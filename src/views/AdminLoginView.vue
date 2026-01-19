<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMessage = ref('')

async function handleLogin() {
  if (!username.value || !password.value) {
    errorMessage.value = '请输入用户名和密码'
    return
  }

  loading.value = true
  errorMessage.value = ''

  try {
    // 查询管理员
    const { data: admin, error } = await supabase
      .from('xcm_admins')
      .select('*')
      .eq('username', username.value)
      .single()

    if (error || !admin) {
      errorMessage.value = '用户名或密码错误'
      return
    }

    // 简单验证（实际应用中应该使用 bcrypt）
    if (admin.password_hash !== password.value) {
      errorMessage.value = '用户名或密码错误'
      return
    }

    // 登录成功
    authStore.setAdminLoggedIn(admin)
    router.push('/admin')
  } catch (error) {
    console.error('登录失败:', error)
    errorMessage.value = '登录失败，请重试'
  } finally {
    loading.value = false
  }
}

function goBack() {
  router.push('/')
}
</script>

<template>
  <div class="login-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <div class="login-card">
      <button class="back-btn" @click="goBack">← 返回</button>

      <div class="header">
        <h1>🔐 管理员登录</h1>
      </div>

      <form @submit.prevent="handleLogin" class="login-form">
        <div class="form-group">
          <label>用户名</label>
          <input
            v-model="username"
            type="text"
            placeholder="请输入用户名"
            autocomplete="username"
          />
        </div>

        <div class="form-group">
          <label>密码</label>
          <input
            v-model="password"
            type="password"
            placeholder="请输入密码"
            autocomplete="current-password"
          />
        </div>

        <div v-if="errorMessage" class="error-message">
          {{ errorMessage }}
        </div>

        <button type="submit" class="login-btn" :disabled="loading">
          {{ loading ? '登录中...' : '登录' }}
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

/* 公主主题 */
.theme-princess {
  background: linear-gradient(135deg, #FFB6C1 0%, #DDA0DD 100%);
}

/* 王子主题 */
.theme-prince {
  background: linear-gradient(135deg, #4169E1 0%, #191970 100%);
}

.login-card {
  background: white;
  border-radius: 20px;
  padding: 40px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  max-width: 400px;
  width: 100%;
}

.back-btn {
  background: none;
  border: none;
  font-size: 1em;
  color: #666;
  cursor: pointer;
  margin-bottom: 20px;
  padding: 0;
}

.back-btn:hover {
  color: #333;
}

.header {
  text-align: center;
  margin-bottom: 30px;
}

.header h1 {
  font-size: 2em;
  color: #333;
}

.login-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.form-group label {
  font-size: 0.9em;
  color: #666;
  font-weight: 500;
}

.form-group input {
  padding: 12px;
  border: 2px solid #E5E5EA;
  border-radius: 10px;
  font-size: 1em;
  transition: all 0.3s;
}

.form-group input:focus {
  outline: none;
  border-color: #667eea;
}

.error-message {
  background: #FFE4E1;
  color: #FF3B30;
  padding: 10px;
  border-radius: 10px;
  font-size: 0.9em;
  text-align: center;
}

.login-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 14px;
  border-radius: 10px;
  font-size: 1em;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.login-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
}

.login-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
