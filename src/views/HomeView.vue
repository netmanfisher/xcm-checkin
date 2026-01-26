<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'
import BottomNav from '../components/BottomNav.vue'

const router = useRouter()
const authStore = useAuthStore()

const studyPlans = ref([])
const todayCheckIns = ref([])
const pendingCheckIns = ref([]) // 待审核的打卡
const weekData = ref([])
const loading = ref(false)

// 获取当前是星期几（1-7，周一到周日，0表示周日）
const currentWeekday = computed(() => {
  const day = new Date().getDay()
  return day === 0 ? 7 : day
})

// 计算本周的日期
const weekDates = computed(() => {
  const today = new Date()
  const day = today.getDay()
  const diff = today.getDate() - day + (day === 0 ? -6 : 1)

  const week = []
  for (let i = 0; i < 7; i++) {
    const date = new Date(today)
    date.setDate(diff + i)
    week.push({
      date: date,
      dateStr: date.toISOString().split('T')[0],
      day: date.getDate(),
      weekday: ['日', '一', '二', '三', '四', '五', '六'][date.getDay()]
    })
  }
  return week
})

onMounted(async () => {
  await fetchStudyPlans()
  await fetchTodayCheckIns()
  await fetchPendingCheckIns()
  await fetchWeekData()
})

async function fetchStudyPlans() {
  try {
    const { data, error } = await supabase
      .from('xcm_study_plans')
      .select('*')
      .eq('status', 'active')
      .order('sort_order')

    if (error) throw error
    studyPlans.value = data
  } catch (error) {
    console.error('获取学习计划失败:', error)
  }
}

async function fetchTodayCheckIns() {
  try {
    const today = new Date().toISOString().split('T')[0]
    const { data, error } = await supabase
      .from('xcm_check_ins')
      .select('*')
      .eq('child_id', authStore.currentChild?.id)
      .eq('status', 'approved')
      .gte('check_in_time', today)
      .order('check_in_time')

    if (error) throw error
    todayCheckIns.value = data
  } catch (error) {
    console.error('获取今日打卡失败:', error)
  }
}

async function fetchPendingCheckIns() {
  try {
    const today = new Date().toISOString().split('T')[0]
    const { data, error } = await supabase
      .from('xcm_check_ins')
      .select('*')
      .eq('child_id', authStore.currentChild?.id)
      .eq('status', 'pending')
      .gte('check_in_time', today)
      .order('check_in_time')

    if (error) throw error
    pendingCheckIns.value = data
  } catch (error) {
    console.error('获取待审核打卡失败:', error)
  }
}

async function fetchWeekData() {
  try {
    const weekStart = weekDates.value[0].dateStr
    const weekEnd = weekDates.value[6].dateStr + 'T23:59:59'

    // 获取本周所有打卡记录
    const { data, error } = await supabase
      .from('xcm_check_ins')
      .select('check_in_time, plan_id')
      .eq('child_id', authStore.currentChild?.id)
      .eq('status', 'approved')
      .gte('check_in_time', weekStart)
      .lte('check_in_time', weekEnd)

    if (error) throw error

    // 按日期统计
    const weekStats = weekDates.value.map(day => {
      const dayCheckIns = data.filter(item => {
        const itemDate = new Date(item.check_in_time).toISOString().split('T')[0]
        return itemDate === day.dateStr
      })

      return {
        ...day,
        completed: dayCheckIns.length,
        total: studyPlans.value.length,
        status: dayCheckIns.length === studyPlans.value.length ? 'completed' :
               dayCheckIns.length > 0 ? 'partial' : 'pending'
      }
    })

    weekData.value = weekStats
  } catch (error) {
    console.error('获取本周数据失败:', error)
  }
}

// 判断任务是否已完成
function isCompleted(planId) {
  return todayCheckIns.value.some(checkin => checkin.plan_id === planId)
}

// 判断任务是否有待审核的打卡
function isPending(planId) {
  return pendingCheckIns.value.some(checkin => checkin.plan_id === planId)
}

// 获取打卡状态文本
function getStatusText(planId) {
  if (isCompleted(planId)) return '（打卡完毕）'
  if (isPending(planId)) return '（待审核）'
  return '（未打卡）'
}

// 获取打卡状态类名
function getStatusClass(planId) {
  if (isCompleted(planId)) return 'status-completed'
  if (isPending(planId)) return 'status-pending'
  return 'status-not-start'
}

