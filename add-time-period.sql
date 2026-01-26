-- 添加时间段字段到学习计划表
ALTER TABLE xcm_study_plans ADD COLUMN IF NOT EXISTS time_period TEXT DEFAULT 'any';

-- 更新现有数据，默认设置为 'any'（任意时间）
UPDATE xcm_study_plans SET time_period = 'any' WHERE time_period IS NULL;

-- 时间段的值可以是: 'morning' (上午), 'afternoon' (下午), 'evening' (晚上), 'any' (任意时间)

-- 示例：如果需要设置特定计划的时间段，可以运行：
-- UPDATE xcm_study_plans SET time_period = 'morning' WHERE name = '晨读';
-- UPDATE xcm_study_plans SET time_period = 'afternoon' WHERE name = '钢琴练习';
-- UPDATE xcm_study_plans SET time_period = 'evening' WHERE name = '睡前阅读';
