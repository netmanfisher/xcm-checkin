<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()

const plans = ref([])
const loading = ref(false)
const showModal = ref(false)
const editingPlan = ref(null)
const formData = ref({
  name: '',
  icon: '📝',
  description: '',
  duration_minutes: 30,
  stars_reward: 3,
  require_photo: false,
  require_audio: false,
  status: 'active',
  sort_order: 1,
  weekdays: [1, 2, 3, 4, 5, 6, 7], // 默认每天
  time_period: 'any' // 默认任意时间
})

const weekdays = [
  { value: 0, label: '🎯 当日当次' },
  { value: 1, label: '周一' },
  { value: 2, label: '周二' },
  { value: 3, label: '周三' },
  { value: 4, label: '周四' },
  { value: 5, label: '周五' },
  { value: 6, label: '周六' },
  { value: 7, label: '周日' }
]

const timePeriods = [
  { value: 'morning', label: '🌅 上午' },
  { value: 'afternoon', label: '☀️ 下午' },
  { value: 'evening', label: '🌙 晚上' },
  { value: 'any', label: '📋 全天' }
]

// 常用任务图标
const taskIcons = [
  // 学习类
  { emoji: '📚', label: '家庭作业' },
  { emoji: '📝', label: '作业本' },
  { emoji: '✏️', label: '铅笔' },
  { emoji: '🖊️', label: '笔记本' },
  { emoji: '📐', label: '数学' },
  { emoji: '🔢', label: '计算' },
  { emoji: '➗', label: '乘法' },
  { emoji: '➕', label: '加法' },
  { emoji: '📖', label: '阅读' },
  { emoji: '📕', label: '书本' },
  { emoji: '📰', label: '报纸' },
  { emoji: '🔤', label: '字典' },
  { emoji: '💡', label: '思考' },

  // 艺术类
  { emoji: '🎹', label: '钢琴' },
  { emoji: '🎸', label: '吉他' },
  { emoji: '🎻', label: '小提琴' },
  { emoji: '🎺', label: '小号' },
  { emoji: '🎼', label: '音乐' },
  { emoji: '🎤', label: '唱歌' },
  { emoji: '🎧', label: '耳机' },
  { emoji: '🎨', label: '绘画' },
  { emoji: '🖌️', label: '蜡笔' },
  { emoji: '✏️', label: '画笔' },
  { emoji: '🖍️', label: '彩笔' },
  { emoji: '🎭', label: '表演' },
  { emoji: '🎪', label: '马戏' },
  { emoji: '🎢', label: '游乐园' },

  // 运动类
  { emoji: '⚽', label: '足球' },
  { emoji: '🏀', label: '篮球' },
  { emoji: '🏈', label: '棒球' },
  { emoji: '🎾', label: '网球' },
  { emoji: '🏓', label: '乒乓球' },
  { emoji: '🏸', label: '台球' },
  { emoji: '🏊', label: '游泳' },
  { emoji: '🚴', label: '骑车' },
  { emoji: '🏃', label: '跑步' },
  { emoji: '🤸', label: '体操' },
  { emoji: '🧘', label: '瑜伽' },
  { emoji: '🏄', label: '滑雪' },
  { emoji: '⛷', label: '滑板' },

  // 语言类
  { emoji: '🗣️', label: '英语' },
  { emoji: '🇬🇧', label: '英式' },
  { emoji: '🇺🇸', label: '美式' },
  { emoji: '🇨🇳', label: '中文' },
  { emoji: '📖', label: '朗读' },
  { emoji: '🗣️', label: '演讲' },

  // 其他
  { emoji: '🧩', label: '拼图' },
  { emoji: '🧮', label: '算盘' },
  { emoji: '🎲', label: '积木' },
  { emoji: '♟', label: '棋类' },
  { emoji: '🎯', label: '射箭' },
  { emoji: '💻', label: '电脑' },
  { emoji: '📱', label: '手机' },
  { emoji: '📺', label: '电视' },
  { emoji: '🎬', label: '电影' },
  { emoji: '🎞', label: '视频' },
  { emoji: '🎵', label: '音乐' },
  { emoji: '🎶', label: '艺术' },
  { emoji: '🧒', label: '照顾' },
  { emoji: '🧹', label: '家务' },
  { emoji: '🍳', label: '烹饪' },
  { emoji: '🥗', label: '饮食' }
]

