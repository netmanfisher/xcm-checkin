-- ============================================
-- 小虾米每日打卡 - 测试数据
-- ============================================

-- 1. 插入管理员（密码: admin123）
INSERT INTO xcm_admins (username, password_hash, name)
VALUES ('admin', '7b6b5e9e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e', '管理员')
ON CONFLICT (username) DO NOTHING;

-- 2. 插入测试孩子
INSERT INTO xcm_children (name, avatar_url, theme, status, stars, current_streak, created_at)
VALUES
  ('小虾米', '👧', 'princess', 'active', 50, 3, NOW()),
  ('小明', '👦', 'prince', 'active', 30, 1, NOW())
ON CONFLICT DO NOTHING;

-- 3. 插入学习计划
INSERT INTO xcm_study_plans (name, icon, description, duration_minutes, stars_reward, require_photo, require_audio, status, sort_order)
VALUES
  ('钢琴练习', '🎹', '每天练习钢琴30分钟', 30, 5, true, false, 'active', 1),
  ('家庭作业', '📝', '完成学校布置的作业', 30, 3, true, false, 'active', 2),
  ('写字练习', '✍️', '练习写字20分钟', 20, 2, true, false, 'active', 3),
  ('数学练习', '🔢', '做数学练习题', 20, 2, false, false, 'active', 4),
  ('阅读', '📚', '阅读课外书30分钟', 30, 3, true, false, 'active', 5),
  ('唱歌打卡', '🎤', '练习唱歌', 15, 1, false, true, 'active', 6)
ON CONFLICT DO NOTHING;

-- 4. 插入愿望清单
INSERT INTO xcm_wishes (child_id, name, description, stars_cost, status, created_at)
VALUES
  ((SELECT id FROM xcm_children WHERE name = '小虾米' LIMIT 1), '冰淇淋', '想吃美味的冰淇淋', 10, 'available', NOW()),
  ((SELECT id FROM xcm_children WHERE name = '小虾米' LIMIT 1), '新玩具', '想要一个新的玩具', 50, 'available', NOW()),
  ((SELECT id FROM xcm_children WHERE name = '小虾米' LIMIT 1), '去游乐园', '想去迪士尼乐园', 200, 'available', NOW()),
  ((SELECT id FROM xcm_children WHERE name = '小明' LIMIT 1), '乐高积木', '想要一套乐高', 100, 'available', NOW())
ON CONFLICT DO NOTHING;

-- 5. 插入成就
INSERT INTO xcm_achievements (name, description, icon, requirement_type, requirement_value, stars_reward)
VALUES
  ('初出茅庐', '完成第一次打卡', '🌱', 'total_checkins', 1, 10),
  ('坚持不懈', '连续打卡7天', '🔥', 'streak_days', 7, 30),
  ('百日成钢', '连续打卡100天', '💪', 'streak_days', 100, 200),
  ('钢琴小王子', '完成钢琴打卡50次', '🎹', 'task_completion', 50, 50),
  ('钢琴大师', '完成钢琴打卡100次', '🎹', 'task_completion', 100, 100),
  ('阅读小书虫', '完成阅读打卡50次', '📚', 'task_completion', 50, 50),
  ('阅读达人', '完成阅读打卡100次', '📚', 'task_completion', 100, 100),
  ('数学小天才', '完成数学打卡50次', '🔢', 'task_completion', 50, 50),
  ('全能小战士', '所有任务都完成过至少10次', '⭐', 'all_tasks', 10, 100)
ON CONFLICT DO NOTHING;

-- 6. 为小虾米初始化连续打卡记录
INSERT INTO xcm_streaks (child_id, current_streak, longest_streak, last_check_in_date)
VALUES
  ((SELECT id FROM xcm_children WHERE name = '小虾米' LIMIT 1), 3, 5, NOW())
ON CONFLICT (child_id) DO NOTHING;

-- 7. 插入一些历史打卡记录（用于测试历史记录和报告）
-- 首先获取小虾米的ID
DO $$
DECLARE
  v_child_id UUID;
  v_plan_piano UUID;
  v_plan_homework UUID;
  v_plan_reading UUID;
