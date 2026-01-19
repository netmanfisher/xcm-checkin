import BaaS from './baas.js'

// 初始化任务数据
export async function initTasks() {
  const Tasks = BaaS.TableObject('tasks')
  const tasks = [
    {
      name: '钢琴练习',
      icon: '🎹',
      description: '每天练习钢琴30分钟',
      duration_minutes: 30,
      coins_reward: 15,
      exp_reward: 30,
      is_active: true,
      sort_order: 1
    },
    {
      name: '家庭作业',
      icon: '📝',
      description: '完成学校布置的作业',
      duration_minutes: 30,
      coins_reward: 10,
      exp_reward: 20,
      is_active: true,
      sort_order: 2
    },
    {
      name: '写字练习',
      icon: '✍️',
      description: '练习写字20分钟',
      duration_minutes: 20,
      coins_reward: 10,
      exp_reward: 20,
      is_active: true,
      sort_order: 3
    },
    {
      name: '数学练习',
      icon: '🔢',
      description: '做数学练习题',
      duration_minutes: 20,
      coins_reward: 10,
      exp_reward: 20,
      is_active: true,
      sort_order: 4
    },
    {
      name: '阅读',
      icon: '📚',
      description: '阅读课外书30分钟',
      duration_minutes: 30,
      coins_reward: 10,
      exp_reward: 20,
      is_active: true,
      sort_order: 5
    },
    {
      name: '唱歌打卡',
      icon: '🎤',
      description: '练习唱歌',
      duration_minutes: 15,
      coins_reward: 5,
      exp_reward: 10,
      is_active: true,
      sort_order: 6
    }
  ]

  try {
    for (const task of tasks) {
      await Tasks.set(task).save()
    }
    console.log('任务初始化成功')
  } catch (error) {
    console.error('任务初始化失败:', error)
  }
}

// 获取所有任务
export async function getTasks() {
  const Tasks = BaaS.TableObject('tasks')
  try {
    const res = await Tasks.getQuery()
      .equalTo('is_active', true)
      .orderBy('sort_order')
      .find()
    return res.data.objects
  } catch (error) {
    console.error('获取任务失败:', error)
    return []
  }
}

// 打卡
export async function checkIn(taskId, userId) {
  const CheckIns = BaaS.TableObject('check_ins')
  const Tasks = BaaS.TableObject('tasks')

  try {
    // 获取任务信息
    const taskRes = await Tasks.get(taskId)
    const task = taskRes.data

    // 创建打卡记录
    await CheckIns.set({
      user_id: userId,
      task_id: taskId,
      task_name: task.name,
      duration_minutes: task.duration_minutes
    }).save()

    // 更新用户金币和经验
    const Profiles = BaaS.TableObject('profiles')
    const profileRes = await Profiles.getQuery()
      .equalTo('user_id', userId)
      .find()

    if (profileRes.data.objects.length > 0) {
      const profile = profileRes.data.objects[0]
      await Profiles.update(profile.id, {
        coins: (profile.coins || 0) + task.coins_reward,
        exp: (profile.exp || 0) + task.exp_reward
      })
    }

    return {
      success: true,
      coins: task.coins_reward,
      exp: task.exp_reward
    }
  } catch (error) {
    console.error('打卡失败:', error)
    return { success: false, error }
  }
}

// 获取今日打卡记录
export async function getTodayCheckIns(userId) {
  const CheckIns = BaaS.TableObject('check_ins')
  const today = new Date()
  today.setHours(0, 0, 0, 0)

  try {
    const res = await CheckIns.getQuery()
      .equalTo('user_id', userId)
      .greaterThanOrEqualTo('created_at', today.toISOString())
      .find()
    return res.data.objects
  } catch (error) {
    console.error('获取今日打卡失败:', error)
    return []
  }
}

// 获取或创建用户资料
export async function getOrCreateProfile(userId, username) {
  const Profiles = BaaS.TableObject('profiles')

  try {
    const res = await Profiles.getQuery()
      .equalTo('user_id', userId)
      .find()

    if (res.data.objects.length > 0) {
      return res.data.objects[0]
    } else {
      // 创建新用户
      const newProfile = await Profiles.set({
        user_id: userId,
        username: username,
        nickname: username,
        level: 1,
        exp: 0,
        coins: 0
      }).save()
      return newProfile.data
    }
  } catch (error) {
    console.error('获取用户资料失败:', error)
    return null
  }
}

// 初始化成就数据
export async function initAchievements() {
  const Achievements = BaaS.TableObject('achievements')
  const achievements = [
    {
      name: '初出茅庐',
      description: '完成第一次打卡',
      icon: '🌱',
      requirement_type: 'total_checkins',
      requirement_value: 1,
      coins_reward: 20
    },
    {
      name: '坚持不懈',
      description: '连续打卡7天',
      icon: '🔥',
      requirement_type: 'streak_days',
      requirement_value: 7,
      coins_reward: 50
    },
    {
      name: '百日成钢',
      description: '连续打卡100天',
      icon: '💪',
      requirement_type: 'streak_days',
      requirement_value: 100,
      coins_reward: 200
    },
    {
      name: '钢琴小王子',
      description: '完成钢琴打卡50次',
      icon: '🎹',
      requirement_type: 'task_completion',
      requirement_value: 50,
      coins_reward: 100
    },
    {
      name: '阅读小书虫',
      description: '完成阅读打卡50次',
      icon: '📚',
      requirement_type: 'task_completion',
      requirement_value: 50,
      coins_reward: 100
    }
  ]

  try {
    for (const achievement of achievements) {
      await Achievements.set(achievement).save()
    }
    console.log('成就初始化成功')
  } catch (error) {
    console.error('成就初始化失败:', error)
  }
}