onMounted(async () => {
  await fetchPlans()
})

async function fetchPlans() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('xcm_study_plans')
      .select('*')
      .order('sort_order')

    if (error) throw error
    plans.value = data || []
  } catch (error) {
    console.error('获取计划列表失败:', error)
    alert('获取计划列表失败')
  } finally {
    loading.value = false
  }
}

function openAddModal() {
  editingPlan.value = null
  formData.value = {
    name: '',
    icon: '📝',
    description: '',
    duration_minutes: 30,
    stars_reward: 3,
    require_photo: false,
    require_audio: false,
    status: 'active',
    sort_order: plans.value.length + 1,
    weekdays: [1, 2, 3, 4, 5, 6, 7],
    time_period: 'any'
  }
  showModal.value = true
}

function openEditModal(plan) {
  editingPlan.value = plan
  formData.value = {
    name: plan.name,
    icon: plan.icon,
    description: plan.description,
    duration_minutes: plan.duration_minutes,
    stars_reward: plan.stars_reward,
    require_photo: plan.require_photo,
    require_audio: plan.require_audio,
    status: plan.status,
    sort_order: plan.sort_order,
    weekdays: plan.weekdays || [1, 2, 3, 4, 5, 6, 7],
    time_period: plan.time_period || 'any'
  }
  showModal.value = true
}

function toggleWeekday(value) {
  const index = formData.value.weekdays.indexOf(value)

  // 特殊处理：如果选择"当日当次"(0)，清除其他所有选项
  if (value === 0) {
    if (index > -1) {
      // 取消选择"当日当次"
      formData.value.weekdays.splice(index, 1)
    } else {
      // 选择"当日当次"，清除其他所有选项
      formData.value.weekdays = [0]
    }
  } else {
    // 选择普通星期几，清除"当日当次"选项
    const zeroIndex = formData.value.weekdays.indexOf(0)
    if (zeroIndex > -1) {
      formData.value.weekdays.splice(zeroIndex, 1)
    }

    // 正常的切换逻辑
    const index = formData.value.weekdays.indexOf(value)
    if (index > -1) {
      formData.value.weekdays.splice(index, 1)
    } else {
      formData.value.weekdays.push(value)
    }
  }
}

async function savePlan() {
  try {
    if (editingPlan.value) {
      const { error } = await supabase
        .from('xcm_study_plans')
        .update(formData.value)
        .eq('id', editingPlan.value.id)

      if (error) throw error
    } else {
      // 如果是"当日当次"任务，设置 first_show_date 为今天
      const planData = { ...formData.value }
      if (planData.weekdays.includes(0)) {
        planData.first_show_date = new Date().toISOString().split('T')[0]
      }

      const { error } = await supabase
        .from('xcm_study_plans')
        .insert(planData)

      if (error) throw error
    }

    showModal.value = false
    await fetchPlans()
  } catch (error) {
    console.error('保存失败:', error)
    console.error('错误详情:', error.message)
    console.error('错误代码:', error.code)
    alert(`保存失败: ${error.message || '未知错误'}\n请检查浏览器控制台获取详细信息`)
  }
}

async function deletePlan(id) {
  try {
    const { error } = await supabase
      .from('xcm_study_plans')
      .delete()
      .eq('id', id)

    if (error) throw error
    await fetchPlans()
  } catch (error) {
    console.error('删除失败:', error)
    alert('删除失败，请重试')
  }
}

function goBack() {
  router.push('/admin')
}

function getTimePeriodLabel(period) {
  const labels = {
    morning: '🌅 上午',
    afternoon: '☀️ 下午',
    evening: '🌙 晚上',
    any: '📋 全天'
  }
  return labels[period] || '📋 全天'
}

function getWeekdaysLabel(weekdayArray) {
  if (!weekdayArray || weekdayArray.length === 7) return '每天'

  const labels = {
    1: '一', 2: '二', 3: '三', 4: '四', 5: '五', 6: '六', 7: '日'
  }

  const sortedDays = weekdayArray.sort((a, b) => a - b)
  return sortedDays.map(day => labels[day]).join('、')
}
</script>

