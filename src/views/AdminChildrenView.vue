<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../supabase'

const router = useRouter()

const children = ref([])
const currentView = ref('children') // children, wishes, plans, reviews
const loading = ref(false)
const showModal = ref(false)
const editingChild = ref(null)
const formData = ref({
  name: '',
  avatar_url: '👧',
  theme: 'princess',
  status: 'active',
  stars: 0
})

onMounted(async () => {
  await fetchChildren()
})

async function fetchChildren() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('xcm_children')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    children.value = data || []
  } catch (error) {
    console.error('获取孩子列表失败:', error)
    alert('获取孩子列表失败')
  } finally {
    loading.value = false
  }
}

function openAddModal() {
  editingChild.value = null
  formData.value = {
    name: '',
    avatar_url: '👧',
    theme: 'princess',
    status: 'active',
    stars: 0
  }
  showModal.value = true
}

function openEditModal(child) {
  editingChild.value = child
  formData.value = {
    name: child.name,
    avatar_url: child.avatar_url || '👧',
    theme: child.theme || 'princess',
    status: child.status || 'active',
    stars: child.stars || 0
  }
  showModal.value = true
}

async function saveChild() {
  try {
    if (editingChild.value) {
      // 更新
      const { error } = await supabase
        .from('xcm_children')
        .update(formData.value)
        .eq('id', editingChild.value.id)

      if (error) throw error
    } else {
      // 新增
      const { error } = await supabase
        .from('xcm_children')
        .insert(formData.value)

      if (error) throw error
    }

    showModal.value = false
    await fetchChildren()
  } catch (error) {
    console.error('保存失败:', error)
    alert('保存失败，请重试')
  }
}

async function deleteChild(id) {
  if (!confirm('确定要删除这个孩子账号吗？')) return

  try {
    const { error } = await supabase
      .from('xcm_children')
      .delete()
      .eq('id', id)

    if (error) throw error
    await fetchChildren()
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
  <div class="admin-children">
    <div class="header">
      <button class="back-btn" @click="goBack">← 返回</button>
      <h2>👶 孩子管理</h2>
      <button class="add-btn" @click="openAddModal">+ 添加孩子</button>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <div v-else class="children-list">
      <div v-for="child in children" :key="child.id" class="child-card">
        <div class="child-avatar">{{ child.avatar_url || '👤' }}</div>
        <div class="child-info">
          <div class="child-name">{{ child.name }}</div>
          <div class="child-details">
            <span>主题: {{ child.theme }}</span>
            <span>星星: ⭐{{ child.stars }}</span>
            <span :class="`status-${child.status}`">
              {{ child.status === 'active' ? '启用' : '禁用' }}
            </span>
          </div>
        </div>
        <div class="child-actions">
          <button class="edit-btn" @click="openEditModal(child)">编辑</button>
          <button class="delete-btn" @click="deleteChild(child.id)">删除</button>
        </div>
      </div>
    </div>

    <!-- 添加/编辑弹窗 -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h3>{{ editingChild ? '编辑孩子' : '添加孩子' }}</h3>
        <form @submit.prevent="saveChild" class="form">
          <div class="form-group">
            <label>名字</label>
            <input v-model="formData.name" type="text" required />
          </div>

          <div class="form-group">
            <label>头像（emoji）</label>
            <input v-model="formData.avatar_url" type="text" />
          </div>

          <div class="form-group">
            <label>主题</label>
            <select v-model="formData.theme">
              <option value="princess">公主（粉色）</option>
              <option value="prince">王子（蓝色）</option>
            </select>
          </div>

          <div class="form-group">
            <label>初始星星</label>
            <input v-model="formData.stars" type="number" min="0" />
          </div>

          <div class="form-group">
            <label>状态</label>
            <select v-model="formData.status">
              <option value="active">启用</option>
              <option value="inactive">禁用</option>
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
.admin-children {
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

.children-list {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.child-card {
  background: white;
  border-radius: 15px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.child-avatar {
  font-size: 3em;
}

.child-info {
  flex: 1;
}

.child-name {
  font-size: 1.2em;
  font-weight: 600;
  color: #333;
  margin-bottom: 5px;
}

.child-details {
  display: flex;
  gap: 15px;
  font-size: 0.9em;
  color: #666;
}

.status-active {
  color: #52c41a;
}

.status-inactive {
  color: #999;
}

.child-actions {
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
