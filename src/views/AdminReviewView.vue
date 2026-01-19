<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const pendingCheckIns = ref([])
const loading = ref(false)
const processing = ref(false)

onMounted(async () => {
  await fetchPendingCheckIns()
})

async function fetchPendingCheckIns() {
  try {
    loading.value = true

    // 先获取待审核打卡
    const { data: checkIns, error } = await supabase
      .from('xcm_check_ins')
      .select('*')
      .eq('status', 'pending')
      .order('check_in_time', { ascending: false })

    if (error) throw error

    // 获取所有孩子信息
    const { data: children } = await supabase
      .from('xcm_children')
      .select('id, name, avatar_url')

    // 获取所有计划信息
    const { data: plans } = await supabase
      .from('xcm_study_plans')
      .select('id, name, icon, stars_reward')

    // 组合数据
    pendingCheckIns.value = (checkIns || []).map(checkIn => ({
      ...checkIn,
      xcm_children: children?.find(c => c.id === checkIn.child_id) || {},
      xcm_study_plans: plans?.find(p => p.id === checkIn.plan_id) || {}
    }))
  } catch (error) {
    console.error('获取待审核打卡失败:', error)
    alert('获取待审核打卡失败')
  } finally {
    loading.value = false
  }
}

async function approveCheckIn(checkIn) {
  if (!confirm(`确认通过 ${checkIn.xcm_children.name} 的「${checkIn.xcm_study_plans.name}」打卡？`)) {
    return
  }

  try {
    processing.value = true

    // 更新打卡状态
    const updateData = {
      status: 'approved',
      reviewed_at: new Date().toISOString()
    }

    // 如果有 reviewer_id 字段才添加
    const { error: updateError } = await supabase
      .from('xcm_check_ins')
      .update(updateData)
      .eq('id', checkIn.id)

    if (updateError) throw updateError

    // 奖励星星
    const { data: child } = await supabase
      .from('xcm_children')
      .select('stars')
      .eq('id', checkIn.child_id)
      .single()

    const newStars = (child?.stars || 0) + (checkIn.xcm_study_plans?.stars_reward || 0)

    const { error: childError } = await supabase
      .from('xcm_children')
      .update({ stars: newStars })
      .eq('id', checkIn.child_id)

    if (childError) throw childError

    // 记录星星历史
    const { error: historyError } = await supabase
      .from('xcm_stars_history')
      .insert({
        child_id: checkIn.child_id,
        amount: checkIn.xcm_study_plans.stars_reward,
        type: 'earned',
        source: 'checkin',
        related_id: checkIn.id,
        description: `完成「${checkIn.xcm_study_plans.name}」`,
        transaction_time: new Date().toISOString()
      })

    if (historyError) throw historyError

    // 更新连续打卡
    await updateStreak(checkIn.child_id)

    alert('审核通过！已奖励 ⭐' + checkIn.xcm_study_plans.stars_reward)
    await fetchPendingCheckIns()
  } catch (error) {
    console.error('审核失败:', error)
    alert('审核失败，请重试')
  } finally {
    processing.value = false
  }
}

async function rejectCheckIn(checkIn) {
  const reason = prompt(`确认拒绝 ${checkIn.xcm_children.name} 的「${checkIn.xcm_study_plans.name}」打卡？\n请输入拒绝原因（可选）：`)
  if (reason === null) return // 用户取消

  try {
    processing.value = true

    const updateData = {
      status: 'rejected',
      rejection_reason: reason || '未通过审核',
      reviewed_at: new Date().toISOString()
    }

    const { error } = await supabase
      .from('xcm_check_ins')
      .update(updateData)
      .eq('id', checkIn.id)

    if (error) throw error

    alert('已拒绝该打卡')
    await fetchPendingCheckIns()
  } catch (error) {
    console.error('审核失败:', error)
    alert('审核失败，请重试')
  } finally {
    processing.value = false
  }
}

async function updateStreak(childId) {
  try {
    // 获取今日已完成的打卡数量
    const today = new Date().toISOString().split('T')[0]
    const { data: todayCheckIns } = await supabase
      .from('xcm_check_ins')
      .select('id')
      .eq('child_id', childId)
      .eq('status', 'approved')
      .gte('check_in_time', today)

    // 如果是今天第一次完成打卡，更新连续天数
    if (todayCheckIns && todayCheckIns.length === 1) {
      const { data: streakData } = await supabase
        .from('xcm_streaks')
        .select('*')
        .eq('child_id', childId)
        .single()

      if (streakData) {
        const yesterday = new Date()
        yesterday.setDate(yesterday.getDate() - 1)
        const yesterdayStr = yesterday.toISOString().split('T')[0]

        if (streakData.last_check_in_date === yesterdayStr) {
          // 连续打卡
          await supabase
            .from('xcm_streaks')
            .update({
              current_streak: streakData.current_streak + 1,
              last_check_in_date: today
            })
            .eq('child_id', childId)
        } else if (streakData.last_check_in_date !== today) {
          // 中断了，重新开始
          await supabase
            .from('xcm_streaks')
            .update({
              current_streak: 1,
              last_check_in_date: today
            })
            .eq('child_id', childId)
        }
      } else {
        // 创建新的连续记录
        await supabase
          .from('xcm_streaks')
          .insert({
            child_id: childId,
            current_streak: 1,
            longest_streak: 1,
            last_check_in_date: today
          })
      }
    }
  } catch (error) {
    console.error('更新连续打卡失败:', error)
  }
}