<template>
  <div class="admin-plans">
    <div class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h2>📝 计划管理</h2>
      <button class="add-btn" @click="openAddModal">+ 添加计划</button>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <div v-else class="plans-list">
      <div v-for="plan in plans" :key="plan.id" class="plan-card">
        <div class="plan-icon">{{ plan.icon }}</div>
        <div class="plan-info">
          <div class="plan-name">{{ plan.name }}</div>
          <div class="plan-details">
            <span class="detail-tag">
              {{ getTimePeriodLabel(plan.time_period) }}
            </span>
            <span class="detail-tag">⏱️ {{ plan.duration_minutes }}分钟</span>
            <span class="detail-tag">⭐ {{ plan.stars_reward }}</span>
            <span v-if="plan.require_photo" class="detail-tag">📸</span>
            <span v-if="plan.require_audio" class="detail-tag">🎤</span>
            <span v-if="plan.status === 'inactive'" class="detail-tag inactive">已禁用</span>
          </div>
          <div class="weekdays-info" v-if="plan.weekdays && plan.weekdays.length < 7">
            <span class="weekdays-label">周期：</span>
            <span class="weekdays-list">{{ getWeekdaysLabel(plan.weekdays) }}</span>
          </div>
        </div>

        <div class="plan-actions">
          <button class="edit-btn" @click="openEditModal(plan)">编辑</button>
          <button class="delete-btn" @click="deletePlan(plan.id)">删除</button>
        </div>
      </div>
    </div>

    <!-- 添加/编辑弹窗 -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h3>{{ editingPlan ? '编辑计划' : '添加计划' }}</h3>
        <form @submit.prevent="savePlan" class="form">
          <div class="form-group">
            <label>计划名称</label>
            <input v-model="formData.name" type="text" required />
          </div>

          <div class="form-group">
            <label>选择图标</label>
            <div class="icon-selector">
              <div
                v-for="icon in taskIcons"
                :key="icon.emoji"
                class="icon-option"
                :class="{ selected: formData.icon === icon.emoji }"
                @click="formData.icon = icon.emoji"
                :title="icon.label"
              >
                {{ icon.emoji }}
              </div>
            </div>
          </div>

          <div class="form-group">
            <label>描述</label>
            <input v-model="formData.description" type="text" />
          </div>

          <div class="form-group">
            <label>时长（分钟）</label>
            <input v-model="formData.duration_minutes" type="number" min="1" required />
          </div>

          <div class="form-group">
            <label>奖励星星</label>
            <input v-model="formData.stars_reward" type="number" min="1" required />
          </div>

          <div class="form-group">
            <label>排序</label>
            <input v-model="formData.sort_order" type="number" min="1" required />
          </div>

          <div class="form-group">
            <label>时间段</label>
            <select v-model="formData.time_period">
              <option v-for="period in timePeriods" :key="period.value" :value="period.value">
                {{ period.label }}
              </option>
            </select>
          </div>

          <div class="form-group checkbox">
            <label>
              <input type="checkbox" v-model="formData.require_photo" />
              需要上传照片
            </label>
          </div>

          <div class="form-group checkbox">
            <label>
              <input type="checkbox" v-model="formData.require_audio" />
              需要录音
            </label>
          </div>

          <div class="form-group">
            <label>状态</label>
            <select v-model="formData.status">
              <option value="active">启用</option>
              <option value="inactive">禁用</option>
            </select>
          </div>

          <div class="form-group">
            <label>周期（选择需要打卡的日期）</label>
            <div class="weekdays-selector">
              <button
                v-for="day in weekdays"
                :key="day.value"
                type="button"
                class="weekday-btn"
                :class="{ active: formData.weekdays.includes(day.value), 'special-day': day.value === 0 }"
                @click="toggleWeekday(day.value)"
              >
                {{ day.label }}
              </button>
            </div>
            <p class="weekday-hint">
              <span v-if="formData.weekdays.includes(0)">⚠️ "当日当次"表示该任务今天只能打卡一次，完成后即不再显示</span>
              <span v-else>💡 选择任务在每周几打卡</span>
            </p>
          </div>

          <div class="form-actions">
            <button type="button" class="cancel-btn" @click="showModal = false">取消</button>
            <button type="submit" class="submit-btn">保存</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin-plans {
  min-height: 100vh;
  background: #F5F5F5;
  padding: 20px;
}

