<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'
import BottomNav from '../components/BottomNav.vue'

const router = useRouter()
const authStore = useAuthStore()

const studyPlans = ref([])
const todayCheckIns = ref([])
const pendingCheckIns = ref([])
const weekData = ref([])
const loading = ref(false)

// 新增：选中的日期和该日期的数据
const selectedDate = ref(null)
const selectedDateData = ref(null)
const selectedDateType = ref('today') // 'today', 'past', 'future'

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
      weekday: ['日', '一', '二', '三', '四', '五', '六'][date.getDay()],
      isToday: isToday(date),
      isPast: isPastDate(date),
      isFuture: isFutureDate(date)
    })
  }
  return week
})

onMounted(async () => {
  await fetchStudyPlans()
  // 默认选中今天
  const today = new Date().toISOString().split('T')[0]
  await selectDate(today)
})

async function fetchStudyPlans() {
  try {
    const { data, error } = await supabase
      .from('xcm_study_plans')
      .select('*')
      .eq('status', 'active')
      .order('sort_order')

    if (error) throw error
    studyPlans.value = data || []
  } catch (error) {
    console.error('获取学习计划失败:', error)
  }
}

// 新增：选择日期
async function selectDate(dateStr) {
  selectedDate.value = dateStr
  loading.value = true

  try {
    if (!authStore.currentChild?.id) {
      selectedDateData.value = null
      return
    }

    const date = new Date(dateStr)

    if (isPastDate(date)) {
      // 过去的日期：查询历史打卡记录
      await fetchHistoryCheckIns(dateStr)
      selectedDateType.value = 'past'
    } else if (isToday(date)) {
      // 今天：显示今天的打卡情况
      await fetchTodayData(dateStr)
      selectedDateType.value = 'today'
    } else {
      // 未来的日期：显示该日期需要打卡的任务
      await fetchPlannedTasks(dateStr)
      selectedDateType.value = 'future'
    }
  } catch (error) {
    console.error('获取日期数据失败:', error)
    selectedDateData.value = null
  } finally {
    loading.value = false
  }
}

// 新增：获取历史打卡记录
async function fetchHistoryCheckIns(dateStr) {
  try {
    const startDate = dateStr
    const endDate = dateStr + 'T23:59:59'

    const { data, error } = await supabase
      .from('xcm_check_ins')
      .select('*')
      .eq('child_id', authStore.currentChild.id)
      .gte('check_in_time', startDate)
      .lte('check_in_time', endDate)
      .order('check_in_time', { ascending: false })

    if (error) throw error
    selectedDateData.value = data || []
  } catch (error) {
    console.error('获取历史打卡失败:', error)
    selectedDateData.value = []
  }
}

// 新增：获取今日数据
async function fetchTodayData(dateStr) {
  try {
    const startDate = dateStr
    const endDate = dateStr + 'T23:59:59'

    // 获取今日所有打卡（包括待审核和已通过）
    const { data: checkins, error: checkinsError } = await supabase
      .from('xcm_check_ins')
      .select('*')
      .eq('child_id', authStore.currentChild.id)
      .gte('check_in_time', startDate)
      .lte('check_in_time', endDate)
      .order('check_in_time')

    if (checkinsError) throw checkinsError

    todayCheckIns.value = checkins || []
    selectedDateData.value = checkins || []
  } catch (error) {
    console.error('获取今日数据失败:', error)
    selectedDateData.value = []
  }
}

// 新增：获取计划任务
async function fetchPlannedTasks(dateStr) {
  try {
    const date = new Date(dateStr)
    const dayOfWeek = date.getDay() === 0 ? 7 : date.getDay()

    // 获取该日期需要打卡的任务
    const plannedTasks = studyPlans.value.filter(plan => {
      const planWeekdays = plan.weekdays || [1, 2, 3, 4, 5, 6, 7]

      // 检查是否应该在当日显示
      if (planWeekdays.includes(0)) {
        // "当日当次"任务
        const firstShowDate = plan.first_show_date || (plan.created_at ? plan.created_at.split('T')[0] : dateStr)
        return firstShowDate === dateStr
      } else {
        // 正常的周期检查
        return planWeekdays.includes(dayOfWeek)
      }
    })

    selectedDateData.value = plannedTasks
  } catch (error) {
    console.error('获取计划任务失败:', error)
    selectedDateData.value = []
  }
}

