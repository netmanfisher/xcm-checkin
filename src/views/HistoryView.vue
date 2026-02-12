<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'
import BottomNav from '../components/BottomNav.vue'

const router = useRouter()
const authStore = useAuthStore()

const currentDate = ref(new Date())
const selectedDate = ref(null)
const selectedDateData = ref([])
const loading = ref(false)
const studyPlans = ref([])
const todayCheckIns = ref([])

// 获取当前月份和年份
const currentYear = computed(() => currentDate.value.getFullYear())
const currentMonth = computed(() => currentDate.value.getMonth())

// 获取当月第一天
const firstDayOfMonth = computed(() => {
  return new Date(currentYear.value, currentMonth.value, 1)
})

// 获取当月最后一天
const lastDayOfMonth = computed(() => {
  return new Date(currentYear.value, currentMonth.value + 1, 0)
})

// 获取日历网格（包括前后月份的填充日期）
const calendarDays = computed(() => {
  const firstDay = firstDayOfMonth.value
  const lastDay = lastDayOfMonth.value
  const daysInMonth = lastDay.getDate()
  const startDayOfWeek = firstDay.getDay() === 0 ? 6 : firstDay.getDay() - 1

  const days = []

  // 填充前面的空日期
  for (let i = 0; i < startDayOfWeek; i++) {
    days.push(null)
  }

  // 当月的所有日期
  for (let i = 1; i <= daysInMonth; i++) {
    const date = new Date(currentYear.value, currentMonth.value, i)
    days.push({
      date: date,
      dateStr: date.toISOString().split('T')[0],
      day: i,
      isToday: isToday(date),
      isPast: isPast(date),
      isFuture: isFuture(date)
    })
  }

  return days
})

// 星期标题
const weekDays = ['一', '二', '三', '四', '五', '六', '日']

onMounted(async () => {
  await fetchStudyPlans()
  await fetchTodayCheckIns()
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

async function fetchTodayCheckIns() {
  try {
    if (!authStore.currentChild?.id) {
      todayCheckIns.value = []
      return
    }

    const today = new Date().toISOString().split('T')[0]
    const { data, error } = await supabase
      .from('xcm_check_ins')
      .select('*')
      .eq('child_id', authStore.currentChild.id)
      .gte('check_in_time', today)
      .order('check_in_time')

    if (error) throw error
    todayCheckIns.value = data || []
  } catch (error) {
    console.error('获取今日打卡失败:', error)
  }
}

async function selectDate(dateStr) {
  selectedDate.value = dateStr
  loading.value = true

  try {
    if (!authStore.currentChild?.id) {
      selectedDateData.value = []
      return
    }

    const date = new Date(dateStr)

    if (isPast(date)) {
      // 过去的日期：查询历史打卡记录
      await fetchHistoryCheckIns(dateStr)
    } else if (isToday(date)) {
      // 今天：显示今天的打卡情况
      await fetchTodayCheckInsData(dateStr)
    } else {
      // 未来的日期：显示该日期需要打卡的任务
      await fetchPlannedTasks(dateStr)
    }
  } catch (error) {
    console.error('获取日期数据失败:', error)
    selectedDateData.value = []
  } finally {
    loading.value = false
  }
}

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
    selectedDateData.value = { type: 'history', data: data || [] }
  } catch (error) {
    console.error('获取历史打卡失败:', error)
    selectedDateData.value = { type: 'history', data: [] }
  }
}