BEGIN
  -- 获取小虾米的ID
  SELECT id INTO v_child_id FROM xcm_children WHERE name = '小虾米' LIMIT 1;

  -- 获取计划ID
  SELECT id INTO v_plan_piano FROM xcm_study_plans WHERE name = '钢琴练习' LIMIT 1;
  SELECT id INTO v_plan_homework FROM xcm_study_plans WHERE name = '家庭作业' LIMIT 1;
  SELECT id INTO v_plan_reading FROM xcm_study_plans WHERE name = '阅读' LIMIT 1;

  -- 插入昨天的已审核打卡记录
  INSERT INTO xcm_check_ins (child_id, plan_id, status, check_in_time, reviewed_at)
  VALUES
    (v_child_id, v_plan_piano, 'approved', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
    (v_child_id, v_plan_homework, 'approved', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
    (v_child_id, v_plan_reading, 'approved', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day');

  -- 插入前天的已审核打卡记录
  INSERT INTO xcm_check_ins (child_id, plan_id, status, check_in_time, reviewed_at)
  VALUES
    (v_child_id, v_plan_piano, 'approved', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    (v_child_id, v_plan_homework, 'approved', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days');

  -- 插入今天的已审核打卡记录
  INSERT INTO xcm_check_ins (child_id, plan_id, status, check_in_time, reviewed_at)
  VALUES
    (v_child_id, v_plan_reading, 'approved', NOW(), NOW());

END $$;

-- 8. 插入星星历史记录（与小虾米的打卡记录对应）
DO $$
DECLARE
  v_child_id UUID;
BEGIN
  SELECT id INTO v_child_id FROM xcm_children WHERE name = '小虾米' LIMIT 1;

  -- 插入星星历史
  INSERT INTO xcm_stars_history (child_id, amount, type, source, description, transaction_time)
  VALUES
    (v_child_id, 5, 'earned', 'checkin', '完成「钢琴练习」', NOW() - INTERVAL '1 day'),
    (v_child_id, 3, 'earned', 'checkin', '完成「家庭作业」', NOW() - INTERVAL '1 day'),
    (v_child_id, 3, 'earned', 'checkin', '完成「阅读」', NOW() - INTERVAL '1 day'),
    (v_child_id, 5, 'earned', 'checkin', '完成「钢琴练习」', NOW() - INTERVAL '2 days'),
    (v_child_id, 3, 'earned', 'checkin', '完成「家庭作业」', NOW() - INTERVAL '2 days'),
    (v_child_id, 3, 'earned', 'checkin', '完成「阅读」', NOW());

END $$;

-- 9. 插入用户成就记录
DO $$
DECLARE
  v_child_id UUID;
  v_achievement_first UUID;
BEGIN
  SELECT id INTO v_child_id FROM xcm_children WHERE name = '小虾米' LIMIT 1;
  SELECT id INTO v_achievement_first FROM xcm_achievements WHERE name = '初出茅庐' LIMIT 1;

  INSERT INTO xcm_user_achievements (child_id, achievement_id, earned_at)
  VALUES (v_child_id, v_achievement_first, NOW() - INTERVAL '3 days')
  ON CONFLICT DO NOTHING;

END $$;

-- ============================================
-- 测试数据插入完成
-- ============================================

-- 查询验证
SELECT '孩子数量' as item, COUNT(*) as count FROM xcm_children WHERE status = 'active'
UNION ALL
SELECT '学习计划数量', COUNT(*) FROM xcm_study_plans WHERE status = 'active'
UNION ALL
SELECT '愿望数量', COUNT(*) FROM xcm_wishes WHERE status = 'available'
UNION ALL
SELECT '成就数量', COUNT(*) FROM xcm_achievements
UNION ALL
SELECT '历史打卡记录', COUNT(*) FROM xcm_check_ins
UNION ALL
SELECT '星星历史记录', COUNT(*) FROM xcm_stars_history;
