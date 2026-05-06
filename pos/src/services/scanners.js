import api from './api'
export const getScanners = () => api.get('/scanners').then(r => r.data)
