import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// 检查环境变量是否配置
if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Supabase 环境变量未配置！')
  console.error('请在 Vercel 项目设置中添加以下环境变量：')
  console.error('- VITE_SUPABASE_URL')
  console.error('- VITE_SUPABASE_ANON_KEY')
  console.error('\n或在本地开发时创建 .env.local 文件并添加上述变量。')
}

export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder-key'
)
