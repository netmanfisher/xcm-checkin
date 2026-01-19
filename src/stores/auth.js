import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  const currentChild = ref(null)
  const isAdmin = ref(false)
  const isLoggedIn = ref(false)

  // 设置当前登录的孩子
  function setCurrentChild(child) {
    currentChild.value = child
    isLoggedIn.value = true
    isAdmin.value = false
    localStorage.setItem('xcm_current_child', JSON.stringify(child))
  }

  // 设置管理员登录
  function setAdminLoggedIn(admin) {
    isAdmin.value = true
    isLoggedIn.value = true
    currentChild.value = null
    localStorage.setItem('xcm_current_admin', JSON.stringify(admin))
  }

  // 登出
  function logout() {
    currentChild.value = null
    isAdmin.value = false
    isLoggedIn.value = false
    localStorage.removeItem('xcm_current_child')
    localStorage.removeItem('xcm_current_admin')
  }

  // 从本地存储恢复登录状态
  function restoreSession() {
    const child = localStorage.getItem('xcm_current_child')
    if (child) {
      currentChild.value = JSON.parse(child)
      isLoggedIn.value = true
      isAdmin.value = false
    }

    const admin = localStorage.getItem('xcm_current_admin')
    if (admin) {
      isAdmin.value = true
      isLoggedIn.value = true
      currentChild.value = null
    }
  }

  return {
    currentChild,
    isAdmin,
    isLoggedIn,
    setCurrentChild,
    setAdminLoggedIn,
    logout,
    restoreSession
  }
})