.header {
  background: white;
  border-radius: 20px;
  padding: 20px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  gap: 15px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.back-btn {
  background: none;
  border: none;
  font-size: 1.2em;
  cursor: pointer;
  padding: 5px 10px;
}

.header h2 {
  flex: 1;
  font-size: 1.5em;
  color: #333;
}

.add-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 600;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #666;
}

.plans-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.plan-card {
  background: white;
  border-radius: 15px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 15px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.plan-icon {
  font-size: 2em;
  flex-shrink: 0;
}

.plan-info {
  flex: 1;
  min-width: 0;
}

.plan-name {
  font-size: 1.1em;
  font-weight: 600;
  color: #333;
  margin-bottom: 8px;
}

.plan-details {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  font-size: 0.85em;
  margin-bottom: 5px;
}

.detail-tag {
  background: #F0F0F0;
  padding: 3px 8px;
  border-radius: 6px;
  color: #666;
  white-space: nowrap;
}

.detail-tag.inactive {
  background: #FFF1F0;
  color: #FF4D4F;
}

.weekdays-info {
  font-size: 0.85em;
  color: #999;
  margin-top: 5px;
}

.weekdays-label {
  font-weight: 500;
}

.weekdays-list {
  color: #666;
}

.plan-actions {
  display: flex;
  gap: 10px;
  flex-shrink: 0;
}

.edit-btn, .delete-btn {
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9em;
}

.edit-btn {
  background: #E6F7FF;
  color: #1890FF;
}

.delete-btn {
  background: #FFF1F0;
  color: #FF4D4F;
}

/* 弹窗样式 */
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

.modal {
  background: white;
  border-radius: 20px;
  padding: 30px;
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal h3 {
  font-size: 1.5em;
  color: #333;
  margin-bottom: 20px;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.form-group.checkbox {
  flex-direction: row;
  align-items: center;
}

.form-group.checkbox label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
}

.form-group label {
  font-size: 0.9em;
  color: #666;
  font-weight: 500;
}

.form-group input,
.form-group select {
  padding: 10px;
  border: 2px solid #E5E5EA;
  border-radius: 8px;
  font-size: 1em;
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: #667eea;
}

.icon-selector {
  display: grid;
  grid-template-columns: repeat(10, 1fr);
  gap: 8px;
  max-height: 200px;
  overflow-y: auto;
  padding: 10px;
  background: #F5F5F5;
  border-radius: 8px;
  border: 2px solid #E5E5EA;
}

.icon-option {
  font-size: 2em;
  padding: 8px;
  text-align: center;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.2s;
  background: white;
  border: 2px solid transparent;
}

.icon-option:hover {
  background: #E6F7FF;
  transform: scale(1.1);
}

.icon-option.selected {
  background: #E6F7FF;
  border-color: #1890FF;
  transform: scale(1.15);
}

.weekdays-selector {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.weekday-btn {
  padding: 8px 12px;
  border: 2px solid #E5E5EA;
  background: white;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9em;
  transition: all 0.3s;
}

.weekday-btn:hover {
  border-color: #667eea;
}

.weekday-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: #667eea;
}

.weekday-btn.special-day {
  font-weight: 600;
  color: #FF6B6B;
}

.weekday-btn.special-day.active {
  background: linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%);
  border-color: #FF6B6B;
}

.weekday-hint {
  margin-top: 8px;
  font-size: 0.8em;
  color: #999;
}

.form-actions {
  display: flex;
  gap: 10px;
  margin-top: 10px;
}

.cancel-btn, .submit-btn {
  flex: 1;
  padding: 12px;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
}

.cancel-btn {
  background: #F5F5F5;
  color: #666;
}

.submit-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}
</style>
