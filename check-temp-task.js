const { createClient } = require('@supabase/supabase-js')

const supabaseUrl = 'https://jheroeajgvyhetjcxmlr.supabase.co'
const supabaseKey = 'sb_publishable_o_8JWWcuHuuakSssWtgQCQ_tZ-RgV-R'

const supabase = createClient(supabaseUrl, supabaseKey)

async function checkTempTasks() {
  try {
    const { data: plans, error } = await supabase
      .from('xcm_study_plans')
      .select('*')
      .eq('status', 'active')
    
    if (error) throw error
    
    console.log('所有启用的计划:')
    plans.forEach(plan => {
      console.log('- ' + plan.name + ' (ID: ' + plan.id + ')')
      console.log('  weekdays: ' + JSON.stringify(plan.weekdays))
      console.log('  time_period: ' + plan.time_period)
      console.log('---')
    })
    
    const tempPlans = plans.filter(p => p.weekdays && p.weekdays.includes(0))
    console.log('\n包含"当日当次"(0)的计划数量: ' + tempPlans.length)
    tempPlans.forEach(plan => {
      console.log('- ' + plan.name + ' (ID: ' + plan.id + ')')
    })
    
  } catch (error) {
    console.error('错误:', error)
  }
}

checkTempTasks()
