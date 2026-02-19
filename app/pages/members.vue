<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { RecordId, Uuid } from 'surrealdb'
import type { OutMember } from '~/db'

export interface Member {
  member: RecordId
  user: RecordId
  email: string
  username: string
  role: OutMember['role']
}

interface Invitation {
  id: RecordId<'invitation'>
  token: Uuid
  role: OutMember['role']
  created_at: string
}

const showInviteModal = ref(false)
const showEditModal = ref(false)
const memberToEdit = ref<Member | null>(null)

const inviteRole = ref<OutMember['role']>('guest')
const createdToken = ref<string | null>(null)
const isCreatingInvitation = ref(false)

const editForm = ref({
  role: 'guest' as OutMember['role'],
})

const isLoading = ref(false)

const getQuery = computed(() => surql`
  SELECT
    id as member,
    in as user,
    in.email as email,
    in.username as username,
    role
  FROM member 
  WHERE out = ${currentHousehold.value!.id} 
  ORDER username ASC
`)

const { data: members, status, refresh } = useAsyncData(async () => {
  const [result] = await db
    .query(getQuery.value)
    .collect<[Member[]]>()
  return result || []
}, { watch: [currentHousehold] })

const invitationsQuery = computed(() => surql`
  SELECT * FROM invitation WHERE household = ${currentHousehold.value!.id} ORDER created_at DESC
`)

const { data: invitations, refresh: refreshInvitations } = useAsyncData('invitations', async () => {
  const [result] = await db
    .query(invitationsQuery.value)
    .collect<[Invitation[]]>()
  return result || []
}, { watch: [currentHousehold] })

const columns = {
  username: { text: 'Username' },
  email: { text: 'Email' },
  role: { text: 'Role' },
} satisfies Columns<Member>

const roleOptions = ['guest', 'writer', 'owner']

function openInvitationModal() {
  inviteRole.value = 'guest'
  createdToken.value = null
  showInviteModal.value = true
}

async function createInvitation() {
  isCreatingInvitation.value = true
  try {
    const [invitation] = await db
      .query(surql`CREATE ONLY invitation SET household = ${currentHousehold.value!.id}, role = ${inviteRole.value}`)
      .collect<[Invitation]>()

    createdToken.value = invitation.token.toString()
    await refreshInvitations()
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Failed to create invitation', description: 'Could not create the invitation. Please try again.' })
  }
  finally {
    isCreatingInvitation.value = false
  }
}

function copyToken(token: string) {
  navigator.clipboard.writeText(token)
  useNebToast({ type: 'success', title: 'Token copied!', description: 'Share it with the person you want to invite.' })
}

async function handleRevokeInvitation(invitation: Invitation) {
  const confirmed = await useNebConfirm({
    title: 'Revoke invitation?',
    description: 'This invitation token will no longer work.',
  })

  if (!confirmed)
    return

  try {
    await db.query(surql`DELETE ${invitation.id}`).collect()
    await refreshInvitations()
    useNebToast({ type: 'success', title: 'Invitation revoked!' })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Failed to revoke invitation', description: 'Please try again.' })
  }
}

function handleEditMember(member: Member) {
  memberToEdit.value = member
  editForm.value = { role: member.role }
  showEditModal.value = true
}

async function handleDeleteMember(member: Member) {
  try {
    const confirmResult = await useNebConfirm({
      title: 'Remove member from household?',
      description: `Are you sure you want to remove ${member.username} from this household? This action cannot be undone.`,
    })

    if (!confirmResult)
      return

    await db
      .query(surql`DELETE ${member.member}`)
      .collect()
    await refresh()

    useNebToast({ type: 'success', title: 'Member removed!', description: 'The member has been successfully removed from the household.' })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Removal failed!', description: 'Could not remove the member from the household. Please try again.' })
  }
}

async function handleEditSubmit() {
  if (!memberToEdit.value)
    return

  isLoading.value = true
  try {
    await db
      .query(surql`UPDATE ${memberToEdit.value.member} SET role = ${editForm.value.role}`)
      .collect()
    useNebToast({ type: 'success', title: 'Role updated!', description: 'The member role has been successfully updated.' })

    showEditModal.value = false
    await refresh()
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Failed to update role!', description: 'Could not update the member role. Please try again.' })
  }
  finally {
    isLoading.value = false
  }
}

function closeModal() {
  showEditModal.value = false
  memberToEdit.value = null
}

