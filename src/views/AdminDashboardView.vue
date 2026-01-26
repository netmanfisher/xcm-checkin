<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../supabase'
import AdminSidebar from '../components/AdminSidebar.vue'

const stats = ref({
  childrenCount: 0,
  pendingReviews: 0,
  todayCompleted: 0
})

const recentActivities = ref([])

onMounted(async () => {
  await fetchStats()
  await fetchRecentActivities()
})

async function fetchStats() {
  try {
    // 孩子数量
    const { count: childrenCount } = await supabase
      .from('xcm_children')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'active')

    // 待审核数量
    const { count: pendingReviews } = await supabase
      .from('xcm_check_ins')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending')

    // 今日完成
    const today = new Date().toISOString().split('T')[0]
    const { count: todayCompleted } = await supabase
      .from('xcm_check_ins')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'approved')
      .gte('check_in_time', today)

    stats.value = {
      childrenCount: childrenCount || 0,
      pendingReviews: pendingReviews || 0,
      todayCompleted: todayCompleted || 0
    }
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
}

async function fetchRecentActivities() {
  // 这里可以获取最近的活动记录
  recentActivities.value = [
    { time: '刚刚', activity: '系统初始化完成' }
  ]
}
</script>

<template>
  <div class="admin-dashboard">
    <AdminSidebar />

    <div class="main-content">
      <h1>数据概览</h1>

      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon">👦👧</div>
          <div class="stat-value">{{ stats.childrenCount }}</div>
          <div class="stat-label">孩子数</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">📋</div>
          <div class="stat-value">{{ stats.pendingReviews }}</div>
          <div class="stat-label">待审核</div>
        </div>
        <div class="stat-card">
          <div class="stat-icon">✅</div>
          <div class="stat-value">{{ stats.todayCompleted }}</div>
          <div class="stat-label">今日完成</div>
        </div>
      </div>

      <section class="quick-actions">
        <h2>快捷操作</h2>
        <div class="action-buttons">
          <router-link to="/admin/plans">📝 添加计划</router-link>
          <router-link to="/admin/wishes">🎁 添加愿望</router-link>
          <router-link to="/admin/children">👧 添加孩子</router-link>
        </div>
      </section>

      <section class="recent-activities">
        <h2>最近活动</h2>
        <div class="activity-list">
          <div
            v-for="activity in recentActivities"
            :key="activity.time"
            class="activity-item"
          >
            <div class="activity-time">{{ activity.time }}</div>
            <div class="activity-content">{{ activity.activity }}</div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.admin-dashboard {
  display: flex;
  min-height: 100vh;
}

.main-content {
  flex: 1;
  margin-left: 250px;
  padding: 30px;
  background: #ECF0F1;
  min-height: 100vh;
}

.main-content h1 {
  font-size: 2em;
  margin-bottom: 30px;
  color: #2C3E50;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  margin-bottom: 30px;
}

.stat-card {
  background: white;
  border-radius: 10px;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  text-align: center;
}

.stat-icon {
  font-size: 2.5em;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 2em;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 0.9em;
  color: #666;
}

.quick-actions {
  background: white;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 30px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

.quick-actions h2 {
  font-size: 1.3em;
  margin-bottom: 15px;
  color: #2C3E50;
}

.action-buttons {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.action-buttons a {
  padding: 10px 20px;
  border: none;
  border-radius: 8px;
  background: #667eea;
  color: white;
  cursor: pointer;
  font-size: 0.9em;
  transition: all 0.3s;
  text-decoration: none;
  display: inline-block;
}

.action-buttons a:hover {
  background: #5568d3;
}

.recent-activities {
  background: white;
  border-radius: 10px;
  padding: 20px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

.recent-activities h2 {
  font-size: 1.3em;
  margin-bottom: 15px;
  color: #2C3E50;
}

.activity-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.activity-item {
  display: flex;
  gap: 15px;
  padding: 10px;
  background: #F5F5F5;
  border-radius: 8px;
}

.activity-time {
  font-size: 0.85em;
  color: #666;
}

.activity-content {
  flex: 1;
  font-size: 0.95em;
  color: #333;
}
</style>