function formatTime(timeStr) {
  const date = new Date(timeStr)
  return date.toLocaleString('zh-CN')
}

function viewPhoto(photoUrl) {
  window.open(photoUrl, '_blank')
}

function playAudio(audioUrl) {
  new Audio(audioUrl).play()
}
</script>

<template>
  <div class="review-container">
    <div class="header">
      <button class="back-btn" @click="router.push('/admin')">← 返回</button>
      <h2>📋 待审核打卡</h2>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <div v-else-if="pendingCheckIns.length === 0" class="empty">
      <div class="empty-icon">🎉</div>
      <p>暂无待审核打卡</p>
    </div>

    <div v-else class="checkin-list">
      <div
        v-for="checkIn in pendingCheckIns"
        :key="checkIn.id"
        class="checkin-card"
      >
        <div class="checkin-header">
          <div class="child-info">
            <div class="child-avatar">{{ checkIn.xcm_children.avatar_url || '👤' }}</div>
            <div>
              <div class="child-name">{{ checkIn.xcm_children.name }}</div>
              <div class="checkin-time">{{ formatTime(checkIn.check_in_time) }}</div>
            </div>
          </div>
          <div class="plan-info">
            <span class="plan-icon">{{ checkIn.xcm_study_plans.icon }}</span>
            <span class="plan-name">{{ checkIn.xcm_study_plans.name }}</span>
            <span class="plan-reward">+⭐{{ checkIn.xcm_study_plans.stars_reward }}</span>
          </div>
        </div>

        <div v-if="checkIn.photo_url" class="checkin-photo">
          <img :src="checkIn.photo_url" alt="打卡照片" @click="viewPhoto(checkIn.photo_url)">
          <div class="photo-hint">点击查看大图</div>
        </div>

        <div v-if="checkIn.audio_url" class="checkin-audio">
          <button class="play-btn" @click="playAudio(checkIn.audio_url)">
            🔊 播放录音
          </button>
        </div>

        <div v-if="checkIn.note" class="checkin-note">
          <strong>备注：</strong>{{ checkIn.note }}
        </div>

        <div class="checkin-actions">
          <button
            class="reject-btn"
            @click="rejectCheckIn(checkIn)"
            :disabled="processing"
          >
            ❌ 拒绝
          </button>
          <button
            class="approve-btn"
            @click="approveCheckIn(checkIn)"
            :disabled="processing"
          >
            ✅ 通过
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.review-container {
  min-height: 100vh;
  background: #F5F5F5;
  padding: 20px;
  padding-bottom: 100px;
}

.header {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
  display: flex;
  align-items: center;
  gap: 15px;
}

.back-btn {
  background: none;
  border: none;
  font-size: 1.2em;
  cursor: pointer;
  padding: 5px 10px;
  border-radius: 10px;
  transition: background 0.3s;
}

.back-btn:hover {
  background: #F5F5F5;
}

.header h2 {
  flex: 1;
  font-size: 1.5em;
  color: #333;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 1.2em;
}

.empty {
  text-align: center;
  padding: 60px 20px;
  background: white;
  border-radius: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.empty-icon {
  font-size: 4em;
  margin-bottom: 20px;
}

.empty p {
  color: #999;
  font-size: 1.2em;
}

.checkin-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.checkin-card {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.checkin-header {
  margin-bottom: 15px;
}

.child-info {
  display: flex;
  align-items: center;
  gap: 15px;
  margin-bottom: 15px;
}

.child-avatar {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  background: #F0F0F0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5em;
}

.child-name {
  font-size: 1.2em;
  font-weight: 600;
  color: #333;
}

.checkin-time {
  font-size: 0.9em;
  color: #999;
  margin-top: 5px;
}

.plan-info {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 15px;
  background: #F8F8FF;
  border-radius: 10px;
}

.plan-icon {
  font-size: 1.5em;
}

.plan-name {
  flex: 1;
  font-weight: 600;
  color: #333;
}

.plan-reward {
  color: #FFD700;
  font-weight: 600;
}

.checkin-photo {
  margin-bottom: 15px;
}

.checkin-photo img {
  width: 100%;
  max-width: 400px;
  border-radius: 10px;
  cursor: pointer;
  transition: transform 0.3s;
}

.checkin-photo img:hover {
  transform: scale(1.02);
}

.photo-hint {
  text-align: center;
  color: #999;
  font-size: 0.85em;
  margin-top: 5px;
}

.checkin-audio {
  margin-bottom: 15px;
}

.play-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 10px;
  padding: 10px 20px;
  cursor: pointer;
  transition: all 0.3s;
}

.play-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

.checkin-note {
  padding: 10px 15px;
  background: #FFF9E6;
  border-left: 3px solid #FFD700;
  border-radius: 5px;
  margin-bottom: 15px;
  color: #666;
}

.checkin-actions {
  display: flex;
  gap: 15px;
}

.approve-btn, .reject-btn {
  flex: 1;
  padding: 15px;
  border: none;
  border-radius: 10px;
  font-size: 1.1em;
  cursor: pointer;
  transition: all 0.3s;
}

.reject-btn {
  background: #F5F5F5;
  color: #666;
}

.reject-btn:hover {
  background: #FFE5E5;
  color: #FF6B6B;
}

.approve-btn {
  background: linear-gradient(135deg, #a8e063 0%, #56ab2f 100%);
  color: white;
}

.approve-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(86, 171, 47, 0.3);
}

.approve-btn:disabled, .reject-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
