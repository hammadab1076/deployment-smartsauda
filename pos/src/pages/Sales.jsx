import { useState, useEffect, useCallback } from 'react'
import { Search, ChevronDown, Eye, X } from 'lucide-react'
import Header from '../components/Header'
import { getOrders } from '../services/orders'

const STATUS_COLORS = {
  completed: 'bg-success/10 text-success',
  refunded:  'bg-danger/10 text-danger',
  pending:   'bg-warning/10 text-warning',
}

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function Sales() {
  const [orders, setOrders]         = useState([])
  const [loading, setLoading]       = useState(true)
  const [error, setError]           = useState('')
  const [search, setSearch]         = useState('')
  const [statusFilter, setStatus]   = useState('All')
  const [viewOrder, setViewOrder]   = useState(null)

  const load = useCallback(async () => {
    try {
      const data = await getOrders()
      setOrders(data)
      setError('')
    } catch {
      setError('Failed to load orders.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
    const interval = setInterval(load, 30000)
    return () => clearInterval(interval)
  }, [load])

  const filtered = orders.filter(o => {
    const customer = o.customer_name || o.user_name || ''
    const matchSearch = customer.toLowerCase().includes(search.toLowerCase()) ||
                        o.id.toLowerCase().includes(search.toLowerCase())
    const matchStatus = statusFilter === 'All' || o.status === statusFilter
    return matchSearch && matchStatus
  })

  const totalRevenue  = orders.filter(o=>o.status==='completed').reduce((s,o)=>s+Number(o.total_amount||0),0)
  const totalRefunded = orders.filter(o=>o.status==='refunded').reduce((s,o)=>s+Number(o.total_amount||0),0)
  const completed     = orders.filter(o=>o.status==='completed')
  const avgOrder      = completed.length ? Math.round(totalRevenue / completed.length) : 0

  return (
    <div className="flex flex-col h-full">
      <Header title="Sales" subtitle={`${orders.length} orders · track transactions and refunds`} />

      <div className="flex-1 overflow-y-auto p-8 space-y-5">

        {error && <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger">{error}</div>}

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          {[
            { label:'Total Revenue',   value:`Rs. ${totalRevenue.toLocaleString()}`,  color:'text-primary' },
            { label:'Total Orders',    value:orders.length,                            color:'text-slate-800' },
            { label:'Avg Order Value', value:`Rs. ${avgOrder.toLocaleString()}`,       color:'text-success' },
            { label:'Refunded',        value:`Rs. ${totalRefunded.toLocaleString()}`,  color:'text-danger' },
          ].map(s=>(
            <div key={s.label} className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
              <p className="text-xs text-slate-400">{s.label}</p>
              <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Toolbar */}
        <div className="flex flex-wrap gap-3 items-center justify-between">
          <div className="flex gap-3 flex-wrap">
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input className="input pl-9 w-56" placeholder="Search by order or customer..." value={search} onChange={e=>setSearch(e.target.value)} />
            </div>
            <div className="relative">
              <select className="input pr-8 appearance-none cursor-pointer" value={statusFilter} onChange={e=>setStatus(e.target.value)}>
                <option value="All">All Statuses</option>
                <option value="completed">Completed</option>
                <option value="refunded">Refunded</option>
                <option value="pending">Pending</option>
              </select>
              <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
          </div>
          <span className="text-sm text-slate-400">{filtered.length} results</span>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-6 space-y-3">{[...Array(6)].map((_,i)=><Skeleton key={i} className="h-12" />)}</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-slate-50 text-slate-400 text-xs border-b border-slate-100">
                  <th className="text-left px-5 py-3 font-medium">Order ID</th>
                  <th className="text-left px-5 py-3 font-medium">Customer</th>
                  <th className="text-left px-5 py-3 font-medium">Date</th>
                  <th className="text-left px-5 py-3 font-medium">Total</th>
                  <th className="text-left px-5 py-3 font-medium">Status</th>
                  <th className="text-left px-5 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(o => (
                  <tr key={o.id} className="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3 font-mono text-xs text-slate-500">{o.id?.slice(0,12)}…</td>
                    <td className="px-5 py-3 font-medium text-slate-700">{o.customer_name || o.user_name || 'Unknown'}</td>
                    <td className="px-5 py-3 text-slate-500">{o.created_at ? new Date(o.created_at).toLocaleDateString('en-PK') : '—'}</td>
                    <td className="px-5 py-3 font-semibold text-slate-800">Rs. {Number(o.total_amount||0).toLocaleString()}</td>
                    <td className="px-5 py-3"><span className={`badge ${STATUS_COLORS[o.status] || 'bg-slate-100 text-slate-500'}`}>{o.status}</span></td>
                    <td className="px-5 py-3">
                      <button onClick={()=>setViewOrder(o)} className="w-8 h-8 rounded-lg bg-primary/10 hover:bg-primary/20 flex items-center justify-center transition-colors">
                        <Eye size={14} className="text-primary" />
                      </button>
                    </td>
                  </tr>
                ))}
                {!filtered.length && (
                  <tr><td colSpan={6} className="px-5 py-8 text-center text-slate-400 text-sm">No orders found</td></tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Order Detail Modal */}
      {viewOrder && (
        <div className="modal-overlay" onClick={()=>setViewOrder(null)}>
          <div className="modal max-w-md" onClick={e=>e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-800">Order Detail</h2>
                <p className="text-xs text-slate-400 font-mono">{viewOrder.id}</p>
              </div>
              <button onClick={()=>setViewOrder(null)} className="text-slate-400 hover:text-slate-600"><X size={20}/></button>
            </div>
            <div className="px-6 py-5 space-y-4 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div><p className="text-slate-400 text-xs">Customer</p><p className="font-semibold text-slate-800">{viewOrder.customer_name || viewOrder.user_name || 'Unknown'}</p></div>
                <div><p className="text-slate-400 text-xs">Date</p><p className="font-semibold text-slate-800">{viewOrder.created_at ? new Date(viewOrder.created_at).toLocaleDateString('en-PK') : '—'}</p></div>
                <div><p className="text-slate-400 text-xs">Status</p><span className={`badge ${STATUS_COLORS[viewOrder.status]}`}>{viewOrder.status}</span></div>
                <div><p className="text-slate-400 text-xs">Total</p><p className="font-bold text-slate-800 text-lg">Rs. {Number(viewOrder.total_amount||0).toLocaleString()}</p></div>
              </div>
              {viewOrder.items?.length > 0 && (
                <div>
                  <p className="text-xs text-slate-400 mb-2">Items</p>
                  <div className="space-y-2">
                    {viewOrder.items.map((item, i) => (
                      <div key={i} className="flex items-center justify-between bg-slate-50 rounded-xl px-3 py-2">
                        <span className="text-sm text-slate-700">{item.product_name} × {item.quantity}</span>
                        <span className="text-sm font-medium text-slate-800">Rs. {(item.unit_price * item.quantity).toLocaleString()}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
            <div className="px-6 pb-6 flex justify-end">
              <button onClick={()=>setViewOrder(null)} className="btn-outline">Close</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
