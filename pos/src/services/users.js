import api from './api'
export const getUsers         = ()                       => api.get('/users').then(r => r.data)
export const createUser       = (name, email, password, role) => api.post('/auth/register', { name, email, password, role }).then(r => r.data)
export const updateUser       = (id, data)               => api.put(`/users/${id}`, data).then(r => r.data)
export const toggleUserStatus = (id, isActive)           => api.put(`/users/${id}/status`, { isActive }).then(r => r.data)
export const deleteUser       = (id)                     => api.delete(`/users/${id}`).then(r => r.data)
