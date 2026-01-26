<script setup>
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '../supabase'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

const plan = ref(null)
const loading = ref(false)
const submitting = ref(false)
const photoFile = ref(null)
const audioFile = ref(null)
const photoPreview = ref(null)
const audioRecording = ref(false)
const audioBlob = ref(null)
const mediaRecorder = ref(null)
const audioChunks = ref([])
const note = ref('')

onMounted(async () => {
  await fetchPlan()
})

async function fetchPlan() {
  try {
    loading.value = true
    const planId = route.params.planId
    const { data, error } = await supabase
      .from('xcm_study_plans')
      .select('*')
      .eq('id', planId)
      .single()

    if (error) throw error
    plan.value = data
  } catch (error) {
    console.error('获取学习计划失败:', error)
    alert('获取学习计划失败')
    router.back()
  } finally {
    loading.value = false
  }
}

function handlePhotoChange(event) {
  const file = event.target.files[0]
  if (file) {
    photoFile.value = file
    const reader = new FileReader()
    reader.onload = (e) => {
      photoPreview.value = e.target.result
    }
    reader.readAsDataURL(file)
  }
}

async function startRecording() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    mediaRecorder.value = new MediaRecorder(stream)
    audioChunks.value = []

    mediaRecorder.value.ondataavailable = (event) => {
      audioChunks.value.push(event.data)
    }

    mediaRecorder.value.onstop = () => {
      audioBlob.value = new Blob(audioChunks.value, { type: 'audio/webm' })
      const audioUrl = URL.createObjectURL(audioBlob.value)
      audioFile.value = new File([audioBlob.value], 'recording.webm', { type: 'audio/webm' })
    }

    mediaRecorder.value.start()
    audioRecording.value = true
  } catch (error) {
    console.error('录音失败:', error)
    alert('无法访问麦克风')
  }
}

function stopRecording() {
  if (mediaRecorder.value && mediaRecorder.value.state !== 'inactive') {
    mediaRecorder.value.stop()
    audioRecording.value = false
  }
}

async function uploadPhoto() {
  if (!photoFile.value) return null

  const fileName = `checkin_${Date.now()}_${photoFile.value.name}`
  const filePath = `${authStore.currentChild.id}/${fileName}`

  const { data, error } = await supabase.storage
    .from('xcm_checkin_photos')
    .upload(filePath, photoFile.value)

  if (error) {
    console.error('上传照片失败:', error)
    return null
  }

  const { data: { publicUrl } } = supabase.storage
    .from('xcm_checkin_photos')
    .getPublicUrl(filePath)

  return publicUrl
}

async function uploadAudio() {
  if (!audioFile.value) return null

  const fileName = `audio_${Date.now()}_${audioFile.value.name}`
  const filePath = `${authStore.currentChild.id}/${fileName}`

  const { data, error } = await supabase.storage
    .from('xcm_checkin_audio')
    .upload(filePath, audioFile.value)

  if (error) {
    console.error('上传音频失败:', error)
    return null
  }

  const { data: { publicUrl } } = supabase.storage
    .from('xcm_checkin_audio')
    .getPublicUrl(filePath)

  return publicUrl
}

async function submitCheckIn() {
  // 验证必填项 - 只有在计划要求时才验证
  if (plan.value.require_photo && !photoFile.value) {
    alert('请上传照片')
    return
  }

  if (plan.value.require_audio && !audioFile.value) {
    alert('请录音')
    return
  }

  // 如果既没有照片也没有录音，提示用户
  if (!photoFile.value && !audioFile.value && !note.value) {
    // Continue without confirmation
  }

  try {
    submitting.value = true

    // 上传文件（如果有）
    const photoUrl = photoFile.value ? await uploadPhoto() : null
    const audioUrl = audioFile.value ? await uploadAudio() : null

    // 创建打卡记录
    const { error } = await supabase
      .from('xcm_check_ins')
      .insert({
        child_id: authStore.currentChild.id,
        plan_id: plan.value.id,
        status: 'pending',
        photo_url: photoUrl,
        audio_url: audioUrl,
        note: note.value,
        check_in_time: new Date().toISOString()
      })

    if (error) throw error

    alert('打卡提交成功！等待管理员审核')
    router.push('/home')
  } catch (error) {
    console.error('提交打卡失败:', error)
    alert(`提交打卡失败: ${error.message || '未知错误'}`)
  } finally {
    submitting.value = false
  }
}

function cancel() {
  router.back()
}
</script>

