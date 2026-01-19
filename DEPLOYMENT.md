# 环境变量配置指南

## Vercel 部署配置

### 1. 在 Supabase 获取 API 密钥

1. 登录 [Supabase](https://supabase.com)
2. 选择或创建你的项目
3. 进入 **Settings** → **API**
4. 复制以下信息：
   - **Project URL**（类似：`https://xxxxx.supabase.co`）
   - **anon public** key（一串很长的密钥）

### 2. 在 Vercel 配置环境变量

1. 打开你的 Vercel 项目
2. 进入 **Settings** → **Environment Variables**
3. 添加以下两个环境变量：

| 名称 | 值 | 环境 |
|------|-----|------|
| `VITE_SUPABASE_URL` | 你的 Supabase Project URL | Production, Preview, Development |
| `VITE_SUPABASE_ANON_KEY` | 你的 Supabase anon key | Production, Preview, Development |

### 3. 重要提示

⚠️ **所有三个环境（Production, Preview, Development）都要配置！**

⚠️ **环境变量名称必须以 `VITE_` 开头，否则 Vue 无法访问！**

### 4. 配置后重新部署

添加环境变量后：
1. 进入 **Deployments** 标签
2. 点击最新部署右侧的 **...** 菜单
3. 选择 **Redeploy**
4. 等待部署完成

### 5. 本地开发配置

在本地开发时，创建 `.env.local` 文件：

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

## 检查配置是否成功

部署后，打开浏览器控制台（F12），查看是否有错误信息：

- 如果看到 `❌ Supabase 环境变量未配置！`，说明环境变量未正确配置
- 如果看到其他数据库错误，说明需要创建数据库表

## 数据库设置

环境变量配置好后，还需要在 Supabase 执行以下操作：

### 1. 创建数据库表

在 Supabase 的 **SQL Editor** 中执行数据库建表脚本（参考 `database-schema.sql`）

### 2. 插入测试数据（可选）

执行 `test-data.sql` 插入测试数据

### 3. 创建 Storage Buckets

在 Supabase 的 **Storage** 页面创建两个 buckets：
- `xcm_checkin_photos` - 存储打卡照片
- `xcm_checkin_audio` - 存储打卡音频

确保两个 buckets 都是 **Public** 状态

## 故障排除

### 页面空白
1. 打开浏览器控制台查看错误信息
2. 检查环境变量是否正确配置
3. 确认已重新部署

### 数据库连接错误
1. 检查 Supabase 项目是否正常
2. 确认数据库表已创建
3. 检查 RLS 策略是否正确

### 图片/音频上传失败
1. 确认 Storage buckets 已创建
2. 确认 buckets 是 Public 状态
3. 检查 Storage 权限设置