// 按时间段分组任务
const groupedPlans = computed(() => {
  const groups = {
    morning: { label: '🌅 上午', icon: '🌅', plans: [] },
    afternoon: { label: '☀️ 下午', icon: '☀️', plans: [] },
    evening: { label: '🌙 晚上', icon: '🌙', plans: [] },
    any: { label: '📋 全天', icon: '📋', plans: [] }
  }

  studyPlans.value.forEach(plan => {
    // 检查是否应该在今日显示
    const planWeekdays = plan.weekdays || [1, 2, 3, 4, 5, 6, 7]

    // 如果包含0（当日当次），则只检查今天是否已打卡
    if (planWeekdays.includes(0)) {
      const hasCompletedToday = todayCheckIns.value.some(checkin => checkin.plan_id === plan.id)
      const hasPendingToday = pendingCheckIns.value.some(checkin => checkin.plan_id === plan.id)

      // 如果今天已打卡或待审核，则不再显示这个任务
      if (hasCompletedToday || hasPendingToday) {
        return // 不添加到显示列表
      }
      // 否则显示（第一次打卡）
    } else {
      // 正常的周期检查，检查今天是否在计划中
      if (!planWeekdays.includes(currentWeekday.value)) {
        return // 今天不是这个计划的打卡日
      }
    }

    const period = plan.time_period || 'any'
    if (groups[period]) {
      groups[period].plans.push(plan)
    } else {
      groups.any.plans.push(plan)
    }
  })

  // 只返回有任务的组
  return Object.values(groups).filter(group => group.plans.length > 0)
})

// 获取某天的完成状态
function getDayStatus(day) {
  if (day.status === 'completed') return '✅'
  if (day.status === 'partial') return day.completed
  return '⚪'
}

// 是否是今天
function isToday(dateStr) {
  return dateStr === new Date().toISOString().split('T')[0]
}

function goToCheckIn(plan) {
  router.push({
    name: 'checkin',
    params: { planId: plan.id }
  })
}

function goToHonors() {
  router.push('/honors')
}

function goBack() {
  authStore.logout()
  router.push('/')
}
</script>