<template>
  <div class="checkin-container" :class="`theme-${authStore.currentChild?.theme || 'princess'}`">
    <div class="header">
      <button class="back-btn" @click="cancel">← 返回</button>
      <h2>{{ plan?.name }}</h2>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <div v-else-if="plan" class="content">
      <div class="plan-info">
        <div class="plan-icon">{{ plan.icon }}</div>
        <div class="plan-details">
          <p class="plan-description">{{ plan.description }}</p>
          <div class="plan-meta">
            <span>⏱️ {{ plan.duration_minutes }}分钟</span>
            <span>⭐ +{{ plan.stars_reward }}</span>
          </div>
        </div>
      </div>

      <div v-if="plan.require_photo" class="form-section">
        <h3>📸 上传照片</h3>
        <p class="required">* 必填</p>
        <div class="photo-upload" @click="$refs.photoInput.click()">
          <div v-if="photoPreview" class="photo-preview">
            <img :src="photoPreview" alt="预览">
            <button class="remove-btn" @click.stop="photoFile = null; photoPreview = null">✕</button>
          </div>
          <div v-else class="upload-placeholder">
            <span class="icon">📷</span>
            <span>点击上传照片</span>
          </div>
        </div>
        <input
          ref="photoInput"
          type="file"
          accept="image/*"
          @change="handlePhotoChange"
          style="display: none"
        >
      </div>

      <div v-if="plan.require_audio" class="form-section">
        <h3>🎤 录音</h3>
        <p class="required">* 必填</p>
        <div class="audio-recorder">
          <button
            v-if="!audioRecording && !audioFile"
            class="record-btn"
            @click="startRecording"
          >
            🎤 开始录音
          </button>
          <button
            v-if="audioRecording"
            class="record-btn recording"
            @click="stopRecording"
          >
            ⏹️ 停止录音
          </button>
          <div v-if="audioFile" class="audio-preview">
            <span>✅ 已录音</span>
            <button class="remove-btn" @click="audioFile = null">重新录音</button>
          </div>
        </div>
      </div>

      <div class="form-section">
        <h3>📝 备注（可选）</h3>
        <textarea
          v-model="note"
          class="note-input"
          placeholder="写点什么吧..."
          rows="3"
        ></textarea>
      </div>

      <div class="actions">
        <button class="cancel-btn" @click="cancel" :disabled="submitting">取消</button>
        <button class="submit-btn" @click="submitCheckIn" :disabled="submitting">
          {{ submitting ? '提交中...' : '提交打卡' }}
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.checkin-container {
  min-height: 100vh;
  padding: 20px;
  padding-bottom: 100px;
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
  font-size: 1.3em;
  color: #333;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #666;
  font-size: 1.2em;
}

.content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.plan-info {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
  display: flex;
  gap: 20px;
}

.plan-icon {
  font-size: 3em;
}

.plan-details {
  flex: 1;
}

.plan-description {
  font-size: 1.1em;
  color: #333;
  margin-bottom: 10px;
}

.plan-meta {
  display: flex;
  gap: 20px;
  color: #666;
}

.form-section {
  background: white;
  border-radius: 20px;
  padding: 20px;
  box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
}

.form-section h3 {
  font-size: 1.2em;
  color: #333;
  margin-bottom: 15px;
}

.required {
  display: inline;
  color: #FF6B6B;
  font-size: 0.9em;
  margin-left: 10px;
}

.optional {
  display: inline;
  color: #999;
  font-size: 0.85em;
  margin-left: 10px;
}


.photo-upload {
  border: 2px dashed #DDD;
  border-radius: 15px;
  padding: 20px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
  min-height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.photo-upload:hover {
  border-color: #667eea;
  background: #F8F8FF;
}

.photo-preview {
  position: relative;
  width: 100%;
  max-width: 400px;
}

.photo-preview img {
  width: 100%;
  border-radius: 10px;
}

.remove-btn {
  position: absolute;
  top: -10px;
  right: -10px;
  background: #FF6B6B;
  color: white;
  border: none;
  border-radius: 50%;
  width: 30px;
  height: 30px;
  cursor: pointer;
  font-size: 1em;
}

.upload-placeholder {
  display: flex;
  flex-direction: column;
  gap: 10px;
  color: #999;
}

.upload-placeholder .icon {
  font-size: 3em;
}

.audio-recorder {
  display: flex;
  gap: 10px;
}

.record-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border: none;
  border-radius: 15px;
  padding: 15px 30px;
  font-size: 1.1em;
  cursor: pointer;
  transition: all 0.3s;
}

.record-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

.record-btn.recording {
  background: linear-gradient(135deg, #FF6B6B 0%, #FF8E53 100%);
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: 0.7;
  }
}

.audio-preview {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 15px 20px;
  background: #F0F0F0;
  border-radius: 15px;
}

.note-input {
  width: 100%;
  border: 2px solid #EEE;
  border-radius: 15px;
  padding: 15px;
  font-size: 1em;
  font-family: inherit;
  resize: vertical;
  transition: border-color 0.3s;
}

.note-input:focus {
  outline: none;
  border-color: #667eea;
}

.actions {
  display: flex;
  gap: 15px;
  margin-top: 20px;
}

.cancel-btn, .submit-btn {
  flex: 1;
  padding: 15px;
  border: none;
  border-radius: 15px;
  font-size: 1.1em;
  cursor: pointer;
  transition: all 0.3s;
}

.cancel-btn {
  background: #F5F5F5;
  color: #666;
}

.cancel-btn:hover {
  background: #E0E0E0;
}

.submit-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.submit-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
}

.submit-btn:disabled, .cancel-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
</style>
