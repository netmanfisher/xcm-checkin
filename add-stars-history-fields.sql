-- 添加缺失的字段到星星历史表
ALTER TABLE xcm_stars_history ADD COLUMN IF NOT EXISTS source TEXT;
ALTER TABLE xcm_stars_history ADD COLUMN IF NOT EXISTS transaction_time TIMESTAMPTZ;

-- 更新现有数据，默认设置为 'checkin' 和当前时间
UPDATE xcm_stars_history
SET source = 'checkin'
WHERE source IS NULL;

UPDATE xcm_stars_history
SET transaction_time = created_at
WHERE transaction_time IS NULL;

-- source 字段的值可以是: 'checkin' (打卡), 'redeem' (兑换), 'manual' (手动调整) 等
-- transaction_time 是交易时间戳
