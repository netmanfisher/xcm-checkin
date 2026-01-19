-- 将所有学习计划的照片和录音要求改为可选（false）
UPDATE xcm_study_plans
SET require_photo = false,
    require_audio = false
WHERE status = 'active';

-- 查询确认
SELECT name, require_photo, require_audio
FROM xcm_study_plans
WHERE status = 'active';
