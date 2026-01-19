<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const selectedMonth = ref(new Date().toISOString().slice(0, 7))
const monthData = ref({
  totalDays: 0,
  completedDays: 0,
  totalTasks: 0,
  completedTasks: 0,
  earnedStars: 0
})
const dailyData = ref([])

onMounted(async () => {
  await fetchMonthData()
})

async function fetchMonthData() {
  try {
    const month = selectedMonth.value
    const startDate = `${month}-01`
    const lastDay = new Date(parseInt(month.slice(0, 4)), parseInt(month.slice(5, 7)), 0)
    const endDate = lastDay.toISOString().slice(0, 10)

    // 获取该月的所有打卡记录
    const { data: checkIns } = await supabase
      .from('xcm_check_ins')
      .select('check_in_time, plan_id')
      .eq('child_id', authStore.currentChild?.id)
      .gte('check_in_time', startDate)
      .lte('check_in_time', endDate)
      .eq('status', 'approved')

    if (checkIns && checkIns.length > 0) {
      // 统计每天完成数
      const dailyStats = {}
      checkIns.forEach(item => {
        const date = item.check_in_time.split('T')[0]
        if (!dailyStats[date]) {
          dailyStats[date] = new Set()
        }
        dailyStats[date].add(item.plan_id)
      })

      dailyData.value = Object.keys(dailyStats).map(date => ({
        date,
        count: dailyStats[date].size
      }))

      // 计算统计数据
      const daysInMonth = new Date(parseInt(month.slice(0, 4)), parseInt(month.slice(5, 7)) + 1, 0).getDate()
      monthData.value = {
        totalDays: daysInMonth,
        completedDays: Object.keys(dailyStats).length,
        totalTasks: checkIns.length,
        completedTasks: checkIns.length,
        earnedStars: checkIns.length * 30 // 简化计算
      }
    }
  } catch (error) {
    console.error('获取月度数据失败:', error)
  }
}

function exportPDF() {
  alert('PDF导出功能开发中...')
}

function goBack() {
  router.push('/home')
}
</script>

<template>
  <div class="report-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <header class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h1>📈 月度报告</h1>
    </header>

    <section class="month-selector">
      <input
        v-model="selectedMonth"
        type="month"
        @change="fetchMonthData"
        class="month-input"
      />
    </section>

    <section class="summary">
      <h3>📊 本月概览</h3>
      <div class="summary-grid">
        <div class="summary-item">
          <div class="summary-label">完成天数</div>
          <div class="summary-value">{{ monthData.completedDays }}/{{ monthData.totalDays }}天</div>
        </div>
        <div class="summary-item">
          <div class="summary-label">完成任务</div>
          <div class="summary-value">{{ monthData.completedTasks }}项</div>
        </div>
        <div class="summary-item">
          <div class="summary-label">完成率</div>
          <div class="summary-value">{{ Math.round((monthData.completedDays / monthData.totalDays) * 100) }}%</div>
        </div>
        <div class="summary-item">
          <div class="summary-label">获得星星</div>
          <div class="summary-value">⭐ {{ monthData.earnedStars }}</div>
        </div>
      </div>
    </section>

    <section class="chart-section">
      <h3>📈 每日完成趋势</h3>
      <div class="chart-placeholder">
        <div class="bar-chart">
          <div
            v-for="day in dailyData"
            :key="day.date"
            class="bar"
            :style="{ height: `${(day.count / 6) * 100}%` }"
          >
            <div class="bar-label">{{ day.date.slice(8) }}日</div>
            <div class="bar-value">{{ day.count }}项</div>
          </div>
        </div>
      </div>
    </section>

    <section class="actions">
      <button class="action-btn" @click="exportPDF">
        📄 导出PDF
      </button>
      <button class="action-btn" onclick="window.print()">
        🖨️ 打印
      </button>
    </section>

    <nav class="bottom-nav">
      <button @click="router.push('/home')">
        <span class="icon">🏠</span>
        <span>首页</span>
      </button>
      <button @click="router.push('/honors')">
        <span class="icon">🏆</span>
        <span>荣誉</span>
      </button>
      <button @click="router.push('/wishes')">
        <span class="icon">🎁</span>
        <span>愿望</span>
      </button>
      <button @click="router.push('/history')">
        <span class="icon">📊</span>
        <span>历史</span>
      </button>
    </nav>
  </div>
</template>

<style scoped>
.report-container {
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
}

.month-selector {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.month-input {
  width: 100%;
  padding: 10px;
  border: 2px solid #E5E5EA;
  border-radius: 10px;
  font-size: 1em;
}

.summary {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.summary h3 {
  font-size: 1.3em;
  color: #333;
  margin-bottom: 15px;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 15px;
}

.summary-item {
  background: #F5F5F5;
  border-radius: 15px;
  padding: 15px;
  text-align: center;
}

.summary-label {
  font-size: 0.9em;
  color: #666;
  margin-bottom: 5px;
}

.summary-value {
  font-size: 1.5em;
  font-weight: 600;
  color: #667eea;
}

.chart-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.chart-section h3 {
  font-size: 1.3em;
  color: #333;
  margin-bottom: 15px;
}

.chart-placeholder {
  height: 200px;
  display: flex;
  align-items: flex-end;
  gap: 5px;
  padding: 20px 0;
}

.bar-chart {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  width: 100%;
  gap: 5px;
}

.bar {
  flex: 1;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 10px 10px 0 0;
  min-height: 20px;
  position: relative;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
  padding: 5px;
}

.bar-label {
  font-size: 0.7em;
  color: #666;
  margin-top: 5px;
}

.bar-value {
  font-size: 0.8em;
  color: white;
  font-weight: 600;
}

.actions {
  background: white;
  border-radius: 20px;
  padding: 20px;
  display: flex;
  gap: 15px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.action-btn {
  flex: 1;
  padding: 15px;
  border: none;
  border-radius: 10px;
  font-size: 1em;
  cursor: pointer;
  transition: all 0.3s;
}

.action-btn:first-child {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.action-btn:last-child {
  background: #E5E5EA;
  color: #333;
}

.action-btn:hover {
  transform: translateY(-2px);
}

.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: white;
  display: flex;
  justify-content: space-around;
  padding: 10px;
  box-shadow: 0 -5px 15px rgba(0, 0, 0, 0.1);
}

.bottom-nav button {
  background: none;
  border: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  color: #666;
  cursor: pointer;
  font-size: 0.8em;
  padding: 5px 10px;
  border-radius: 10px;
  transition: all 0.3s;
}

.bottom-nav button:hover {
  background: #F5F5F5;
}

.bottom-nav button .icon {
  font-size: 1.5em;
}
</style>
