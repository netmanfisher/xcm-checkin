<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()

const wishes = ref([])
const children = ref([])
const loading = ref(false)
const showModal = ref(false)
const editingWish = ref(null)
const formData = ref({
  child_id: '',
  name: '',
  description: '',
  stars_cost: 10,
  status: 'available'
})

onMounted(async () => {
  await fetchChildren()
  await fetchWishes()
})

async function fetchChildren() {
  try {
    const { data, error } = await supabase
      .from('xcm_children')
      .select('id, name')
      .eq('status', 'active')

    if (error) throw error
    children.value = data || []
  } catch (error) {
    console.error('获取孩子列表失败:', error)
  }
}

async function fetchWishes() {
  try {
    loading.value = true

    // 获取所有愿望
    const { data: wishesData, error: wishesError } = await supabase
      .from('xcm_wishes')
      .select('*')
      .order('created_at', { ascending: false })

    if (wishesError) throw wishesError

    // 获取所有孩子
    const { data: childrenData } = await supabase
      .from('xcm_children')
      .select('id, name')

    // 组合数据
    wishes.value = (wishesData || []).map(wish => ({
      ...wish,
      xcm_children: childrenData?.find(c => c.id === wish.child_id) || { name: '' }
    }))
  } catch (error) {
    console.error('获取愿望列表失败:', error)
    alert('获取愿望列表失败')
  } finally {
    loading.value = false
  }
}

function openAddModal() {
  editingWish.value = null
  formData.value = {
    child_id: children.value[0]?.id || '',
    name: '',
    icon: '🎁',
    description: '',
    stars_cost: 10,
    status: 'available'
  }
  showModal.value = true
}

function openEditModal(wish) {
  editingWish.value = wish
  formData.value = {
    child_id: wish.child_id,
    name: wish.name,
    icon: wish.icon || '🎁',
    description: wish.description,
    stars_cost: wish.stars_cost,
    status: wish.status
  }
  showModal.value = true
}

async function saveWish() {
  try {
    if (editingWish.value) {
      const { error } = await supabase
        .from('xcm_wishes')
        .update(formData.value)
        .eq('id', editingWish.value.id)

      if (error) throw error
    } else {
      const insertData = {
        child_id: formData.value.child_id,
        name: formData.value.name,
        icon: formData.value.icon,
        description: formData.value.description,
        stars_cost: formData.value.stars_cost,
        status: formData.value.status,
        created_at: new Date().toISOString()
      }

      const { error } = await supabase
        .from('xcm_wishes')
        .insert(insertData)

      if (error) throw error
    }

    showModal.value = false
    await fetchWishes()
  } catch (error) {
    console.error('保存失败:', error)
    alert(`保存失败: ${error.message || '未知错误'}`)
  }
}

async function deleteWish(id) {
  if (!confirm('确定要删除这个愿望吗？')) return

  try {
    const { error } = await supabase
      .from('xcm_wishes')
      .delete()
      .eq('id', id)

    if (error) throw error
    await fetchWishes()
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
  <div class="admin-wishes">
    <div class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h2>🎁 愿望管理</h2>
      <button class="add-btn" @click="openAddModal">+ 添加愿望</button>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <div v-else class="wishes-list">
      <div v-for="wish in wishes" :key="wish.id" class="wish-card">
        <div class="wish-icon">{{ wish.icon || '🎁' }}</div>
        <div class="wish-info">
          <div class="wish-name">{{ wish.name }}</div>
          <div class="wish-details">
            <span>{{ wish.xcm_children?.name }}</span>
            <span>⭐ {{ wish.stars_cost }}</span>
            <span :class="`status-${wish.status}`">
              {{ wish.status === 'available' ? '可兑换' : wish.status === 'redeemed' ? '已兑换' : '已删除' }}
            </span>
          </div>
        </div>
        <div class="wish-actions">
          <button class="edit-btn" @click="openEditModal(wish)">编辑</button>
          <button class="delete-btn" @click="deleteWish(wish.id)">删除</button>
        </div>
      </div>
    </div>

    <!-- 添加/编辑弹窗 -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h3>{{ editingWish ? '编辑愿望' : '添加愿望' }}</h3>
        <form @submit.prevent="saveWish" class="form">
          <div class="form-group">
            <label>孩子</label>
            <select v-model="formData.child_id" required>
              <option value="">请选择</option>
              <option v-for="child in children" :key="child.id" :value="child.id">
                {{ child.name }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label>愿望名称</label>
            <input v-model="formData.name" type="text" required />
          </div>

          <div class="form-group">
            <label>图标（emoji）</label>
            <input v-model="formData.icon" type="text" placeholder="🎁" />
          </div>

          <div class="form-group">
            <label>描述</label>
            <input v-model="formData.description" type="text" />
          </div>

          <div class="form-group">
            <label>需要星星</label>
            <input v-model="formData.stars_cost" type="number" min="1" required />
          </div>

          <div class="form-group">
            <label>状态</label>
            <select v-model="formData.status">
              <option value="available">可兑换</option>
              <option value="redeemed">已兑换</option>
              <option value="deleted">已删除</option>
            </select>
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
.admin-wishes {
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

.wishes-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.wish-card {
  background: white;
  border-radius: 15px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.wish-icon {
  font-size: 2.5em;
}

.wish-info {
  flex: 1;
}

.wish-name {
  font-size: 1.2em;
  font-weight: 600;
  color: #333;
  margin-bottom: 5px;
}

.wish-details {
  display: flex;
  gap: 15px;
  font-size: 0.9em;
  color: #666;
}

.status-available {
  color: #52c41a;
}

.status-redeemed {
  color: #1890FF;
}

.status-deleted {
  color: #999;
}

.wish-actions {
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
