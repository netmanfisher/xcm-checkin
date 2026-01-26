<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const stats = ref({
  pendingReviews: 0
})

onMounted(async () => {
  await fetchPendingCount()
})

async function fetchPendingCount() {
  try {
    const { count } = await supabase
      .from('xcm_check_ins')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending')

    stats.value.pendingReviews = count || 0
  } catch (error) {
    console.error('获取待审核数量失败:', error)
  }
}

function isActive(path) {
  return router.currentRoute.value.path === path
}
</script>

<template>
  <div class="sidebar">
    <div class="logo">
      <h2>🔧 管理后台</h2>
    </div>
    <nav class="nav-menu">
      <router-link to="/admin" :class="{ active: isActive('/admin') }">
        📊 数据概览
      </router-link>
      <router-link to="/admin/children" :class="{ active: isActive('/admin/children') }">
        👦👧 孩子管理
      </router-link>
      <router-link to="/admin/plans" :class="{ active: isActive('/admin/plans') }">
        📝 计划管理
      </router-link>
      <router-link to="/admin/reviews" :class="{ active: isActive('/admin/reviews') }">
        📋 打卡审核 ({{ stats.pendingReviews }})
      </router-link>
      <router-link to="/admin/wishes" :class="{ active: isActive('/admin/wishes') }">
        🎁 愿望管理
      </router-link>
      <button class="logout-btn" @click="authStore.logout(); router.push('/')">
        🚪 退出登录
      </button>
    </nav>
  </div>
</template>

<style scoped>
.sidebar {
  width: 250px;
  min-height: 100vh;
  background: #2C3E50;
  padding: 20px;
  color: white;
  position: fixed;
  left: 0;
  top: 0;
  overflow-y: auto;
}

.logo h2 {
  font-size: 1.5em;
  margin-bottom: 30px;
}

.nav-menu {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.nav-menu a,
.nav-menu button {
  background: none;
  border: none;
  color: white;
  padding: 12px 15px;
  text-align: left;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.3s;
  font-size: 0.95em;
  text-decoration: none;
  display: block;
}

.nav-menu a:hover,
.nav-menu button:hover {
  background: #34495E;
}

.nav-menu a.active {
  background: #667eea;
  font-weight: 600;
}

.logout-btn {
  margin-top: 20px;
  background: #E74C3C !important;
}

.logout-btn:hover {
  background: #C0392B !important;
}
</style>
