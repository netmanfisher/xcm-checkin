import BaaS from 'minapp-sdk'

// 初始化知晓云
BaaS.init({
  clientId: import.meta.env.VITE_BAAS_CLIENT_ID,
  clientSecret: import.meta.env.VITE_BAAS_CLIENT_SECRET
})

export default BaaS
