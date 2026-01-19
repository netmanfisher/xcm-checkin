-- 为 xcm_study_plans 表添加 weekdays 字段（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'xcm_study_plans'
    AND column_name = 'weekdays'
  ) THEN
    ALTER TABLE xcm_study_plans ADD COLUMN weekdays INTEGER[];
  END IF;
END $$;

-- 为 xcm_wishes 表添加 icon 字段（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'xcm_wishes'
    AND column_name = 'icon'
  ) THEN
    ALTER TABLE xcm_wishes ADD COLUMN icon TEXT DEFAULT '🎁';
  END IF;
END $$;

-- 更新现有数据（使用 ARRAY[...] 语法）
UPDATE xcm_study_plans SET weekdays = ARRAY[1, 2, 3, 4, 5, 6, 7] WHERE weekdays IS NULL;
UPDATE xcm_wishes SET icon = '🎁' WHERE icon IS NULL OR icon = '';

-- 查询确认
SELECT 'study_plans weekdays' as table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'xcm_study_plans' AND column_name = 'weekdays'
UNION ALL
SELECT 'wishes icon', column_name, data_type
FROM information_schema.columns
WHERE table_name = 'xcm_wishes' AND column_name = 'icon';