function getPlanIcon(planId) {
  const plan = studyPlans.value.find(p => p.id === planId)
  return plan?.icon || '📝'
}

function getPlanName(planId) {
  const plan = studyPlans.value.find(p => p.id === planId)
  return plan?.name || '未知任务'
}

function getStatusText(status) {
  const statusMap = {
    'pending': '待审核',
    'approved': '已通过',
    'rejected': '已拒绝'
  }
  return statusMap[status] || status
}

function getStatusClass(status) {
  return `status-${status}`
}

// 新增：判断任务是否已完成（用于今天）
function isCompleted(planId) {
  return todayCheckIns.value.some(checkin => checkin.plan_id === planId && checkin.status === 'approved')
}

// 新增：判断任务是否有待审核的打卡（用于今天）
function isPending(planId) {
  return todayCheckIns.value.some(checkin => checkin.plan_id === planId && checkin.status === 'pending')
}

// 新增：获取打卡状态文本（用于今天的任务卡片）
function getTaskStatusText(planId) {
  if (isCompleted(planId)) return '（打卡完毕）'
  if (isPending(planId)) return '（待审核）'
  return '（未打卡）'
}

// 新增：获取打卡状态类名（用于今天的任务卡片）
function getTaskStatusClass(planId) {
  if (isCompleted(planId)) return 'status-completed'
  if (isPending(planId)) return 'status-pending'
  return 'status-not-start'
}

