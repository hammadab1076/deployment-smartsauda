import { useState, useEffect, useCallback } from 'react'
import { Search, Plus, Edit2, Trash2, X, Phone, Mail } from 'lucide-react'
import Header from '../components/Header'
import { getSuppliers, createSupplier, updateSupplier, deleteSupplier } from '../services/suppliers'

const EMPTY_FORM = { name:'', contact_person:'', phone:'', email:'', notes:'' }

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function Contacts() {
  const [suppliers, setSuppliers] = useState([])
  const [loading, setLoading]     = useState(true)
  const [error, setError]         = useState('')
  const [search, setSearch]       = useState('')
  const [showModal, setShowModal] = useState(false)
  const [editId, setEditId]       = useState(null)
  const [deleteId, setDeleteId]   = useState(null)
  const [saving, setSaving]       = useState(false)
  const [form, setForm]           = useState(EMPTY_FORM)

  const load = useCallback(async () => {
    try {
      const data = await getSuppliers()
      setSuppliers(data)
      setError('')
    } catch {
      setError('Failed to load suppliers.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const filtered = suppliers.filter(s =>
    s.name?.toLowerCase().includes(search.toLowerCase()) ||
    s.contact_person?.toLowerCase().includes(search.toLowerCase())
  )

  function openAdd()  { setForm(EMPTY_FORM); setEditId(null); setShowModal(true) }
  function openEdit(s) {
    setForm({ name:s.name, contact_person:s.contact_person||'', phone:s.phone||'', email:s.email||'', notes:s.notes||'' })
    setEditId(s.id)
    setShowModal(true)
  }

  async function save() {
    if (!form.name) return
    setSaving(true)
    try {
      if (editId) {
        await updateSupplier(editId, form)
      } else {
        await createSupplier(form)
      }
      await load()
      setShowModal(false)
    } catch {
      setError('Failed to save supplier.')
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    try {
      await deleteSupplier(deleteId)
      await load()
    } catch {
      setError('Failed to delete supplier.')
    } finally {
      setDeleteId(null)
    }
  }

  return (
    <div className="flex flex-col h-full">
      <Header title="Contacts" subtitle={`${suppliers.length} suppliers · manage vendor relationships`} />

      <div className="flex-1 overflow-y-auto p-8 space-y-5">

        {error && <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger">{error}</div>}

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4">
          <div className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
            <p className="text-xs text-slate-400">Total Suppliers</p>
            <p className="text-2xl font-bold mt-1 text-primary">{suppliers.length}</p>
          </div>
          <div className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
            <p className="text-xs text-slate-400">With Email</p>
            <p className="text-2xl font-bold mt-1 text-success">{suppliers.filter(s=>s.email).length}</p>
          </div>
          <div className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
            <p className="text-xs text-slate-400">With Phone</p>
            <p className="text-2xl font-bold mt-1 text-slate-800">{suppliers.filter(s=>s.phone).length}</p>
          </div>
        </div>

        {/* Toolbar */}
        <div className="flex gap-3 items-center justify-between">
          <div className="relative">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input className="input pl-9 w-64" placeholder="Search suppliers..." value={search} onChange={e=>setSearch(e.target.value)} />
          </div>
          <button onClick={openAdd} className="btn-success"><Plus size={16}/> Add Supplier</button>
        </div>

        {/* Cards Grid */}
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {[...Array(6)].map((_,i) => <Skeleton key={i} className="h-44" />)}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {filtered.map(s => (
              <div key={s.id} className="bg-white rounded-2xl border border-slate-100 shadow-sm p-5 space-y-4">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
                      <span className="text-primary font-bold text-base">{s.name?.charAt(0)}</span>
                    </div>
                    <div>
                      <p className="font-semibold text-slate-800 text-sm leading-tight">{s.name}</p>
                      <p className="text-xs text-slate-400">{s.contact_person || '—'}</p>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={()=>openEdit(s)} className="w-7 h-7 rounded-lg bg-primary/10 hover:bg-primary/20 flex items-center justify-center">
                      <Edit2 size={12} className="text-primary" />
                    </button>
                    <button onClick={()=>setDeleteId(s.id)} className="w-7 h-7 rounded-lg bg-danger/10 hover:bg-danger/20 flex items-center justify-center">
                      <Trash2 size={12} className="text-danger" />
                    </button>
                  </div>
                </div>

                <div className="space-y-1.5">
                  {s.phone && (
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <Phone size={12} className="text-slate-400" />{s.phone}
                    </div>
                  )}
                  {s.email && (
                    <div className="flex items-center gap-2 text-xs text-slate-500">
                      <Mail size={12} className="text-slate-400" />{s.email}
                    </div>
                  )}
                </div>

                {s.notes && (
                  <div className="bg-slate-50 rounded-xl px-3 py-2">
                    <p className="text-xs text-slate-500">{s.notes}</p>
                  </div>
                )}

                <div className="text-xs text-slate-400 pt-1">
                  Added {s.created_at ? new Date(s.created_at).toLocaleDateString('en-PK') : '—'}
                </div>
              </div>
            ))}
            {!filtered.length && (
              <div className="col-span-3 text-center py-12 text-slate-400 text-sm">No suppliers found</div>
            )}
          </div>
        )}
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={()=>setShowModal(false)}>
          <div className="modal max-w-md" onClick={e=>e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-800">{editId ? 'Edit Supplier' : 'Add Supplier'}</h2>
              <button onClick={()=>setShowModal(false)} className="text-slate-400 hover:text-slate-600"><X size={20}/></button>
            </div>
            <div className="px-6 py-5 space-y-4">
              <div>
                <label className="label">Company Name *</label>
                <input className="input" placeholder="e.g. Nestle Pakistan Ltd" value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} />
              </div>
              <div>
                <label className="label">Contact Person</label>
                <input className="input" placeholder="e.g. Rizwan Ahmed" value={form.contact_person} onChange={e=>setForm(f=>({...f,contact_person:e.target.value}))} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="label">Phone</label>
                  <input className="input" placeholder="021-XXXXXXX" value={form.phone} onChange={e=>setForm(f=>({...f,phone:e.target.value}))} />
                </div>
                <div>
                  <label className="label">Email</label>
                  <input className="input" type="email" placeholder="orders@company.pk" value={form.email} onChange={e=>setForm(f=>({...f,email:e.target.value}))} />
                </div>
              </div>
              <div>
                <label className="label">Notes</label>
                <textarea className="input resize-none" rows={2} placeholder="Any notes about this supplier..." value={form.notes} onChange={e=>setForm(f=>({...f,notes:e.target.value}))} />
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3 justify-end">
              <button onClick={()=>setShowModal(false)} className="btn-outline">Cancel</button>
              <button onClick={save} disabled={saving} className="btn-success disabled:opacity-60">
                {saving ? 'Saving…' : editId ? 'Save Changes' : 'Add Supplier'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="modal-overlay" onClick={()=>setDeleteId(null)}>
          <div className="modal max-w-sm" onClick={e=>e.stopPropagation()}>
            <div className="p-6 text-center space-y-4">
              <div className="w-14 h-14 bg-danger/10 rounded-full flex items-center justify-center mx-auto">
                <Trash2 size={24} className="text-danger" />
              </div>
              <h3 className="font-bold text-slate-800 text-lg">Delete Supplier?</h3>
              <p className="text-sm text-slate-500">This will remove the supplier permanently.</p>
              <div className="flex gap-3 pt-2">
                <button onClick={()=>setDeleteId(null)} className="btn-outline flex-1 justify-center">Cancel</button>
                <button onClick={handleDelete} className="flex-1 bg-danger text-white py-2 rounded-xl text-sm font-semibold hover:bg-red-700 transition-colors">Delete</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
