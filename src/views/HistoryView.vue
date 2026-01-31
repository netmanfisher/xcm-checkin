<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'
import BottomNav from '../components/BottomNav.vue'

const router = useRouter()
const authStore = useAuthStore()

const selectedDate = ref(null)
const selectedDateCheckIns = ref([])
const loading = ref(false)
const studyPlans = ref([])

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

async function selectDate(dateStr) {
  selectedDate.value = dateStr
  loading.value = true

  try {
    if (!authStore.currentChild?.id) {
      selectedDateCheckIns.value = []
      return
    }

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
    selectedDateCheckIns.value = data || []
  } catch (error) {
    console.error('获取打卡记录失败:', error)
    selectedDateCheckIns.value = []
  } finally {
    loading.value = false
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

function isToday(dateStr) {
  return dateStr === new Date().toISOString().split('T')[0]
}

function getSelectedDateDisplay() {
  if (!selectedDate.value) return ''
  const date = new Date(selectedDate.value)
  return `${date.getMonth() + 1}月${date.getDate()}日`
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

    <!-- 周历选择器 -->
    <section class="week-selector">
      <h3>选择日期</h3>
      <div class="week-grid">
        <div
          v-for="day in weekDates"
          :key="day.dateStr"
          class="day-card"
          :class="{
            selected: selectedDate === day.dateStr,
            today: isToday(day.dateStr)
          }"
          @click="selectDate(day.dateStr)"
        >
          <div class="day-weekday">{{ day.weekday }}</div>
          <div class="day-date">{{ day.day }}</div>
        </div>
      </div>
    </section>

    <!-- 选中日期的打卡详情 -->
    <section class="checkin-details">
      <div class="date-header">
        <h3>{{ getSelectedDateDisplay() }} 打卡详情</h3>
        <div class="stats">
          共 {{ selectedDateCheckIns.length }} 项打卡
        </div>
      </div>

      <div v-if="loading" class="loading">
        加载中...
      </div>

      <div v-else-if="selectedDateCheckIns.length === 0" class="empty-state">
        <div class="empty-icon">📭</div>
        <p>当天没有打卡记录</p>
      </div>

      <div v-else class="checkin-list">
        <div
          v-for="checkin in selectedDateCheckIns"
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

/* 周历选择器 */
.week-selector {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.week-selector h3 {
  font-size: 1.2em;
  color: #333;
  margin-bottom: 15px;
}

.week-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
}

.day-card {
  background: #F5F5F5;
  border-radius: 12px;
  padding: 12px 8px;
  text-align: center;
  cursor: pointer;
  border: 2px solid transparent;
  transition: all 0.3s;
}

.day-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1);
}

.day-card.selected {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: #667eea;
}

.day-card.selected .day-weekday,
.day-card.selected .day-date {
  color: white;
}

.day-card.today {
  border-color: #FFD700;
  background: #FFF8DC;
}

.day-weekday {
  font-size: 0.85em;
  color: #666;
  margin-bottom: 5px;
}

.day-date {
  font-size: 1.3em;
  font-weight: 600;
  color: #333;
}

/* 打卡详情 */
.checkin-details {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.date-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.date-header h3 {
  font-size: 1.3em;
  color: #333;
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
}

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
</style>