// 按时间段分组任务（仅用于今天）
const groupedPlans = computed(() => {
  // 只有选中的是今天时才显示任务列表
  if (selectedDateType.value !== 'today') {
    return []
  }

  const groups = {
    morning: { label: '🌅 上午', icon: '🌅', plans: [] },
    afternoon: { label: '☀️ 下午', icon: '☀️', plans: [] },
    evening: { label: '🌙 晚上', icon: '🌙', plans: [] },
    any: { label: '📋 全天', icon: '📋', plans: [] }
  }

  studyPlans.value.forEach(plan => {
    // 检查是否应该在今日显示
    const planWeekdays = plan.weekdays || [1, 2, 3, 4, 5, 6, 7]

    let shouldShow = false
    const today = new Date().toISOString().split('T')[0]

    // 如果包含0（当日当次）
    if (planWeekdays.includes(0)) {
      // "当日当次"任务：只在 first_show_date 当天显示
      // 如果没有 first_show_date 字段，使用 created_at
      const firstShowDate = plan.first_show_date || (plan.created_at ? plan.created_at.split('T')[0] : today)
      shouldShow = firstShowDate === today
    } else {
      // 正常的周期检查：检查今天是否在计划中
      shouldShow = planWeekdays.includes(currentWeekday.value)
    }

    // 如果不应该显示，跳过
    if (!shouldShow) {
      return
    }

    // 将任务添加到对应的时间段分组
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

// 获取某天的完成状态（用于周历显示）
function getDayStatus(day) {
  if (day.isToday && selectedDateType.value === 'today') {
    // 今天：显示完成进度
    const completed = todayCheckIns.value.filter(c => c.status === 'approved').length
    const pending = todayCheckIns.value.filter(c => c.status === 'pending').length
    const total = completed + pending
    if (total === 0) return '⚪'
    return `${completed}/${studyPlans.value.length}`
  } else if (day.isPast) {
    // 过去的日期：显示完成状态
    const dayData = weekData.value.find(d => d.dateStr === day.dateStr)
    if (dayData && dayData.completed > 0) {
      return dayData.status === 'completed' ? '✅' : dayData.completed
    }
    return '⚪'
  } else {
    // 未来的日期：显示计划数
    const plannedTasks = studyPlans.value.filter(plan => {
      const planWeekdays = plan.weekdays || [1, 2, 3, 4, 5, 6, 7]
      const date = day.date
      const dayOfWeek = date.getDay() === 0 ? 7 : date.getDay()

      if (planWeekdays.includes(0)) {
        const firstShowDate = plan.first_show_date || (plan.created_at ? plan.created_at.split('T')[0] : day.dateStr)
        return firstShowDate === day.dateStr
      } else {
        return planWeekdays.includes(dayOfWeek)
      }
    })
    return plannedTasks.length > 0 ? plannedTasks.length : '⚪'
  }
}

// 获取内容区域标题
function getContentTitle() {
  if (!selectedDate.value) return '今日任务'
  const date = new Date(selectedDate.value)
  const dateStr = `${date.getMonth() + 1}月${date.getDate()}日`

  if (selectedDateType.value === 'today') return `${dateStr} 今日任务`
  if (selectedDateType.value === 'past') return `${dateStr} 历史记录`
  if (selectedDateType.value === 'future') return `${dateStr} 计划任务`
  return '今日任务'
}

function isToday(date) {
  const today = new Date()
  return date.getDate() === today.getDate() &&
         date.getMonth() === today.getMonth() &&
         date.getFullYear() === today.getFullYear()
}

function isPastDate(date) {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const compareDate = new Date(date)
  compareDate.setHours(0, 0, 0, 0)
  return compareDate < today
}

function isFutureDate(date) {
  const today = new Date()
  today.setHours(23, 59, 59, 999)
  const compareDate = new Date(date)
  compareDate.setHours(0, 0, 0, 0)
  return compareDate > today
}

function goToCheckIn(plan) {
  router.push({
    name: 'checkin',
    params: { planId: plan.id }
  })
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
          :class="{
            today: day.isToday,
            selected: selectedDate === day.dateStr,
            past: day.isPast,
            future: day.isFuture
          }"
          @click="selectDate(day.dateStr)"
        >
          <div class="day-date">{{ day.day }}</div>
          <div class="day-weekday">{{ day.weekday }}</div>
          <div class="day-status">{{ getDayStatus(day) }}</div>
        </div>
      </div>
    </section>

    <!-- 内容区域 - 根据选中日期显示不同内容 -->
    <section class="content-section">
      <h3>{{ getContentTitle() }}</h3>

      <div v-if="loading" class="loading">加载中...</div>

      <!-- 历史打卡记录 -->
      <div v-else-if="selectedDateType === 'past' && selectedDateData" class="history-list">
        <div v-if="selectedDateData.length === 0" class="empty-state">
          <div class="empty-icon">📭</div>
          <p>当天没有打卡记录</p>
        </div>
        <div v-else>
          <div
            v-for="checkin in selectedDateData"
            :key="checkin.id"
            class="checkin-card"
            :class="getStatusClass(checkin.status)"
          >
            <div class="checkin-header">
              <div class="task-info">
                <span class="task-icon">{{ getPlanIcon(checkin.plan_id) }}</span>
                <span class="task-name">{{ getPlanName(checkin.plan_id) }}</span>
              </div>
              <div class="checkin-status" :class="getStatusClass(checkin.status)">
                {{ getStatusText(checkin.status) }}
              </div>
            </div>
            <div class="checkin-time">
              🕐 {{ new Date(checkin.check_in_time).toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' }) }}
              <span v-if="checkin.duration_minutes"> · ⏱️ {{ checkin.duration_minutes }}分钟</span>
            </div>
            <div v-if="checkin.notes" class="checkin-notes">
              📝 {{ checkin.notes }}
            </div>
            <div class="checkin-media">
              <div v-if="checkin.photo_url" class="media-item">
                📸 <a :href="checkin.photo_url" target="_blank">查看照片</a>
              </div>
              <div v-if="checkin.audio_url" class="media-item">
                🎤 <a :href="checkin.audio_url" target="_blank">播放录音</a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 今日任务 -->
      <div v-else-if="selectedDateType === 'today'" class="today-tasks-content">
        <div v-if="groupedPlans.length === 0" class="empty-state">
          <div class="empty-icon">📝</div>
          <p>今天没有安排任务</p>
        </div>
        <div v-else>
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
                  getTaskStatusClass(plan.id),
                  { clickable: !isCompleted(plan.id) && !isPending(plan.id) }
                ]"
                @click="(!isCompleted(plan.id) && !isPending(plan.id)) && goToCheckIn(plan)"
              >
                <div class="task-icon">{{ plan.icon }}</div>
                <div class="task-info">
                  <div class="task-name">
                    {{ plan.name }}
                    <span class="status-text" :class="getTaskStatusClass(plan.id)">
                      {{ getTaskStatusText(plan.id) }}
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
      </div>

      <!-- 未来计划任务 -->
      <div v-else-if="selectedDateType === 'future' && selectedDateData" class="future-tasks">
        <div v-if="selectedDateData.length === 0" class="empty-state">
          <div class="empty-icon">😴</div>
          <p>当天没有安排任务</p>
        </div>
        <div v-else class="task-list">
          <div
            v-for="task in selectedDateData"
            :key="task.id"
            class="task-card"
          >
            <div class="task-icon">{{ task.icon }}</div>
            <div class="task-info">
              <div class="task-name">{{ task.name }}</div>
              <div class="task-details">
                <span v-if="task.require_photo">📸 照片</span>
                <span v-if="task.require_audio">🎤 录音</span>
                <span>⏱️ {{ task.duration_minutes }}分钟</span>
                <span>⭐ +{{ task.stars_reward }}</span>
              </div>
              <div v-if="task.description" class="task-description">
                {{ task.description }}
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
  cursor: pointer;
  transition: all 0.3s;
}

.day-card:hover:not(.today) {
  transform: scale(1.05);
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
}

.day-card.today {
  border-color: #FFD700;
  background: #FFF8DC;
}

.day-card.selected {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.day-card.selected .day-date,
.day-card.selected .day-weekday {
  color: white;
}

.day-card.past {
  color: #999;
}

.day-card.future {
  color: #333;
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

.content-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.content-section h3 {
  font-size: 1.3em;
  margin-bottom: 15px;
  color: #333;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #999;
}

.empty-state {
  text-align: center;
  padding: 40px 20px;
}

.empty-icon {
  font-size: 3em;
  margin-bottom: 15px;
}

.empty-state p {
  color: #999;
  font-size: 1em;
}

/* 历史记录列表 */
.history-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.checkin-card {
  background: #F9F9F9;
  border-radius: 15px;
  padding: 15px;
  border-left: 4px solid #999;
}

.checkin-card.status-pending {
  border-left-color: #FFA500;
  background: #FFF8F0;
}

.checkin-card.status-approved {
  border-left-color: #4CAF50;
  background: #F0FFF4;
}

.checkin-card.status-rejected {
  border-left-color: #F44336;
  background: #FFF0F0;
}

.checkin-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.task-info {
  display: flex;
  align-items: center;
  gap: 10px;
}

.task-icon {
  font-size: 1.8em;
}

.task-name {
  font-size: 1.1em;
  font-weight: 600;
  color: #333;
}

.checkin-status {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 0.85em;
  font-weight: 500;
}

.status-pending {
  background: #FFE4B5;
  color: #FF8C00;
}

.status-approved {
  background: #C8E6C9;
  color: #2E7D32;
}

.status-rejected {
  background: #FFCDD2;
  color: #C62828;
}

.checkin-time {
  font-size: 0.9em;
  color: #666;
  margin-bottom: 8px;
}

.checkin-notes {
  font-size: 0.95em;
  color: #333;
  background: white;
  padding: 10px;
  border-radius: 8px;
  margin-bottom: 10px;
}

.checkin-media {
  display: flex;
  gap: 15px;
  margin-bottom: 10px;
}

.media-item {
  font-size: 0.9em;
}

.media-item a {
  color: #667eea;
  text-decoration: none;
}

.media-item a:hover {
  text-decoration: underline;
}

/* 今日任务内容 */
.today-tasks-content {
  display: flex;
  flex-direction: column;
  gap: 15px;
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

.task-card.status-not-start {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.task-card.status-pending {
  background: linear-gradient(135deg, #f6d365 0%, #fda085 100%);
  cursor: not-allowed;
}

.task-card.status-completed {
  background: linear-gradient(135deg, #a8e063 0%, #56ab2f 100%);
  cursor: default;
}

.task-card .task-icon {
  font-size: 2.5em;
}

.task-card .task-info {
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

/* 未来任务列表 */
.future-tasks .task-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.future-tasks .task-card {
  display: flex;
  gap: 15px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 15px;
  padding: 15px;
  color: white;
  align-items: flex-start;
}

.future-tasks .task-card .task-icon {
  font-size: 2.5em;
}

.future-tasks .task-card .task-info {
  flex: 1;
}

.future-tasks .task-card .task-name {
  font-size: 1.1em;
  font-weight: 600;
  margin-bottom: 8px;
  color: white;
}

.future-tasks .task-details {
  display: flex;
  gap: 12px;
  font-size: 0.85em;
  opacity: 0.9;
  flex-wrap: wrap;
}

.task-description {
  margin-top: 8px;
  font-size: 0.9em;
  opacity: 0.85;
  line-height: 1.4;
}
</style>