async function fetchTodayCheckInsData(dateStr) {
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
    selectedDateData.value = { type: 'today', data: data || [] }
  } catch (error) {
    console.error('获取今日打卡失败:', error)
    selectedDateData.value = { type: 'today', data: [] }
  }
}

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

    selectedDateData.value = { type: 'future', data: plannedTasks }
  } catch (error) {
    console.error('获取计划任务失败:', error)
    selectedDateData.value = { type: 'future', data: [] }
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

function isToday(date) {
  const today = new Date()
  return date.getDate() === today.getDate() &&
         date.getMonth() === today.getMonth() &&
         date.getFullYear() === today.getFullYear()
}

function isPast(date) {
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const compareDate = new Date(date)
  compareDate.setHours(0, 0, 0, 0)
  return compareDate < today
}

function isFuture(date) {
  const today = new Date()
  today.setHours(23, 59, 59, 999)
  const compareDate = new Date(date)
  compareDate.setHours(0, 0, 0, 0)
  return compareDate > today
}

function getSelectedDateDisplay() {
  if (!selectedDate.value) return ''
  const date = new Date(selectedDate.value)
  return `${date.getMonth() + 1}月${date.getDate()}日`
}

function getMonthDisplay() {
  return `${currentYear.value}年${currentMonth.value + 1}月`
}

function previousMonth() {
  currentDate.value = new Date(currentYear.value, currentMonth.value - 1, 1)
}

function nextMonth() {
  currentDate.value = new Date(currentYear.value, currentMonth.value + 1, 1)
}

function goToToday() {
  currentDate.value = new Date()
  const today = new Date().toISOString().split('T')[0]
  selectDate(today)
}

function goBack() {
  router.push('/home')
}
</script>

<template>
  <div class="history-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <header class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h1>📅 打卡记录</h1>
    </header>

    <!-- 月历选择器 -->
    <section class="calendar-selector">
      <div class="calendar-header">
        <button class="month-nav" @click="previousMonth">◀</button>
        <h3>{{ getMonthDisplay() }}</h3>
        <button class="month-nav" @click="nextMonth">▶</button>
      </div>
      <button class="today-btn" @click="goToToday">回到今天</button>

      <div class="calendar-grid">
        <!-- 星期标题 -->
        <div v-for="day in weekDays" :key="day" class="weekday-header">
          {{ day }}
        </div>

        <!-- 日期格子 -->
        <div
          v-for="(day, index) in calendarDays"
          :key="index"
          class="day-cell"
          :class="{
            'empty': !day,
            'today': day?.isToday,
            'selected': selectedDate === day?.dateStr,
            'past': day?.isPast,
            'future': day?.isFuture
          }"
          @click="day && selectDate(day.dateStr)"
        >
          <div v-if="day" class="day-number">
            {{ day.day }}
          </div>
        </div>
      </div>
    </section>

    <!-- 选中日期的内容 -->
    <section class="date-content">
      <!-- 历史打卡记录 -->
      <div v-if="selectedDateData.type === 'history'" class="content-section">
        <div class="content-header">
          <h3>{{ getSelectedDateDisplay() }} 历史记录</h3>
          <div class="stats">共 {{ selectedDateData.data.length }} 项打卡</div>
        </div>

        <div v-if="loading" class="loading">加载中...</div>

        <div v-else-if="selectedDateData.data.length === 0" class="empty-state">
          <div class="empty-icon">📭</div>
          <p>当天没有打卡记录</p>
        </div>

        <div v-else class="checkin-list">
          <div
            v-for="checkin in selectedDateData.data"
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

            <div v-if="checkin.status !== 'pending'" class="review-info">
              <div v-if="checkin.reviewed_at" class="review-time">
                审核时间：{{ new Date(checkin.reviewed_at).toLocaleString('zh-CN') }}
              </div>
              <div v-if="checkin.review_note" class="review-note">
                备注：{{ checkin.review_note }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 今日打卡情况 -->
      <div v-else-if="selectedDateData.type === 'today'" class="content-section">
        <div class="content-header">
          <h3>今天打卡情况</h3>
          <div class="stats">
            已完成 {{ selectedDateData.data.filter(d => d.status === 'approved').length }} /
            共 {{ selectedDateData.data.length }} 项
          </div>
        </div>

        <div v-if="loading" class="loading">加载中...</div>

        <div v-else-if="selectedDateData.data.length === 0" class="empty-state">
          <div class="empty-icon">📝</div>
          <p>今天还没有打卡记录</p>
          <button class="go-home-btn" @click="router.push('/home')">去打卡</button>
        </div>

        <div v-else class="checkin-list">
          <div
            v-for="checkin in selectedDateData.data"
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
          </div>
        </div>
      </div>

      <!-- 未来计划任务 -->
      <div v-else-if="selectedDateData.type === 'future'" class="content-section">
        <div class="content-header">
          <h3>{{ getSelectedDateDisplay() }} 计划任务</h3>
          <div class="stats">共 {{ selectedDateData.data.length }} 项任务</div>
        </div>

        <div v-if="loading" class="loading">加载中...</div>

        <div v-else-if="selectedDateData.data.length === 0" class="empty-state">
          <div class="empty-icon">😴</div>
          <p>当天没有安排任务</p>
        </div>

        <div v-else class="task-list">
          <div
            v-for="task in selectedDateData.data"
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

    <BottomNav />
  </div>
</template>

<style scoped>
.history-container {
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
  display: flex;
  align-items: center;
  margin-bottom: 20px;
}

.back-btn {
  background: none;
  border: none;
  font-size: 1.2em;
  color: white;
  cursor: pointer;
  margin-right: 15px;
}

.header h1 {
  font-size: 2em;
  color: white;
  flex: 1;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
}

/* 日历选择器 */
.calendar-selector {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.calendar-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.calendar-header h3 {
  font-size: 1.3em;
  color: #333;
  margin: 0;
}

.month-nav {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  font-size: 1.2em;
  cursor: pointer;
  transition: all 0.3s;
}

.month-nav:hover {
  transform: scale(1.1);
  box-shadow: 0 3px 10px rgba(102, 126, 234, 0.3);
}

.today-btn {
  width: 100%;
  background: #FFD700;
  color: #333;
  border: none;
  padding: 10px;
  border-radius: 10px;
  font-size: 1em;
  font-weight: 600;
  cursor: pointer;
  margin-bottom: 15px;
  transition: all 0.3s;
}

.today-btn:hover {
  background: #FFC107;
  transform: translateY(-2px);
  box-shadow: 0 3px 10px rgba(255, 215, 0, 0.3);
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 8px;
}

.weekday-header {
  text-align: center;
  font-size: 0.9em;
  color: #666;
  font-weight: 600;
  padding: 10px 0;
}

.day-cell {
  aspect-ratio: 1;
  background: #F5F5F5;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.3s;
  font-size: 1em;
}

.day-cell:hover:not(.empty) {
  transform: scale(1.05);
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
}

.day-cell.selected {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: #667eea;
  font-weight: 600;
}

.day-cell.today {
  border-color: #FFD700;
  background: #FFF8DC;
  font-weight: 700;
}

.day-cell.today.selected {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.day-cell.past {
  color: #999;
}

.day-cell.future {
  color: #333;
}

.day-cell.empty {
  background: transparent;
  cursor: default;
}

.day-number {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

/* 内容区域 */
.date-content {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.content-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.content-header h3 {
  font-size: 1.3em;
  color: #333;
  margin: 0;
}

.stats {
  font-size: 0.9em;
  color: #666;
  background: #F5F5F5;
  padding: 5px 12px;
  border-radius: 15px;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #999;
  font-size: 1.1em;
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
  margin-bottom: 15px;
}

.go-home-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 12px 30px;
  border-radius: 10px;
  font-size: 1em;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.go-home-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

/* 打卡列表 */
.checkin-list {
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

.review-info {
  border-top: 1px solid #E0E0E0;
  padding-top: 10px;
  margin-top: 10px;
}

.review-time {
  font-size: 0.85em;
  color: #666;
  margin-bottom: 5px;
}

.review-note {
  font-size: 0.9em;
  color: #333;
  background: #FFF9E6;
  padding: 8px;
  border-radius: 6px;
}

/* 任务列表 */
.task-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.task-card {
  display: flex;
  gap: 15px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 15px;
  padding: 15px;
  color: white;
  align-items: flex-start;
}

.task-card .task-icon {
  font-size: 2.5em;
}

.task-card .task-info {
  flex: 1;
}

.task-card .task-name {
  font-size: 1.1em;
  font-weight: 600;
  margin-bottom: 8px;
  color: white;
}

.task-details {
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
