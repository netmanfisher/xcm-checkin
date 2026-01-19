<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const wishes = ref([])
const redeemedHistory = ref([])
const showRedeemConfirm = ref(false)
const selectedWish = ref(null)

const availableStars = computed(() => {
  return authStore.currentChild?.stars || 0
})

onMounted(async () => {
  await fetchWishes()
  await fetchRedeemedHistory()
})

async function fetchWishes() {
  try {
    const { data, error } = await supabase
      .from('xcm_wishes')
      .select('*')
      .eq('status', 'available')
      .order('sort_order')

    if (error) throw error
    wishes.value = data
  } catch (error) {
    console.error('获取愿望失败:', error)
  }
}

async function fetchRedeemedHistory() {
  try {
    const { data, error } = await supabase
      .from('xcm_redemptions')
      .select('*')
      .eq('child_id', authStore.currentChild?.id)
      .order('redeemed_at', { ascending: false })
      .limit(10)

    if (error) throw error
    redeemedHistory.value = data
  } catch (error) {
    console.error('获取兑换历史失败:', error)
  }
}

function confirmRedeem(wish) {
  if (availableStars.value < wish.stars_cost) {
    alert('星星不足！')
    return
  }
  selectedWish.value = wish
  showRedeemConfirm.value = true
}

async function redeemWish() {
  if (!selectedWish.value) return

  try {
    // 1. 创建兑换记录
    const { error: redeemError } = await supabase
      .from('xcm_redemptions')
      .insert({
        child_id: authStore.currentChild?.id,
        wish_id: selectedWish.value.id,
        wish_name: selectedWish.value.name,
        stars_cost: selectedWish.value.stars_cost
      })

    if (redeemError) throw redeemError

    // 2. 扣除星星
    const newStars = availableStars.value - selectedWish.value.stars_cost
    await supabase
      .from('xcm_children')
      .update({ stars: newStars })
      .eq('id', authStore.currentChild?.id)

    // 3. 记录星星历史
    await supabase
      .from('xcm_stars_history')
      .insert({
        child_id: authStore.currentChild?.id,
        type: 'spend',
        amount: -selectedWish.value.stars_cost,
        description: `兑换愿望：${selectedWish.value.name}`,
        related_id: selectedWish.value.id,
        related_type: 'wish'
      })

    // 4. 更新本地状态
    authStore.currentChild.stars = newStars

    // 5. 刷新数据
    await fetchWishes()
    await fetchRedeemedHistory()

    showRedeemConfirm.value = false
    selectedWish.value = null

    alert('兑换成功！')
  } catch (error) {
    console.error('兑换失败:', error)
    alert('兑换失败，请重试')
  }
}

function goBack() {
  router.push('/home')
}
</script>

<template>
  <div class="wishes-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <header class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h1>🎁 愿望清单</h1>
      <div class="stars-balance">⭐ {{ availableStars }}</div>
    </header>

    <section class="wishes-section">
      <h2>🎁 可兑换愿望</h2>
      <div class="wishes-grid">
        <div
          v-for="wish in wishes"
          :key="wish.id"
          class="wish-card"
          @click="confirmRedeem(wish)"
        >
          <div class="wish-icon">{{ wish.icon }}</div>
          <div class="wish-name">{{ wish.name }}</div>
          <div class="wish-cost">⭐{{ wish.stars_cost }}</div>
        </div>
        <div v-if="wishes.length === 0" class="empty-state">
          暂时没有可兑换的愿望
        </div>
      </div>
    </section>

    <section class="history-section">
      <h2>📋 已兑换历史</h2>
      <div class="history-list">
        <div
          v-for="item in redeemedHistory"
          :key="item.id"
          class="history-item"
        >
          <div class="history-date">
            {{ new Date(item.redeemed_at).toLocaleDateString('zh-CN') }}
          </div>
          <div class="history-wish">{{ item.wish_name }}</div>
          <div class="history-cost">-⭐{{ item.stars_cost }}</div>
        </div>
        <div v-if="redeemedHistory.length === 0" class="empty-state">
          还没有兑换记录
        </div>
      </div>
    </section>

    <!-- 兑换确认弹窗 -->
    <div v-if="showRedeemConfirm" class="modal-overlay" @click="showRedeemConfirm = false">
      <div class="modal-content" @click.stop>
        <h2>确认兑换</h2>
        <div class="wish-detail">
          <p>愿望：{{ selectedWish?.name }}</p>
          <p>消耗：⭐{{ selectedWish?.stars_cost }}</p>
          <p>当前星星：⭐{{ availableStars }}</p>
          <p class="warning">兑换后无法退还，确定要兑换吗？</p>
        </div>
        <div class="modal-actions">
          <button class="cancel-btn" @click="showRedeemConfirm = false">取消</button>
          <button class="confirm-btn" @click="redeemWish">确认兑换</button>
        </div>
      </div>
    </div>

    <nav class="bottom-nav">
      <button @click="router.push('/home')">
        <span class="icon">🏠</span>
        <span>首页</span>
      </button>
      <button @click="router.push('/honors')">
        <span class="icon">🏆</span>
        <span>荣誉</span>
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
.wishes-container {
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

.stars-balance {
  background: #FFD700;
  color: white;
  padding: 5px 15px;
  border-radius: 20px;
  font-weight: 600;
}

.wishes-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.wishes-section h2 {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 15px;
}

.wishes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 15px;
}

.wish-card {
  background: #F5F5F5;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.wish-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.2);
}

.wish-icon {
  font-size: 3em;
  margin-bottom: 10px;
}

.wish-name {
  font-size: 1em;
  color: #333;
  margin-bottom: 10px;
  font-weight: 600;
}

.wish-cost {
  color: #FF6B6B;
  font-weight: 600;
}

.empty-state {
  grid-column: 1 / -1;
  text-align: center;
  padding: 40px;
  color: #999;
}

.history-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.history-section h2 {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 15px;
}

.history-list {
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

.history-date {
  font-size: 0.9em;
  color: #666;
}

.history-wish {
  flex: 1;
  text-align: center;
  font-weight: 500;
  color: #333;
}

.history-cost {
  color: #FF6B6B;
  font-weight: 600;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 20px;
  padding: 30px;
  max-width: 400px;
  width: 90%;
}

.modal-content h2 {
  font-size: 1.5em;
  margin-bottom: 20px;
  color: #333;
}

.wish-detail {
  margin-bottom: 20px;
}

.wish-detail p {
  margin-bottom: 10px;
  font-size: 1.1em;
  color: #333;
}

.warning {
  color: #FF6B6B;
  font-weight: 600;
}

.modal-actions {
  display: flex;
  gap: 15px;
}

.cancel-btn,
.confirm-btn {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 10px;
  font-size: 1em;
  cursor: pointer;
  transition: all 0.3s;
}

.cancel-btn {
  background: #E5E5EA;
  color: #333;
}

.confirm-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
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
