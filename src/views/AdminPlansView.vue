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
  weekdays: [1, 2, 3, 4, 5, 6, 7] // 默认每天
})

const weekdays = [
  { value: 1, label: '周一' },
  { value: 2, label: '周二' },
  { value: 3, label: '周三' },
  { value: 4, label: '周四' },
  { value: 5, label: '周五' },
  { value: 6, label: '周六' },
  { value: 7, label: '周日' }
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
    weekdays: [1, 2, 3, 4, 5, 6, 7]
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
    weekdays: plan.weekdays || [1, 2, 3, 4, 5, 6, 7]
  }
  showModal.value = true
}

function toggleWeekday(value) {
  const index = formData.value.weekdays.indexOf(value)
  if (index > -1) {
    formData.value.weekdays.splice(index, 1)
  } else {
    formData.value.weekdays.push(value)
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
      const { error } = await supabase
        .from('xcm_study_plans')
        .insert(formData.value)

      if (error) throw error
    }

    showModal.value = false
    await fetchPlans()
  } catch (error) {
    console.error('保存失败:', error)
    alert('保存失败，请重试')
  }
}

async function deletePlan(id) {
  if (!confirm('确定要删除这个学习计划吗？')) return

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
            <span>⏱️ {{ plan.duration_minutes }}分钟</span>
            <span>⭐ {{ plan.stars_reward }}</span>
            <span v-if="plan.require_photo">📸 必填</span>
            <span v-if="plan.require_audio">🎤 必填</span>
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
            <label>图标（emoji）</label>
            <input v-model="formData.icon" type="text" />
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
                :class="{ active: formData.weekdays.includes(day.value) }"
                @click="toggleWeekday(day.value)"
              >
                {{ day.label }}
              </button>
            </div>
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
  gap: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.plan-icon {
  font-size: 2.5em;
}

.plan-info {
  flex: 1;
}

.plan-name {
  font-size: 1.2em;
  font-weight: 600;
  color: #333;
  margin-bottom: 5px;
}

.plan-details {
  display: flex;
  gap: 15px;
  font-size: 0.9em;
  color: #666;
}

.plan-actions {
  display: flex;
  gap: 10px;
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
