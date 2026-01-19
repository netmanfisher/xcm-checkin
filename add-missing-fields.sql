-- 添加缺失的数据库字段

-- 为 xcm_wishes 表添加 child_id 字段（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'xcm_wishes'
    AND column_name = 'child_id'
  ) THEN
    ALTER TABLE xcm_wishes ADD COLUMN child_id UUID;
  END IF;
END $$;

-- 为 xcm_check_ins 表添加 note 字段（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'xcm_check_ins'
    AND column_name = 'note'
  ) THEN
    ALTER TABLE xcm_check_ins ADD COLUMN note TEXT;
  END IF;
END $$;

-- 为 xcm_check_ins 表添加 photo_url 字段（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'xcm_check_ins'
    AND column_name = 'photo_url'
  ) THEN
    ALTER TABLE xcm_check_ins ADD COLUMN photo_url TEXT;
  END IF;
END $$;

-- 为 xcm_check_ins 表添加 audio_url 字段（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'xcm_check_ins'
    AND column_name = 'audio_url'
  ) THEN
    ALTER TABLE xcm_check_ins ADD COLUMN audio_url TEXT;
  END IF;
END $$;

-- 查询确认
SELECT
  'xcm_wishes.child_id' as field_name,
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'xcm_wishes' AND column_name = 'child_id') THEN '✓ 存在'
    ELSE '✗ 不存在'
  END as status
UNION ALL
SELECT
  'xcm_check_ins.note',
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'xcm_check_ins' AND column_name = 'note') THEN '✓ 存在'
    ELSE '✗ 不存在'
  END
UNION ALL
SELECT
  'xcm_check_ins.photo_url',
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'xcm_check_ins' AND column_name = 'photo_url') THEN '✓ 存在'
    ELSE '✗ 不存在'
  END
UNION ALL
SELECT
  'xcm_check_ins.audio_url',
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'xcm_check_ins' AND column_name = 'audio_url') THEN '✓ 存在'
    ELSE '✗ 不存在'
  END;
