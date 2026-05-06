import { useState, useEffect, useCallback } from 'react'
import { Search, Plus, ChevronDown, Eye, X, CheckCircle, Clock } from 'lucide-react'
import Header from '../components/Header'
import { getSuppliers } from '../services/suppliers'
import { getPurchaseOrders, createPurchaseOrder, updatePOStatus } from '../services/purchase'

const STATUS_COLORS = {
  received:  'bg-success/10 text-success',
  pending:   'bg-warning/10 text-warning',
  cancelled: 'bg-danger/10 text-danger',
}

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function Purchase() {
  const [orders, setOrders]         = useState([])
  const [suppliers, setSuppliers]   = useState([])
  const [loading, setLoading]       = useState(true)
  const [error, setError]           = useState('')
  const [search, setSearch]         = useState('')
  const [statusFilter, setStatus]   = useState('All')
  const [showModal, setShowModal]   = useState(false)
  const [viewPO, setViewPO]         = useState(null)
  const [saving, setSaving]         = useState(false)
  const [form, setForm]             = useState({ supplier_id:'', supplier_name:'', date:'', items_count:1, total_cost:'', status:'pending' })

  const load = useCallback(async () => {
    try {
      const [pos, sups] = await Promise.all([getPurchaseOrders(), getSuppliers()])
      setOrders(pos)
      setSuppliers(sups)
      setError('')
    } catch {
      setError('Failed to load purchase orders.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const filtered = orders.filter(po => {
    const matchSearch = po.supplier_name?.toLowerCase().includes(search.toLowerCase()) ||
                        po.id?.toLowerCase().includes(search.toLowerCase())
    const matchStatus = statusFilter === 'All' || po.status === statusFilter
    return matchSearch && matchStatus
  })

  const totalSpend   = orders.filter(p=>p.status==='received').reduce((s,p)=>s+Number(p.total_cost||0),0)
  const pendingSpend = orders.filter(p=>p.status==='pending').reduce((s,p)=>s+Number(p.total_cost||0),0)

  async function savePO() {
    if (!form.supplier_name || !form.date || !form.total_cost) return
    setSaving(true)
    try {
      await createPurchaseOrder({ ...form, items_count: Number(form.items_count), total_cost: Number(form.total_cost) })
      await load()
      setShowModal(false)
    } catch {
      setError('Failed to create purchase order.')
    } finally {
      setSaving(false)
    }
  }

  async function markReceived(id) {
    try {
      await updatePOStatus(id, 'received')
      await load()
    } catch {
      setError('Failed to update status.')
    }
  }

  function handleSupplierChange(supplierId) {
    const sup = suppliers.find(s => s.id === supplierId)
    setForm(f => ({ ...f, supplier_id: supplierId, supplier_name: sup ? sup.name : '' }))
  }

  return (
    <div className="flex flex-col h-full">
      <Header title="Purchase" subtitle={`${orders.length} purchase orders · manage incoming stock`} />

      <div className="flex-1 overflow-y-auto p-8 space-y-5">

        {error && <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger">{error}</div>}

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          {[
            { label:'Total POs',    value:orders.length,                                    color:'text-slate-800' },
            { label:'Received',     value:orders.filter(p=>p.status==='received').length,   color:'text-success' },
            { label:'Pending',      value:orders.filter(p=>p.status==='pending').length,    color:'text-warning' },
            { label:'Total Spend',  value:`Rs. ${totalSpend.toLocaleString()}`,             color:'text-primary' },
          ].map(s=>(
            <div key={s.label} className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
              <p className="text-xs text-slate-400">{s.label}</p>
              <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Pending alert */}
        {pendingSpend > 0 && (
          <div className="bg-warning/10 border border-warning/30 rounded-2xl px-5 py-3 flex items-center gap-3">
            <Clock size={18} className="text-warning" />
            <span className="text-sm font-medium text-amber-800">
              {orders.filter(p=>p.status==='pending').length} pending orders totalling{' '}
              <strong>Rs. {pendingSpend.toLocaleString()}</strong> awaiting delivery confirmation.
            </span>
          </div>
        )}

        {/* Toolbar */}
        <div className="flex flex-wrap gap-3 items-center justify-between">
          <div className="flex gap-3">
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input className="input pl-9 w-56" placeholder="Search purchase orders..." value={search} onChange={e=>setSearch(e.target.value)} />
            </div>
            <div className="relative">
              <select className="input pr-8 appearance-none cursor-pointer" value={statusFilter} onChange={e=>setStatus(e.target.value)}>
                <option value="All">All Statuses</option>
                <option value="received">Received</option>
                <option value="pending">Pending</option>
                <option value="cancelled">Cancelled</option>
              </select>
              <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
          </div>
          <button onClick={()=>{ setForm({ supplier_id:'', supplier_name:'', date:new Date().toISOString().slice(0,10), items_count:1, total_cost:'', status:'pending' }); setShowModal(true) }} className="btn-success">
            <Plus size={16}/> New PO
          </button>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-6 space-y-3">{[...Array(5)].map((_,i)=><Skeleton key={i} className="h-12" />)}</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-slate-50 text-slate-400 text-xs border-b border-slate-100">
                  <th className="text-left px-5 py-3 font-medium">PO ID</th>
                  <th className="text-left px-5 py-3 font-medium">Supplier</th>
                  <th className="text-left px-5 py-3 font-medium">Date</th>
                  <th className="text-left px-5 py-3 font-medium">Items</th>
                  <th className="text-left px-5 py-3 font-medium">Total Cost</th>
                  <th className="text-left px-5 py-3 font-medium">Status</th>
                  <th className="text-left px-5 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(po => (
                  <tr key={po.id} className="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3 font-mono text-xs text-slate-500">{po.id?.slice(0,12)}…</td>
                    <td className="px-5 py-3 font-medium text-slate-700">{po.supplier_name}</td>
                    <td className="px-5 py-3 text-slate-500">{po.date ? new Date(po.date).toLocaleDateString('en-PK') : '—'}</td>
                    <td className="px-5 py-3 text-slate-500">{po.items_count} items</td>
                    <td className="px-5 py-3 font-semibold text-slate-800">Rs. {Number(po.total_cost||0).toLocaleString()}</td>
                    <td className="px-5 py-3"><span className={`badge ${STATUS_COLORS[po.status]}`}>{po.status}</span></td>
                    <td className="px-5 py-3">
                      <div className="flex gap-2">
                        <button onClick={()=>setViewPO(po)} className="w-8 h-8 rounded-lg bg-primary/10 hover:bg-primary/20 flex items-center justify-center">
                          <Eye size={14} className="text-primary" />
                        </button>
                        {po.status === 'pending' && (
                          <button onClick={()=>markReceived(po.id)} className="w-8 h-8 rounded-lg bg-success/10 hover:bg-success/20 flex items-center justify-center">
                            <CheckCircle size={14} className="text-success" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {!filtered.length && (
                  <tr><td colSpan={7} className="px-5 py-8 text-center text-slate-400 text-sm">No purchase orders found</td></tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* New PO Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={()=>setShowModal(false)}>
          <div className="modal max-w-md" onClick={e=>e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-800">New Purchase Order</h2>
              <button onClick={()=>setShowModal(false)} className="text-slate-400 hover:text-slate-600"><X size={20}/></button>
            </div>
            <div className="px-6 py-5 space-y-4">
              <div>
                <label className="label">Supplier *</label>
                <select className="input" value={form.supplier_id} onChange={e=>handleSupplierChange(e.target.value)}>
                  <option value="">Select supplier…</option>
                  {suppliers.map(s=><option key={s.id} value={s.id}>{s.name}</option>)}
                  <option value="__manual__">Enter manually…</option>
                </select>
              </div>
              {form.supplier_id === '__manual__' && (
                <div>
                  <label className="label">Supplier Name *</label>
                  <input className="input" placeholder="Supplier name" value={form.supplier_name} onChange={e=>setForm(f=>({...f,supplier_name:e.target.value}))} />
                </div>
              )}
              <div>
                <label className="label">Date *</label>
                <input className="input" type="date" value={form.date} onChange={e=>setForm(f=>({...f,date:e.target.value}))} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="label">Number of Items</label>
                  <input className="input" type="number" min={1} value={form.items_count} onChange={e=>setForm(f=>({...f,items_count:e.target.value}))} />
                </div>
                <div>
                  <label className="label">Total Cost (Rs.) *</label>
                  <input className="input" type="number" placeholder="0" value={form.total_cost} onChange={e=>setForm(f=>({...f,total_cost:e.target.value}))} />
                </div>
              </div>
              <div>
                <label className="label">Status</label>
                <select className="input" value={form.status} onChange={e=>setForm(f=>({...f,status:e.target.value}))}>
                  <option value="pending">Pending</option>
                  <option value="received">Received</option>
                </select>
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3 justify-end">
              <button onClick={()=>setShowModal(false)} className="btn-outline">Cancel</button>
              <button onClick={savePO} disabled={saving} className="btn-success disabled:opacity-60">
                {saving ? 'Creating…' : 'Create PO'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* View PO Modal */}
      {viewPO && (
        <div className="modal-overlay" onClick={()=>setViewPO(null)}>
          <div className="modal max-w-sm" onClick={e=>e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-800">Purchase Order</h2>
                <p className="text-xs font-mono text-slate-400">{viewPO.id}</p>
              </div>
              <button onClick={()=>setViewPO(null)} className="text-slate-400 hover:text-slate-600"><X size={20}/></button>
            </div>
            <div className="px-6 py-5 space-y-3 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div><p className="text-slate-400 text-xs">Supplier</p><p className="font-semibold text-slate-800">{viewPO.supplier_name}</p></div>
                <div><p className="text-slate-400 text-xs">Date</p><p className="font-semibold text-slate-800">{viewPO.date ? new Date(viewPO.date).toLocaleDateString('en-PK') : '—'}</p></div>
                <div><p className="text-slate-400 text-xs">Items</p><p className="font-semibold text-slate-800">{viewPO.items_count}</p></div>
                <div><p className="text-slate-400 text-xs">Status</p><span className={`badge ${STATUS_COLORS[viewPO.status]}`}>{viewPO.status}</span></div>
                <div className="col-span-2"><p className="text-slate-400 text-xs">Total Cost</p><p className="font-bold text-slate-800 text-xl">Rs. {Number(viewPO.total_cost||0).toLocaleString()}</p></div>
                {viewPO.notes && <div className="col-span-2"><p className="text-slate-400 text-xs">Notes</p><p className="text-slate-600">{viewPO.notes}</p></div>}
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3 justify-end">
              {viewPO.status === 'pending' && (
                <button onClick={()=>{ markReceived(viewPO.id); setViewPO(null) }} className="btn-success">Mark Received</button>
              )}
              <button onClick={()=>setViewPO(null)} className="btn-outline">Close</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
