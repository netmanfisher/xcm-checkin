-- 查看 xcm_stars_history 表的检查约束
-- SELECT * FROM pg_constraint WHERE conname = 'xcm_stars_history_type_check';

-- 问题：type 字段可能有检查约束，只允许特定值
-- 解决方案：删除旧的检查约束，或者更新插入的值以符合约束

-- 方案1：删除检查约束（如果不需要限制）
-- ALTER TABLE xcm_stars_history DROP CONSTRAINT IF EXISTS xcm_stars_history_type_check;

-- 方案2：修改插入的值，使用符合约束的值
-- 先查看现有的 type 值：
SELECT DISTINCT type FROM xcm_stars_history;

-- 根据现有数据，type 字段可能使用的值是：
-- 'earned' (获得) 或 'spent' (消费) 或类似的值

-- 如果约束限制了 type 的值，我们需要确保使用的值在允许范围内
