import api from './api'
export const getNotifications = () => api.get('/notifications').then(r => r.data)
