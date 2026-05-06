import api from './api'
export const getPurchaseOrders  = ()           => api.get('/purchase-orders').then(r => r.data)
export const createPurchaseOrder = (data)      => api.post('/purchase-orders', data).then(r => r.data)
export const updatePOStatus     = (id, status) => api.patch(`/purchase-orders/${id}/status`, { status }).then(r => r.data)
export const deletePurchaseOrder = (id)        => api.delete(`/purchase-orders/${id}`).then(r => r.data)
