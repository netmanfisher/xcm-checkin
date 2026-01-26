<script setup>
import AdminSidebar from './AdminSidebar.vue'
</script>

<template>
  <div class="admin-layout">
    <AdminSidebar />
    <div class="admin-content">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.admin-layout {
  display: flex;
  min-height: 100vh;
}

.admin-content {
  flex: 1;
  margin-left: 250px;
  padding: 30px;
  background: #ECF0F1;
  min-height: 100vh;
}
</style>
