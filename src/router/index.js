import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'select-child',
      component: () => import('../views/SelectChildView.vue')
    },
    {
      path: '/admin/login',
      name: 'admin-login',
      component: () => import('../views/AdminLoginView.vue')
    },
    {
      path: '/admin',
      name: 'admin-dashboard',
      component: () => import('../views/AdminDashboardView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
      path: '/admin/reviews',
      name: 'admin-review',
      component: () => import('../views/AdminReviewView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
      path: '/admin/children',
      name: 'admin-children',
      component: () => import('../views/AdminChildrenView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
      path: '/admin/plans',
      name: 'admin-plans',
      component: () => import('../views/AdminPlansView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
      path: '/admin/wishes',
      name: 'admin-wishes',
      component: () => import('../views/AdminWishesView.vue'),
      meta: { requiresAuth: true, requiresAdmin: true }
    },
    {
      path: '/checkin/:planId',
      name: 'checkin',
      component: () => import('../views/CheckInView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/home',
      name: 'home',
      component: () => import('../views/HomeView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/honors',
      name: 'honors',
      component: () => import('../views/HonorsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/wishes',
      name: 'wishes',
      component: () => import('../views/WishesView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/history',
      name: 'history',
      component: () => import('../views/HistoryView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/report',
      name: 'report',
      component: () => import('../views/ReportView.vue'),
      meta: { requiresAuth: true }
    }
  ]
})

// 路由守卫
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()

  if (to.meta.requiresAuth && !authStore.isLoggedIn) {
    next({ name: 'select-child' })
  } else if (to.meta.requiresAdmin && !authStore.isAdmin) {
    next({ name: 'admin-login' })
  } else {
    next()
  }
})

export default router
