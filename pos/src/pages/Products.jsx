import { useState, useEffect, useCallback } from 'react'
import { Plus, Search, Edit2, Trash2, Tag, Barcode, X, ChevronDown } from 'lucide-react'
import Header from '../components/Header'
import { getProducts, createProduct, updateProduct, deleteProduct } from '../services/products'

const TYPE_COLORS = { single:'bg-blue-50 text-blue-600', variation:'bg-purple-50 text-purple-600', combo:'bg-orange-50 text-orange-600' }
const STOCK_COLOR = s => s === 0 ? 'text-danger font-semibold' : s < 20 ? 'text-warning font-semibold' : 'text-slate-600'
const CATEGORIES  = ['Beverages', 'Dairy', 'Snacks', 'Household', 'Bakery', 'Frozen']

const EMPTY_FORM  = { name:'', category:'Beverages', price:'', stock:'', barcode:'', nfc_tag_id:'', type:'single', description:'' }

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function Products() {
  const [products, setProducts]   = useState([])
  const [loading, setLoading]     = useState(true)
  const [error, setError]         = useState('')
  const [search, setSearch]       = useState('')
  const [catFilter, setCatFilter] = useState('All')
  const [typeFilter, setTypeFilter] = useState('All')
  const [showModal, setShowModal] = useState(false)
  const [editItem, setEditItem]   = useState(null)
  const [deleteId, setDeleteId]   = useState(null)
  const [saving, setSaving]       = useState(false)
  const [form, setForm]           = useState(EMPTY_FORM)

  const load = useCallback(async () => {
    try {
      const data = await getProducts()
      setProducts(data)
      setError('')
    } catch {
      setError('Failed to load products.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const filtered = products.filter(p => {
    const matchSearch = p.name.toLowerCase().includes(search.toLowerCase())
    const matchCat    = catFilter === 'All' || p.category === catFilter
    const matchType   = typeFilter === 'All' || p.type === typeFilter
    return matchSearch && matchCat && matchType
  })

  function openAdd()  { setForm(EMPTY_FORM); setEditItem(null); setShowModal(true) }
  function openEdit(p) {
    setForm({ name:p.name, category:p.category, price:String(p.price), stock:String(p.stock||0),
              barcode:p.barcode||'', nfc_tag_id:p.nfc_tag_id||'', type:p.type||'single', description:p.description||'' })
    setEditItem(p.id)
    setShowModal(true)
  }

  async function saveProduct() {
    if (!form.name || !form.price) return
    setSaving(true)
    try {
      const payload = { ...form, price: Number(form.price), stock: Number(form.stock || 0) }
      if (editItem) {
        await updateProduct(editItem, payload)
      } else {
        await createProduct(payload)
      }
      await load()
      setShowModal(false)
    } catch {
      setError('Failed to save product.')
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    try {
      await deleteProduct(deleteId)
      await load()
    } catch {
      setError('Failed to delete product.')
    } finally {
      setDeleteId(null)
    }
  }

  return (
    <div className="flex flex-col h-full">
      <Header title="Products" subtitle={`${products.length} products · manage inventory, NFC tags & barcodes`} />

      <div className="flex-1 overflow-y-auto p-8 space-y-5">

        {error && <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger">{error}</div>}

        {/* Toolbar */}
        <div className="flex flex-wrap gap-3 items-center justify-between">
          <div className="flex gap-3 flex-wrap">
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input className="input pl-9 w-56" placeholder="Search products..." value={search} onChange={e=>setSearch(e.target.value)} />
            </div>
            <div className="relative">
              <select className="input pr-8 appearance-none cursor-pointer" value={catFilter} onChange={e=>setCatFilter(e.target.value)}>
                <option value="All">All Categories</option>
                {CATEGORIES.map(c=><option key={c}>{c}</option>)}
              </select>
              <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
            <div className="relative">
              <select className="input pr-8 appearance-none cursor-pointer" value={typeFilter} onChange={e=>setTypeFilter(e.target.value)}>
                <option value="All">All Types</option>
                <option value="single">Single</option>
                <option value="variation">Variation</option>
                <option value="combo">Combo</option>
              </select>
              <ChevronDown size={14} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
            </div>
          </div>
          <button onClick={openAdd} className="btn-success"><Plus size={16}/> Add Product</button>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-4 gap-4">
          {[
            { label:'Total Products',   value:products.length,                              color:'text-primary' },
            { label:'In Stock',         value:products.filter(p=>p.stock>0).length,         color:'text-success' },
            { label:'Low Stock (<20)',  value:products.filter(p=>p.stock>0&&p.stock<20).length, color:'text-warning' },
            { label:'NFC Assigned',     value:products.filter(p=>p.nfc_tag_id).length,      color:'text-purple-600' },
          ].map(s=>(
            <div key={s.label} className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
              <p className="text-xs text-slate-400">{s.label}</p>
              <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-6 space-y-3">{[...Array(6)].map((_,i)=><Skeleton key={i} className="h-12" />)}</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-slate-50 text-slate-400 text-xs border-b border-slate-100">
                  <th className="text-left px-5 py-3 font-medium">Product</th>
                  <th className="text-left px-5 py-3 font-medium">Category</th>
                  <th className="text-left px-5 py-3 font-medium">Type</th>
                  <th className="text-left px-5 py-3 font-medium">Price</th>
                  <th className="text-left px-5 py-3 font-medium">Stock</th>
                  <th className="text-left px-5 py-3 font-medium">NFC Tag</th>
                  <th className="text-left px-5 py-3 font-medium">Barcode</th>
                  <th className="text-left px-5 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(p => (
                  <tr key={p.id} className="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-slate-100 flex items-center justify-center text-lg">🛒</div>
                        <div>
                          <p className="font-semibold text-slate-800">{p.name}</p>
                          <p className="text-xs text-slate-400">{p.id}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-slate-500">{p.category}</td>
                    <td className="px-5 py-3">
                      <span className={`badge ${TYPE_COLORS[p.type] || 'bg-slate-100 text-slate-500'}`}>{p.type || 'single'}</span>
                    </td>
                    <td className="px-5 py-3 font-semibold text-slate-800">Rs. {Number(p.price).toLocaleString()}</td>
                    <td className={`px-5 py-3 ${STOCK_COLOR(p.stock)}`}>{p.stock} units</td>
                    <td className="px-5 py-3">
                      {p.nfc_tag_id
                        ? <span className="flex items-center gap-1 text-xs font-mono text-purple-600 bg-purple-50 px-2 py-1 rounded-lg w-fit"><Tag size={11}/>{p.nfc_tag_id}</span>
                        : <span className="text-slate-300 text-xs">—</span>}
                    </td>
                    <td className="px-5 py-3">
                      {p.barcode
                        ? <span className="flex items-center gap-1 text-xs font-mono text-slate-500"><Barcode size={11}/>{p.barcode}</span>
                        : <span className="text-slate-300 text-xs">—</span>}
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex gap-2">
                        <button onClick={()=>openEdit(p)} className="w-8 h-8 rounded-lg bg-primary/10 hover:bg-primary/20 flex items-center justify-center transition-colors">
                          <Edit2 size={14} className="text-primary" />
                        </button>
                        <button onClick={()=>setDeleteId(p.id)} className="w-8 h-8 rounded-lg bg-danger/10 hover:bg-danger/20 flex items-center justify-center transition-colors">
                          <Trash2 size={14} className="text-danger" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!filtered.length && (
                  <tr><td colSpan={8} className="px-5 py-8 text-center text-slate-400 text-sm">No products found</td></tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Add/Edit Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={()=>setShowModal(false)}>
          <div className="modal" onClick={e=>e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
              <h2 className="text-lg font-bold text-slate-800">{editItem ? 'Edit Product' : 'Add New Product'}</h2>
              <button onClick={()=>setShowModal(false)} className="text-slate-400 hover:text-slate-600"><X size={20}/></button>
            </div>
            <div className="px-6 py-5 space-y-4">
              <div>
                <label className="label">Product Type</label>
                <div className="flex gap-3">
                  {['single','variation','combo'].map(t=>(
                    <button key={t} onClick={()=>setForm(f=>({...f,type:t}))}
                      className={`flex-1 py-2 rounded-xl text-sm font-semibold border capitalize transition-all
                        ${form.type===t ? 'border-primary bg-primary/5 text-primary' : 'border-slate-200 text-slate-400 hover:border-primary/40'}`}>
                      {t}
                    </button>
                  ))}
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div className="col-span-2">
                  <label className="label">Product Name *</label>
                  <input className="input" placeholder="e.g. Coke 1.5 Liter" value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} />
                </div>
                <div>
                  <label className="label">Category</label>
                  <select className="input" value={form.category} onChange={e=>setForm(f=>({...f,category:e.target.value}))}>
                    {CATEGORIES.map(c=><option key={c}>{c}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Price (Rs.) *</label>
                  <input className="input" type="number" placeholder="0" value={form.price} onChange={e=>setForm(f=>({...f,price:e.target.value}))} />
                </div>
                <div>
                  <label className="label">Stock (units)</label>
                  <input className="input" type="number" placeholder="0" value={form.stock} onChange={e=>setForm(f=>({...f,stock:e.target.value}))} />
                </div>
                <div>
                  <label className="label">Barcode</label>
                  <input className="input" placeholder="e.g. 6001000000010" value={form.barcode} onChange={e=>setForm(f=>({...f,barcode:e.target.value}))} />
                </div>
                <div className="col-span-2">
                  <label className="label">NFC Tag UID</label>
                  <input className="input font-mono" placeholder="e.g. 437702f8" value={form.nfc_tag_id} onChange={e=>setForm(f=>({...f,nfc_tag_id:e.target.value}))} />
                </div>
                <div className="col-span-2">
                  <label className="label">Description</label>
                  <textarea className="input resize-none" rows={2} value={form.description} onChange={e=>setForm(f=>({...f,description:e.target.value}))} />
                </div>
              </div>
            </div>
            <div className="px-6 pb-6 flex gap-3 justify-end">
              <button onClick={()=>setShowModal(false)} className="btn-outline">Cancel</button>
              <button onClick={saveProduct} disabled={saving} className="btn-success disabled:opacity-60">
                {saving ? 'Saving…' : editItem ? 'Save Changes' : 'Add Product'}
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
              <h3 className="font-bold text-slate-800 text-lg">Delete Product?</h3>
              <p className="text-sm text-slate-500">This action cannot be undone.</p>
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
