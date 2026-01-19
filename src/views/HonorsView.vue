<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const achievements = ref([])
const streakInfo = ref(null)
const totalCompleted = ref(0)

onMounted(async () => {
  await fetchData()
})

async function fetchData() {
  try {
    // 获取成就
    const { data: achievements } = await supabase
      .from('xcm_user_achievements')
      .select('*, xcm_achievements(*)')
      .eq('child_id', authStore.currentChild?.id)

    // 获取连续打卡
    const { data: streak } = await supabase
      .from('xcm_streaks')
      .select('*')
      .eq('child_id', authStore.currentChild?.id)
      .single()

    // 获取总完成次数
    const { count } = await supabase
      .from('xcm_check_ins')
      .select('*', { count: 'exact', head: true })
      .eq('child_id', authStore.currentChild?.id)
      .eq('status', 'approved')

    achievements.value = achievements || []
    streakInfo.value = streak
    totalCompleted.value = count || 0
  } catch (error) {
    console.error('获取数据失败:', error)
  }
}

const totalStars = computed(() => {
  return authStore.currentChild?.stars || 0
})

function goBack() {
  router.push('/home')
}
</script>

<template>
  <div class="honors-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <header class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h1>🏆 荣誉墙</h1>
    </header>

    <section class="stars-section">
      <div class="stars-display">
        <div class="stars-icon">⭐</div>
        <div class="stars-amount">{{ totalStars }}</div>
        <div class="stars-label">当前星星</div>
      </div>
    </section>

    <section class="achievements-section">
      <h2>🏆 我的成就</h2>
      <div class="achievements-grid">
        <div
          v-for="item in achievements"
          :key="item.id"
          class="achievement-card"
        >
          <div class="achievement-icon">{{ item.xcm_achievements.icon }}</div>
          <div class="achievement-name">{{ item.xcm_achievements.name }}</div>
          <div class="achievement-desc">{{ item.xcm_achievements.description }}</div>
        </div>
        <div v-if="achievements.length === 0" class="empty-state">
          还没有获得成就哦，继续努力！💪
        </div>
      </div>
    </section>

    <section class="stats-section">
      <h2>📊 学习统计</h2>
      <div class="stats-grid">
        <div class="stat-item">
          <div class="stat-icon">🔥</div>
          <div class="stat-value">{{ streakInfo?.current_streak || 0 }}天</div>
          <div class="stat-label">连续打卡</div>
        </div>
        <div class="stat-item">
          <div class="stat-icon">📚</div>
          <div class="stat-value">{{ totalCompleted }}</div>
          <div class="stat-label">累计完成</div>
        </div>
        <div class="stat-item">
          <div class="stat-icon">🏅</div>
          <div class="stat-value">{{ streakInfo?.longest_streak || 0 }}天</div>
          <div class="stat-label">最长连续</div>
        </div>
      </div>
    </section>

    <nav class="bottom-nav">
      <button @click="router.push('/home')">
        <span class="icon">🏠</span>
        <span>首页</span>
      </button>
      <button @click="router.push('/wishes')">
        <span class="icon">🎁</span>
        <span>愿望</span>
      </button>
      <button @click="router.push('/history')">
        <span class="icon">📊</span>
        <span>历史</span>
      </button>
      <button @click="router.push('/report')">
        <span class="icon">📈</span>
        <span>报告</span>
      </button>
    </nav>
  </div>
</template>

<style scoped>
.honors-container {
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

.stars-section {
  background: white;
  border-radius: 20px;
  padding: 30px;
  margin-bottom: 20px;
  text-align: center;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.stars-display {
  max-width: 300px;
  margin: 0 auto;
}

.stars-icon {
  font-size: 4em;
  margin-bottom: 10px;
}

.stars-amount {
  font-size: 3em;
  font-weight: bold;
  color: #FFD700;
  margin-bottom: 5px;
}

.stars-label {
  font-size: 1.2em;
  color: #666;
}

.achievements-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.achievements-section h2 {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 15px;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 15px;
}

.achievement-card {
  background: #F5F5F5;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
}

.achievement-icon {
  font-size: 3em;
  margin-bottom: 10px;
}

.achievement-name {
  font-size: 1.1em;
  font-weight: 600;
  color: #333;
  margin-bottom: 5px;
}

.achievement-desc {
  font-size: 0.9em;
  color: #666;
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 40px;
  color: #999;
  font-size: 1.1em;
}

.stats-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.stats-section h2 {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 15px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
  gap: 15px;
}

.stat-item {
  background: #F5F5F5;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
}

.stat-icon {
  font-size: 2em;
  margin-bottom: 10px;
}

.stat-value {
  font-size: 1.8em;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 5px;
}

.stat-label {
  font-size: 0.9em;
  color: #666;
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