<template>
  <div class="home-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <!-- 头部 -->
    <header class="header">
      <div class="user-info">
        <span class="greeting">👋 {{ authStore.currentChild?.name }}</span>
        <button class="logout-btn" @click="goBack">退出</button>
      </div>
      <div class="date">{{ new Date().toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' }) }}</div>
      <div class="stats">
        <div class="stat-item">
          <span class="icon">⭐</span>
          <span class="value">{{ authStore.currentChild?.stars || 0 }}</span>
        </div>
        <div class="stat-item">
          <span class="icon">🔥</span>
          <span class="value">{{ authStore.currentChild?.current_streak || 0 }}天</span>
        </div>
      </div>
    </header>

    <!-- 周历视图 -->
    <section class="week-calendar">
      <h3>📊 本周进度</h3>
      <div class="week-grid">
        <div
          v-for="day in weekDates"
          :key="day.dateStr"
          class="day-card"
          :class="{ today: isToday(day.dateStr) }"
        >
          <div class="day-date">{{ day.day }}</div>
          <div class="day-weekday">{{ day.weekday }}</div>
          <div class="day-status">{{ getDayStatus(day) }}</div>
        </div>
      </div>
    </section>

    <!-- 今日任务 -->
    <section class="today-tasks">
      <h3>📝 今日任务</h3>
      <div v-if="loading" class="loading">加载中...</div>
      <div v-else>
        <!-- 按时间段分组显示 -->
        <div v-for="group in groupedPlans" :key="group.label" class="time-period-group">
          <div class="period-header">
            <span class="period-icon">{{ group.icon }}</span>
            <span class="period-label">{{ group.label }}</span>
            <span class="period-count">{{ group.plans.length }}项任务</span>
          </div>
          <div class="tasks-list">
            <div
              v-for="plan in group.plans"
              :key="plan.id"
              class="task-card"
              :class="[
                getStatusClass(plan.id),
                { clickable: !isCompleted(plan.id) && !isPending(plan.id) }
              ]"
              @click="(!isCompleted(plan.id) && !isPending(plan.id)) && goToCheckIn(plan)"
            >
              <div class="task-icon">{{ plan.icon }}</div>
              <div class="task-info">
                <div class="task-name">
                  {{ plan.name }}
                  <span class="status-text" :class="getStatusClass(plan.id)">
                    {{ getStatusText(plan.id) }}
                  </span>
                </div>
                <div class="task-details">
                  <span v-if="plan.require_photo">📸</span>
                  <span v-if="plan.require_audio">🎤</span>
                  <span>⏱️ {{ plan.duration_minutes }}分钟</span>
                </div>
              </div>
              <div class="task-reward">+⭐{{ plan.stars_reward }}</div>
              <div class="task-status">
                <span v-if="isCompleted(plan.id)">✅</span>
                <span v-else-if="isPending(plan.id)">⏳</span>
                <span v-else>打卡</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- 底部导航 -->
    <BottomNav />
  </div>
</template>

<style scoped>
.home-container {
  min-height: 100vh;
  padding: 20px;
  padding-bottom: 80px;
}

/* 公主主题 */
.theme-princess {
  background: linear-gradient(135deg, #FFE4E1 0%, #FFB6C1 100%);
}

/* 王子主题 */
.theme-prince {
  background: linear-gradient(135deg, #87CEEB 0%, #4169E1 100%);
}

.header {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.user-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.greeting {
  font-size: 1.5em;
  color: #333;
}

.logout-btn {
  background: none;
  border: none;
  color: #666;
  cursor: pointer;
  font-size: 0.9em;
}

.date {
  text-align: center;
  color: #666;
  margin-bottom: 15px;
}

.stats {
  display: flex;
  gap: 20px;
  justify-content: center;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 1.1em;
}

.week-calendar {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.week-calendar h3 {
  font-size: 1.3em;
  margin-bottom: 15px;
  color: #333;
}

.week-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
}

.day-card {
  background: #F5F5F5;
  border-radius: 10px;
  padding: 10px;
  text-align: center;
  border: 2px solid transparent;
}

.day-card.today {
  border-color: #FFD700;
  background: #FFF8DC;
}

.day-date {
  font-size: 1.1em;
  color: #333;
  margin-bottom: 5px;
}

.day-weekday {
  font-size: 0.9em;
  color: #666;
  margin-bottom: 5px;
}

.day-status {
  font-size: 1.2em;
}

.today-tasks {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.today-tasks h3 {
  font-size: 1.3em;
  margin-bottom: 15px;
  color: #333;
}

.loading {
  text-align: center;
  color: #999;
}

.tasks-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.time-period-group {
  margin-bottom: 25px;
}

.period-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 15px;
  background: linear-gradient(135deg, #FFB6C1 0%, #DDA0DD 100%);
  border-radius: 12px;
  margin-bottom: 12px;
  color: white;
  box-shadow: 0 3px 10px rgba(255, 182, 193, 0.3);
  border: 2px solid rgba(255, 255, 255, 0.5);
}

.period-icon {
  font-size: 1.4em;
}

.period-label {
  font-size: 1em;
  font-weight: 700;
  flex: 1;
  text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.1);
}

.period-count {
  font-size: 0.75em;
  opacity: 0.95;
  background: rgba(255, 255, 255, 0.3);
  padding: 3px 8px;
  border-radius: 12px;
  font-weight: 500;
}

.task-card {
  display: flex;
  align-items: center;
  gap: 15px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 15px;
  padding: 15px;
  color: white;
  transition: all 0.3s;
}

.task-card.clickable {
  cursor: pointer;
}

.task-card.clickable:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

/* 未打卡状态（默认） */
.task-card.status-not-start {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

/* 待审核状态 - 黄色 */
.task-card.status-pending {
  background: linear-gradient(135deg, #f6d365 0%, #fda085 100%);
  cursor: not-allowed;
}

/* 打卡完毕状态 - 绿色 */
.task-card.status-completed {
  background: linear-gradient(135deg, #a8e063 0%, #56ab2f 100%);
  cursor: default;
}

.task-icon {
  font-size: 2.5em;
}

.task-info {
  flex: 1;
}

.task-name {
  font-size: 1.1em;
  font-weight: 600;
  margin-bottom: 5px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.status-text {
  font-size: 0.7em;
  padding: 2px 8px;
  border-radius: 10px;
  font-weight: 500;
}

.status-text.status-not-start {
  background: rgba(255, 255, 255, 0.3);
}

.status-text.status-pending {
  background: rgba(255, 255, 255, 0.4);
  animation: pulse 2s infinite;
}

.status-text.status-completed {
  background: rgba(255, 255, 255, 0.3);
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.task-details {
  display: flex;
  gap: 10px;
  font-size: 0.85em;
  opacity: 0.9;
}

.task-reward {
  font-size: 0.9em;
  font-weight: 600;
}

.task-status {
  font-size: 1.2em;
}
</style>
