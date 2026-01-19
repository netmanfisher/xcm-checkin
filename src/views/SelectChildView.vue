<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const children = ref([])
const loading = ref(true)

onMounted(async () => {
  // 尝试恢复登录状态
  authStore.restoreSession()
  if (authStore.isLoggedIn) {
    if (authStore.isAdmin) {
      router.push('/admin')
    } else {
      router.push('/home')
    }
    return
  }

  // 获取孩子列表
  await fetchChildren()
})

async function fetchChildren() {
  try {
    const { data, error } = await supabase
      .from('xcm_children')
      .select('*')
      .eq('status', 'active')
      .order('created_at')

    if (error) {
      console.error('❌ 数据库错误:', error)
      console.error('错误代码:', error.code)
      console.error('错误信息:', error.message)
      console.error('提示: 请确保已在 Supabase 中创建数据库表并插入测试数据')
      throw error
    }

    console.log('✅ 成功获取孩子列表:', data)
    children.value = data || []
  } catch (error) {
    console.error('获取孩子列表失败:', error)
  } finally {
    loading.value = false
  }
}

function selectChild(child) {
  authStore.setCurrentChild(child)
  router.push('/home')
}

function goToAdminLogin() {
  router.push('/admin/login')
}
</script>

<template>
  <div class="select-child-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <div class="header">
      <h1>🌟 小虾米每日打卡</h1>
      <p>请选择你的头像</p>
    </div>

    <div v-if="loading" class="loading">
      <p>加载中...</p>
    </div>

    <div v-else-if="children.length === 0" class="empty-state">
      <div class="empty-icon">📭</div>
      <h2>还没有孩子账号</h2>
      <p>请先在管理后台添加孩子账号</p>
      <button class="admin-login-btn" @click="goToAdminLogin">
        前往管理后台
      </button>
    </div>

    <div v-else class="children-grid">
      <div
        v-for="child in children"
        :key="child.id"
        class="child-card"
        @click="selectChild(child)"
      >
        <div class="child-avatar">
          {{ child.avatar_url || '👧' }}
        </div>
        <div class="child-name">{{ child.name }}</div>
        <div class="child-info">
          <span>⭐ LV{{ child.level }}</span>
          <span>💰 {{ child.stars }}</span>
        </div>
      </div>
    </div>

    <div class="footer">
      <button class="admin-login-btn" @click="goToAdminLogin">
        🔧 管理员登录
      </button>
    </div>
  </div>
</template>

<style scoped>
.select-child-container {
  min-height: 100vh;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
}

/* 公主主题 */
.theme-princess {
  background: linear-gradient(135deg, #FFB6C1 0%, #DDA0DD 100%);
}

/* 王子主题 */
.theme-prince {
  background: linear-gradient(135deg, #4169E1 0%, #191970 100%);
}

.header {
  text-align: center;
  margin-bottom: 40px;
  margin-top: 40px;
}

.header h1 {
  font-size: 2.5em;
  color: white;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.2);
  margin-bottom: 10px;
}

.header p {
  font-size: 1.2em;
  color: white;
  opacity: 0.9;
}

.loading {
  text-align: center;
  font-size: 1.5em;
  color: white;
  margin-top: 50px;
}

.empty-state {
  text-align: center;
  background: white;
  border-radius: 20px;
  padding: 40px;
  margin: 20px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
}

.empty-icon {
  font-size: 4em;
  margin-bottom: 20px;
}

.empty-state h2 {
  color: #333;
  margin-bottom: 10px;
}

.empty-state p {
  color: #666;
  margin-bottom: 20px;
}


.children-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 20px;
  max-width: 800px;
  width: 100%;
  margin-bottom: 40px;
}

.child-card {
  background: white;
  border-radius: 20px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  display: flex;
  flex-direction: column;
  align-items: center;
}

.child-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 15px 40px rgba(0, 0, 0, 0.3);
}

.child-avatar {
  font-size: 4em;
  margin-bottom: 10px;
}

.child-name {
  font-size: 1.3em;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}

.child-info {
  display: flex;
  gap: 15px;
  font-size: 0.9em;
  color: #666;
}

.footer {
  margin-top: auto;
}

.admin-login-btn {
  background: rgba(255, 255, 255, 0.2);
  border: 2px solid white;
  color: white;
  padding: 10px 20px;
  border-radius: 10px;
  font-size: 0.9em;
  cursor: pointer;
  transition: all 0.3s;
}

.admin-login-btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: scale(1.05);
}
</style>
