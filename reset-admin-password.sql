-- 重置管理员密码为 admin123（明文）
UPDATE xcm_admins
SET password_hash = 'admin123'
WHERE username = 'admin';

-- 确认修改
SELECT username, password_hash FROM xcm_admins WHERE username = 'admin';