function mapRoleToColor(role: OutMember['role']) {
  switch (role) {
    case 'owner':
      return 'primary'
    case 'writer':
      return 'info'
    case 'guest':
      return 'success'
  }
}
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        title="Household Members"
        description="Manage who has access to this household and their permissions"
        :type="pageHeaderType"
        has-separator
      >
        <template v-if="isCurrHouseholdOwner" #actions>
          <neb-button small @click="openInvitationModal()">
            <icon name="material-symbols:person-add-outline-rounded" />
            Invite Member
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="members-page">
      <neb-table
        :columns
        :rows="members || []"
        :status="status"
        :refresh="refresh"
      >
        <template #td-role="{ data: { original } }">
          <neb-badge :color="mapRoleToColor(original.role)">
            {{ original.role }}
          </neb-badge>
        </template>

        <template #row-actions="{ data: { original } }">
          <icon v-if="isCurrHouseholdOwner" class="row-action" name="material-symbols:edit-outline-rounded" @click="handleEditMember(original)" />
          <icon v-if="isCurrHouseholdOwner" class="row-action delete-action" name="material-symbols:delete-outline-rounded" @click="handleDeleteMember(original)" />
        </template>
      </neb-table>

      <div v-if="isCurrHouseholdOwner && invitations?.length" class="invitations-section">
        <neb-content-header title="Pending Invitations" type="section" has-separator />

        <div class="invitation-list">
          <div v-for="invitation in invitations" :key="invitation.id.toString()" class="invitation-item">
            <div class="invitation-info">
              <neb-badge :color="mapRoleToColor(invitation.role)">
                {{ invitation.role }}
              </neb-badge>

              <code class="invitation-token">{{ invitation.token }}</code>
              <neb-button type="link-neutral" small @click="copyToken(invitation.token)">
                <icon name="material-symbols:content-copy-outline-rounded" />
              </neb-button>
            </div>

            <icon class="row-action delete-action" name="material-symbols:delete-outline-rounded" @click="handleRevokeInvitation(invitation)" />
          </div>
        </div>
      </div>
    </div>

    <neb-modal v-model="showInviteModal" title="Invite Member" header-icon="material-symbols:person-add-outline-rounded" max-width="500px">
      <template #content>
        <div v-if="!createdToken" class="invite-form">
          <neb-select
            v-model="inviteRole"
            label="Role"
            placeholder="Select a role"
            :options="roleOptions"
            no-search
          />
        </div>

        <div v-else class="token-display">
          <p class="token-instructions">
            Share this token with the person you want to invite. It can only be used once.
          </p>

          <div class="token-field">
            <code class="token-value">{{ createdToken }}</code>

            <neb-button small type="secondary" @click="copyToken(createdToken)">
              <icon name="material-symbols:content-copy-outline-rounded" />
              Copy
            </neb-button>
          </div>
        </div>
      </template>

      <template #actions>
        <template v-if="!createdToken">
          <neb-button type="secondary" @click="showInviteModal = false">
            Cancel
          </neb-button>

          <neb-button type="primary" :loading="isCreatingInvitation" @click="createInvitation()">
            Create Invitation
          </neb-button>
        </template>

        <neb-button v-else type="primary" @click="showInviteModal = false">
          Done
        </neb-button>
      </template>
    </neb-modal>

    <neb-modal
      v-model="showEditModal"
      title="Edit Member Role"
      header-icon="material-symbols:edit-outline-rounded"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <neb-avatar-card :title="memberToEdit?.username" :text="memberToEdit?.email" />

        <neb-select
          v-model="editForm.role"
          label="Role"
          placeholder="Select a role"
          no-search
          :disabled="isLoading"
          :options="roleOptions"
        />
      </template>

      <template #actions>
        <neb-button type="secondary" @click="closeModal()">
          Cancel
        </neb-button>

        <neb-button type="primary" :disabled="isLoading" :loading="isLoading" @click="handleEditSubmit()">
          Update Role
        </neb-button>
      </template>
    </neb-modal>
  </page-layout>
</template>

<style scoped>
.members-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.invitations-section {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.invitation-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.invitation-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-3) var(--space-4);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
  background: var(--neutral-color-25);
}

.invitation-info {
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.invitation-token {
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
}

.invite-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.token-display {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
}

.token-instructions {
  font-size: var(--text-sm);
  color: var(--neutral-color-600);
}

.token-field {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  border: 1px solid var(--neutral-color-100);
  border-radius: var(--radius-default);
  background: var(--neutral-color-25);
}

.token-value {
  flex: 1;
  font-size: var(--text-sm);
  word-break: break-all;
  color: var(--neutral-color-700);
}

.dark-mode {
  .invitation-item,
  .token-field {
    background: var(--neutral-color-900);
    border-color: var(--neutral-color-800);
  }

  .invitation-token,
  .token-instructions {
    color: var(--neutral-color-400);
  }

  .token-value {
    color: var(--neutral-color-300);
  }
}
</style>
