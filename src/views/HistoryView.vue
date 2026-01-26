<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'
import BottomNav from '../components/BottomNav.vue'

const router = useRouter()
const authStore = useAuthStore()

const history = ref([])
const totalEarned = ref(0)
const totalSpent = ref(0)

onMounted(async () => {
  await fetchHistory()
  await calculateStats()
})

async function fetchHistory() {
  try {
    const { data, error } = await supabase
      .from('xcm_stars_history')
      .select('*')
      .eq('child_id', authStore.currentChild?.id)
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) throw error
    history.value = data
  } catch (error) {
    console.error('获取历史失败:', error)
  }
}

async function calculateStats() {
  try {
    const { data } = await supabase
      .from('xcm_children')
      .select('total_earned, total_spent')
      .eq('id', authStore.currentChild?.id)
      .single()

    if (data) {
      totalEarned.value = data.total_earned
      totalSpent.value = data.total_spent
    }
  } catch (error) {
    console.error('获取统计失败:', error)
  }
}

const currentStars = computed(() => {
  return authStore.currentChild?.stars || 0
})

function goBack() {
  router.push('/home')
}
</script>

<template>
  <div class="history-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <header class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h1>📊 星星历史</h1>
    </header>

    <section class="stats-summary">
      <div class="stat-card">
        <div class="stat-label">累计获得</div>
        <div class="stat-value earned">⭐⭐ {{ totalEarned }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">累计消费</div>
        <div class="stat-value spent">⭐ {{ totalSpent }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">当前星星</div>
        <div class="stat-value current">⭐⭐⭐ {{ currentStars }}</div>
      </div>
    </section>

    <section class="history-list">
      <h2>📜 历史记录</h2>
      <div class="history-items">
        <div
          v-for="item in history"
          :key="item.id"
          class="history-item"
          :class="{ earned: item.type === 'earn', spent: item.type === 'spend' }"
        >
          <div class="history-date">
            {{ new Date(item.created_at).toLocaleString('zh-CN') }}
          </div>
          <div class="history-desc">{{ item.description }}</div>
          <div class="history-amount" :class="item.type">
            {{ item.type === 'earn' ? '+' : '' }}⭐{{ Math.abs(item.amount) }}
          </div>
        </div>
        <div v-if="history.length === 0" class="empty-state">
          还没有历史记录
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
}

.stats-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 15px;
  margin-bottom: 20px;
}

.stat-card {
  background: white;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.stat-label {
  font-size: 0.9em;
  color: #666;
  margin-bottom: 5px;
}

.stat-value {
  font-size: 1.5em;
  font-weight: 600;
}

.stat-value.earned {
  color: #4CAF50;
}

.stat-value.spent {
  color: #FF9800;
}

.stat-value.current {
  color: #FFD700;
}

.history-list {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.history-list h2 {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 15px;
}

.history-items {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.history-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background: #F5F5F5;
  border-radius: 10px;
}

.history-item.earned {
  border-left: 4px solid #4CAF50;
}

.history-item.spent {
  border-left: 4px solid #FF9800;
}

.history-date {
  font-size: 0.9em;
  color: #666;
  margin-bottom: 5px;
}

.history-desc {
  flex: 1;
  font-size: 1em;
  color: #333;
  font-weight: 500;
}

.history-amount.earned {
  color: #4CAF50;
  font-weight: 600;
}

.history-amount.spent {
  color: #FF9800;
  font-weight: 600;
}

.empty-state {
  text-align: center;
  padding: 40px;
  color: #999;
}
</style>
