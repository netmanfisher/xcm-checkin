-- 添加 first_show_date 字段到 xcm_study_plans 表
-- 用于记录"当日当次"任务首次显示的日期
ALTER TABLE xcm_study_plans ADD COLUMN IF NOT EXISTS first_show_date DATE;

-- 对于现有的"当日当次"任务，设置 first_show_date 为创建日期
UPDATE xcm_study_plans
SET first_show_date = created_at::DATE
WHERE first_show_date IS NULL
  AND 0 = ANY(weekdays);
