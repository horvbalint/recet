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

const { t } = useI18n()

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
  username: { text: t('members.columns.username') },
  email: { text: t('members.columns.email') },
  role: { text: t('members.columns.role') },
} satisfies Columns<Member>

const roleOptions = ['guest', 'writer', 'owner'] as ['guest', 'writer', 'owner']

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
    useNebToast({ type: 'error', title: t('members.invite.error.title'), description: t('members.invite.error.description') })
  }
  finally {
    isCreatingInvitation.value = false
  }
}

function copyToken(token: string) {
  navigator.clipboard.writeText(token)
  useNebToast({ type: 'success', title: t('members.invite.tokenCopied.title'), description: t('members.invite.tokenCopied.description') })
}

async function handleRevokeInvitation(invitation: Invitation) {
  const confirmed = await useNebConfirm({
    title: t('members.revokeConfirm.title'),
    description: t('members.revokeConfirm.description'),
  })

  if (!confirmed)
    return

  try {
    await db.query(surql`DELETE ${invitation.id}`).collect()
    await refreshInvitations()
    useNebToast({ type: 'success', title: t('members.revokeSuccess') })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: t('members.revokeError.title'), description: t('members.revokeError.description') })
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
      title: t('members.remove.confirm.title'),
      description: t('members.remove.confirm.description', { username: member.username }),
    })

    if (!confirmResult)
      return

    await db
      .query(surql`DELETE ${member.member}`)
      .collect()
    await refresh()

    useNebToast({ type: 'success', title: t('members.remove.success.title'), description: t('members.remove.success.description') })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: t('members.remove.error.title'), description: t('members.remove.error.description') })
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
    useNebToast({ type: 'success', title: t('members.editRole.success.title'), description: t('members.editRole.success.description') })

    showEditModal.value = false
    await refresh()
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: t('members.editRole.error.title'), description: t('members.editRole.error.description') })
  }
  finally {
    isLoading.value = false
  }
}

function closeModal() {
  showEditModal.value = false
  memberToEdit.value = null
}

const roleColorMap = {
  owner: 'primary',
  writer: 'info',
  guest: 'success',
} as const

const roleDictionary: Record<OutMember['role'], string> = {
  owner: t('members.roles.owner'),
  writer: t('members.roles.writer'),
  guest: t('members.roles.guest'),
}
</script>

<template>
  <page-layout>
    <template #content-header>
      <neb-content-header
        :title="$t('members.title')"
        :description="$t('members.description')"
        :type="pageHeaderType"
        has-separator
      >
        <template v-if="isCurrHouseholdOwner" #actions>
          <neb-button small @click="openInvitationModal()">
            <icon name="material-symbols:person-add-outline-rounded" />
            {{ $t('members.inviteButton') }}
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
          <neb-badge :color="roleColorMap[original.role]">
            {{ roleDictionary[original.role] }}
          </neb-badge>
        </template>

        <template v-if="isCurrHouseholdOwner" #row-actions="{ data: { original } }">
          <icon class="row-action" name="material-symbols:edit-outline-rounded" @click="handleEditMember(original)" />
          <icon class="row-action delete-action" name="material-symbols:delete-outline-rounded" @click="handleDeleteMember(original)" />
        </template>
      </neb-table>

      <div v-if="isCurrHouseholdOwner && invitations?.length" class="invitations-section">
        <neb-content-header :title="$t('members.pendingInvitations')" type="section" has-separator />

        <div class="invitation-list">
          <div v-for="invitation in invitations" :key="invitation.id.toString()" class="invitation-item">
            <div class="invitation-info">
              <neb-badge :color="roleColorMap[invitation.role]">
                {{ roleDictionary[invitation.role] }}
              </neb-badge>

              <code class="invitation-token">{{ invitation.token }}</code>
              <neb-button type="link-neutral" small @click="copyToken(invitation.token.toString())">
                <icon name="material-symbols:content-copy-outline-rounded" />
              </neb-button>
            </div>

            <icon class="row-action delete-action" name="material-symbols:delete-outline-rounded" @click="handleRevokeInvitation(invitation)" />
          </div>
        </div>
      </div>
    </div>

    <neb-modal v-model="showInviteModal" :title="$t('members.invite.title')" header-icon="material-symbols:person-add-outline-rounded" max-width="500px">
      <template #content>
        <div v-if="!createdToken" class="invite-form">
          <neb-select
            v-model="inviteRole"
            :label="$t('members.invite.role.label')"
            :placeholder="$t('members.invite.role.placeholder')"
            :options="roleOptions"
            :custom-label="(role: OutMember['role']) => roleDictionary[role]"
            no-search
          />
        </div>

        <div v-else class="token-display">
          <p class="token-instructions">
            {{ $t('members.invite.tokenInstructions') }}
          </p>

          <div class="token-field">
            <code class="token-value">{{ createdToken }}</code>

            <neb-button small type="secondary" @click="copyToken(createdToken)">
              <icon name="material-symbols:content-copy-outline-rounded" />
              {{ $t('common.copy') }}
            </neb-button>
          </div>
        </div>
      </template>

      <template #actions>
        <template v-if="!createdToken">
          <neb-button type="secondary" @click="showInviteModal = false">
            {{ $t('common.cancel') }}
          </neb-button>

          <neb-button type="primary" :loading="isCreatingInvitation" @click="createInvitation()">
            {{ $t('members.invite.createButton') }}
          </neb-button>
        </template>

        <neb-button v-else type="primary" @click="showInviteModal = false">
          {{ $t('common.done') }}
        </neb-button>
      </template>
    </neb-modal>

    <neb-modal
      v-model="showEditModal"
      :title="$t('members.editRole.title')"
      header-icon="material-symbols:edit-outline-rounded"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <neb-avatar-card :title="memberToEdit?.username" :text="memberToEdit?.email" />

        <neb-select
          v-model="editForm.role"
          :label="$t('members.invite.role.label')"
          :placeholder="$t('members.invite.role.placeholder')"
          no-search
          :disabled="isLoading"
          :options="roleOptions"
          :custom-label="(role: OutMember['role']) => roleDictionary[role]"
        />
      </template>

      <template #actions>
        <neb-button type="secondary" @click="closeModal()">
          {{ $t('common.cancel') }}
        </neb-button>

        <neb-button type="primary" :disabled="isLoading" :loading="isLoading" @click="handleEditSubmit()">
          {{ $t('members.editRole.updateButton') }}
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
