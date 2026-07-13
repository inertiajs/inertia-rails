export type Framework = 'react' | 'vue' | 'svelte'

export const railsCode = `class UsersController < ApplicationController
  def index
    render inertia: {
      users: User.active.map do |user|
        user.as_json(only: [:id, :name, :email])
      end
    }
  end
end`

export const frontendCode: Record<Framework, string> = {
  react: `import { Link } from '@inertiajs/react'

const Users = ({ users }: { users: User[] }) => (
  <>
    {users.map((user) => (
      <div key={user.id}>
        <Link href={\`/users/\${user.id}\`}>
          {user.name}
        </Link>
        <p>{user.email}</p>
    </div>
    ))}
  </>
);

export default Users;`,
  vue: `<script setup lang="ts">
import { Link } from '@inertiajs/vue3'
defineProps<{ users: User[] }>()
</script>

<template>
  <div v-for="user in users" :key="user.id">
    <Link :href="\`/users/\${user.id}\`">
      {{ user.name }}
    </Link>
    <p>{{ user.email }}</p>
  </div>
</template>`,
  svelte: `<script lang="ts">
import { Link } from '@inertiajs/svelte';
export let users = [];
</script>

{#each users as user}
  <Link href={\`/users/\${user.id}\`}>
    {user.name}
  </Link>
  <p>{user.email}</p>
{/each}`,
}
