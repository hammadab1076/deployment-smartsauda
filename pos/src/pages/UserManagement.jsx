import { useState, useEffect, useCallback } from 'react'
import { Search, Plus, Edit2, Trash2, X, ShieldCheck, User, Eye, EyeOff } from 'lucide-react'
import Header from '../components/Header'
import { getUsers, createUser, updateUser, toggleUserStatus, deleteUser } from '../services/users'

const ROLE_BADGE = {
  customer: 'bg-success/10 text-success',
  auditor:  'bg-purple-50 text-purple-600',
}

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function UserManagement() {
  const [users, setUsers]         = useState([])
  const [loading, setLoading]     = useState(true)
  const [error, setError]         = useState('')
  const [tab, setTab]             = useState('customer')
  const [search, setSearch]       = useState('')
  const [saving, setSaving]       = useState(false)
  const [deleteId, setDeleteId]   = useState(null)

  // Modal state — mode: null | 'create' | 'edit'
  const [mode, setMode]           = useState(null)
  const [editId, setEditId]       = useState(null)
  const [form, setForm]           = useState({ name: '', email: '', password: '', role: 'auditor' })
  const [showPw, setShowPw]       = useState(false)

  const load = useCallback(async () => {
    try {
      const data = await getUsers()
      setUsers(data)
      setError('')
    } catch {
      setError('Failed to load users.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const nonAdmins = users.filter(u => u.role !== 'admin')
  const visible   = nonAdmins.filter(u =>
    u.role === tab &&
    (u.name?.toLowerCase().includes(search.toLowerCase()) ||
     u.email?.toLowerCase().includes(search.toLowerCase()))
  )
  const customers = nonAdmins.filter(u => u.role === 'customer')
  const auditors  = nonAdmins.filter(u => u.role === 'auditor')

  function openCreate() {
    setForm({ name: '', email: '', password: '', role: tab })
    setEditId(null)
    setShowPw(false)
    setMode('create')
  }
  function openEdit(u) {
    setForm({ name: u.name, email: u.email, password: '', role: u.role })
    setEditId(u.id)
    setShowPw(false)
    setMode('edit')
  }
  function closeModal() { setMode(null); setEditId(null) }

  async function save() {
    if (!form.name || !form.email) return
    setSaving(true)
    try {
      if (mode === 'create') {
        if (!form.password || form.password.length < 6) {
          setError('Password must be at least 6 characters.')
          return
        }
        await createUser(form.name, form.email, form.password, form.role)
      } else {
        await updateUser(editId, { name: form.name, phone: null })
      }
      await load()
      closeModal()
      setError('')
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to save user.')
    } finally {
      setSaving(false)
    }
  }

  async function handleToggle(u) {
    try {
      await toggleUserStatus(u.id, !u.is_active)
      await load()
    } catch {
      setError('Failed to update status.')
    }
  }

  async function handleDelete() {
    try {
      await deleteUser(deleteId)
      await load()
    } catch {
      setError('Failed to delete user.')
    } finally {
      setDeleteId(null)
    }
  }

  return (
    <div className="flex flex-col h-full">
      <Header title="User Management" subtitle="Manage customers and auditors" />

      <div className="flex-1 overflow-y-auto p-8 space-y-5">

        {error && (
          <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger flex items-center justify-between">
            {error}
            <button onClick={() => setError('')}><X size={14}/></button>
          </div>
        )}

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4">
          {[
            { label: 'Total Customers',  value: customers.length,                        color: 'text-success' },
            { label: 'Active Customers', value: customers.filter(u=>u.is_active).length, color: 'text-primary' },
            { label: 'Total Auditors',   value: auditors.length,                         color: 'text-purple-600' },
            { label: 'Active Auditors',  value: auditors.filter(u=>u.is_active).length,  color: 'text-slate-800' },
          ].map(s => (
            <div key={s.label} className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
              <p className="text-xs text-slate-400">{s.label}</p>
              <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Tab + Toolbar */}
        <div className="flex flex-wrap gap-3 items-center justify-between">
          <div className="flex bg-slate-100 rounded-2xl p-1 gap-1">
            {[
              { role: 'customer', label: 'Customers', icon: User,        color: 'text-success' },
              { role: 'auditor',  label: 'Auditors',  icon: ShieldCheck, color: 'text-purple-600' },
            ].map(({ role, label, icon: Icon, color }) => (
              <button key={role} onClick={() => setTab(role)}
                className={`flex items-center gap-2 px-5 py-2 rounded-xl text-sm font-semibold transition-all
                  ${tab === role ? 'bg-white shadow text-slate-800' : 'text-slate-400 hover:text-slate-600'}`}>
                <Icon size={15} className={tab === role ? color : ''} />
                {label}
              </button>
            ))}
          </div>
          <div className="flex gap-3">
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input className="input pl-9 w-52" placeholder="Search users..." value={search} onChange={e => setSearch(e.target.value)} />
            </div>
            <button onClick={openCreate} className="btn-success">
              <Plus size={16}/> Add {tab === 'customer' ? 'Customer' : 'Auditor'}
            </button>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
          {loading ? (
            <div className="p-6 space-y-3">{[...Array(5)].map((_, i) => <Skeleton key={i} className="h-12" />)}</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-slate-50 text-slate-400 text-xs border-b border-slate-100">
                  <th className="text-left px-5 py-3 font-medium">Name</th>
                  <th className="text-left px-5 py-3 font-medium">Email</th>
                  <th className="text-left px-5 py-3 font-medium">Role</th>
                  <th className="text-left px-5 py-3 font-medium">Joined</th>
                  <th className="text-left px-5 py-3 font-medium">Status</th>
                  <th className="text-left px-5 py-3 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {visible.map(u => (
                  <tr key={u.id} className="border-b border-slate-50 hover:bg-slate-50/60 transition-colors">
                    <td className="px-5 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary text-xs font-bold">
                          {u.name?.charAt(0)?.toUpperCase() || '?'}
                        </div>
                        <span className="font-semibold text-slate-800">{u.name}</span>
                      </div>
                    </td>
                    <td className="px-5 py-3 text-slate-500">{u.email}</td>
                    <td className="px-5 py-3"><span className={`badge ${ROLE_BADGE[u.role]}`}>{u.role}</span></td>
                    <td className="px-5 py-3 text-slate-500">{u.created_at ? new Date(u.created_at).toLocaleDateString('en-PK') : '—'}</td>
                    <td className="px-5 py-3">
                      <button onClick={() => handleToggle(u)}
                        className={`badge cursor-pointer ${u.is_active ? 'bg-success/10 text-success' : 'bg-slate-100 text-slate-400'}`}>
                        {u.is_active ? 'Active' : 'Inactive'}
                      </button>
                    </td>
                    <td className="px-5 py-3">
                      <div className="flex gap-2">
                        <button onClick={() => openEdit(u)} className="w-8 h-8 rounded-lg bg-primary/10 hover:bg-primary/20 flex items-center justify-center">
                          <Edit2 size={14} className="text-primary" />
                        </button>
                        <button onClick={() => setDeleteId(u.id)} className="w-8 h-8 rounded-lg bg-danger/10 hover:bg-danger/20 flex items-center justify-center">
                          <Trash2 size={14} className="text-danger" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {!visible.length && (
                  <tr><td colSpan={6} className="px-5 py-8 text-center text-slate-400 text-sm">No {tab}s found</td></tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Create / Edit Modal */}
      {mode && (
        <div className="modal-overlay" onClick={closeModal}>
          <div className="modal max-w-sm" onClick={e => e.stopPropagation()}>
            <div className="flex items-center justify-between px-6 pt-6 pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-800">
                  {mode === 'create' ? `Create ${form.role === 'auditor' ? 'Auditor' : 'Customer'}` : 'Edit User'}
                </h2>
                {mode === 'create' && (
                  <p className="text-xs text-slate-400 mt-0.5">Account will be usable in the mobile app immediately.</p>
                )}
              </div>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600"><X size={20}/></button>
            </div>
            <div className="px-6 py-5 space-y-4">
              <div>
                <label className="label">Full Name</label>
                <input className="input" placeholder="e.g. Ahmed Khan"
                  value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
              </div>
              <div>
                <label className="label">Email</label>
                <input type="email" placeholder="user@example.com"
                  className={`input ${mode === 'edit' ? 'bg-slate-50 text-slate-400' : ''}`}
                  value={form.email}
                  disabled={mode === 'edit'}
                  onChange={e => setForm(f => ({ ...f, email: e.target.value }))} />
              </div>
              {mode === 'create' && (
                <div>
                  <label className="label">Password</label>
                  <div className="relative">
                    <input className="input pr-10" type={showPw ? 'text' : 'password'}
                      placeholder="Min. 6 characters"
                      value={form.password}
                      onChange={e => setForm(f => ({ ...f, password: e.target.value }))} />
                    <button type="button" onClick={() => setShowPw(p => !p)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                      {showPw ? <EyeOff size={16}/> : <Eye size={16}/>}
                    </button>
                  </div>
                </div>
              )}
              {mode === 'create' && (
                <div>
                  <label className="label">Role</label>
                  <select className="input" value={form.role} onChange={e => setForm(f => ({ ...f, role: e.target.value }))}>
                    <option value="auditor">Auditor</option>
                    <option value="customer">Customer</option>
                  </select>
                </div>
              )}
            </div>
            <div className="px-6 pb-6 flex gap-3 justify-end">
              <button onClick={closeModal} className="btn-outline">Cancel</button>
              <button onClick={save} disabled={saving} className="btn-success disabled:opacity-60">
                {saving ? 'Saving…' : mode === 'create' ? 'Create Account' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteId && (
        <div className="modal-overlay" onClick={() => setDeleteId(null)}>
          <div className="modal max-w-sm" onClick={e => e.stopPropagation()}>
            <div className="p-6 text-center space-y-4">
              <div className="w-14 h-14 bg-danger/10 rounded-full flex items-center justify-center mx-auto">
                <Trash2 size={24} className="text-danger" />
              </div>
              <h3 className="font-bold text-slate-800 text-lg">Delete User?</h3>
              <p className="text-sm text-slate-500">This will permanently remove the user account.</p>
              <div className="flex gap-3 pt-2">
                <button onClick={() => setDeleteId(null)} className="btn-outline flex-1 justify-center">Cancel</button>
                <button onClick={handleDelete} className="flex-1 bg-danger text-white py-2 rounded-xl text-sm font-semibold hover:bg-red-700 transition-colors">Delete</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
