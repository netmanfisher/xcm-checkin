<script setup>
import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

const navItems = [
  { path: '/home', icon: '🏠', label: '首页' },
  { path: '/honors', icon: '🏆', label: '荣誉' },
  { path: '/wishes', icon: '🎁', label: '愿望' },
  { path: '/history', icon: '📊', label: '历史' },
  { path: '/report', icon: '📈', label: '报告' }
]

function navigate(path) {
  router.push(path)
}
</script>

<template>
  <nav class="bottom-nav">
    <button
      v-for="item in navItems"
      :key="item.path"
      :class="{ active: route.path === item.path }"
      @click="navigate(item.path)"
    >
      <span class="icon">{{ item.icon }}</span>
      <span class="label">{{ item.label }}</span>
    </button>
  </nav>
</template>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  display: flex;
  justify-content: space-around;
  padding: 8px 0;
  box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  border-top: 1px solid #E5E5E5;
}

.bottom-nav button {
  background: none;
  border: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  color: #999;
  cursor: pointer;
  font-size: 0.75em;
  padding: 4px 12px;
  border-radius: 8px;
  transition: all 0.3s;
  flex: 1;
}

.bottom-nav button:hover {
  background: #F5F5F5;
}

.bottom-nav button.active {
  color: #667eea;
  background: #F0F0FF;
}

.bottom-nav button .icon {
  font-size: 1.5em;
}

.bottom-nav button .label {
  font-weight: 500;
}
</style>
