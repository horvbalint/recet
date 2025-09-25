<script setup lang="ts">
import type { Columns } from '@nebula/components/table/neb-table-frame.vue'
import type { RecordId } from 'surrealdb'
import type { OutMember } from '~/db'

export interface Member {
  member: RecordId
  user: RecordId
  email: string
  username: string
  role: OutMember['role']
}

// Modal states
const showAddModal = ref(false)
const showEditModal = ref(false)
const memberToEdit = ref<Member | null>(null)

// Form data
const addForm = ref({
  username: '',
  role: 'guest' as OutMember['role'],
})

const editForm = ref({
  role: 'guest' as OutMember['role'],
})

const isFormValid = ref(false)
const isLoading = ref(false)

const getQuery = surql`
  SELECT
    id as member,
    in as user,
    in.email as email,
    in.username as username,
    role
  FROM member 
  WHERE out = type::thing(${householdGap}) 
  ORDER username ASC
`

const { data: members, status, refresh } = useAsyncData(async () => {
  const [result] = await db.query<[Member[]]>(getQuery, [householdGap.fill(currentHousehold.value!.id)])
  return result || []
}, { watch: [currentHousehold] })

const columns: Columns<Member> = {
  username: { text: 'Username' },
  email: { text: 'Email' },
  role: { text: 'Role' },
}

// Role options
const roleOptions = ['guest', 'writer', 'owner']

function handleAddMember() {
  addForm.value = { username: '', role: 'guest' }
  showAddModal.value = true
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

    await db.query(surql`DELETE ${member.member}`)
    await refresh()

    useNebToast({ type: 'success', title: 'Member removed!', description: 'The member has been successfully removed from the household.' })
  }
  catch (error) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Removal failed!', description: 'Could not remove the member from the household. Please try again.' })
  }
}

// Add member function
async function handleAddSubmit() {
  if (!addForm.value.username)
    return

  isLoading.value = true
  try {
    await db.query(surql`fn::add_member_to_household(${currentHousehold.value!.id}, ${addForm.value.username}, ${addForm.value.role})`)

    useNebToast({ type: 'success', title: 'Member added!', description: 'The user has been successfully added to the household.' })
    showAddModal.value = false
    await refresh()
  }
  catch (error: any) {
    console.error(error)
    useNebToast({ type: 'error', title: 'Failed to add member!', description: error.message || 'Could not add the member. Please try again.' })
  }
  finally {
    isLoading.value = false
  }
}

// Edit member role function
async function handleEditSubmit() {
  if (!memberToEdit.value)
    return

  isLoading.value = true
  try {
    await db.query(surql`UPDATE ${memberToEdit.value.member} SET role = ${editForm.value.role}`)
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
  showAddModal.value = false
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
  <nuxt-layout name="app">
    <template #content-header>
      <neb-content-header
        title="Household Members"
        description="Manage who has access to this household and their permissions"
        :type="pageHeaderType"
        has-separator
      >
        <template v-if="isCurrHouseholdOwner" #actions>
          <neb-button small @click="handleAddMember()">
            <icon name="material-symbols:person-add-outline-rounded" />
            Add Member
          </neb-button>
        </template>
      </neb-content-header>
    </template>

    <div class="members-page">
      <neb-table
        :columns="columns"
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
    </div>

    <!-- Add Member Modal -->
    <neb-modal
      v-model="showAddModal"
      title="Add Member to Household"
      header-icon="material-symbols:person-add-outline-rounded"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <neb-validator v-model="isFormValid">
          <div class="modal-form-content">
            <neb-input
              v-model="addForm.username"
              label="Username"
              placeholder="Enter the user's username"
              required
              :disabled="isLoading"
            />

            <neb-select
              v-model="addForm.role"
              label="Role"
              placeholder="Select a role"
              required
              :disabled="isLoading"
              :options="roleOptions"
            />
          </div>
        </neb-validator>
      </template>

      <template #actions>
        <neb-button type="secondary" @click="closeModal()">
          Cancel
        </neb-button>

        <neb-button
          type="primary"
          :disabled="!addForm.username || isLoading"
          :loading="isLoading"
          @click="handleAddSubmit()"
        >
          Add Member
        </neb-button>
      </template>
    </neb-modal>

    <!-- Edit Member Role Modal -->
    <neb-modal
      v-model="showEditModal"
      title="Edit Member Role"
      header-icon="material-symbols:edit-outline-rounded"
      max-width="500px"
      :close-on-background-click="false"
    >
      <template #content>
        <neb-validator v-model="isFormValid">
          <div class="modal-form-content">
            <neb-avatar-card :title="memberToEdit?.username" :text="memberToEdit?.email" />

            <neb-select
              v-model="editForm.role"
              label="Role"
              placeholder="Select a role"
              required
              :disabled="isLoading"
              :options="roleOptions"
            />
          </div>
        </neb-validator>
      </template>

      <template #actions>
        <neb-button type="secondary" @click="closeModal()">
          Cancel
        </neb-button>

        <neb-button
          type="primary"
          :disabled="isLoading"
          :loading="isLoading"
          @click="handleEditSubmit()"
        >
          Update Role
        </neb-button>
      </template>
    </neb-modal>
  </nuxt-layout>
</template>

<style scoped>
.members-page {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}

.modal-form-content {
  display: flex;
  flex-direction: column;
  gap: var(--space-5);
}
</style>
