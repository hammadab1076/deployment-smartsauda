import { useState, useEffect, useCallback } from 'react'
import { Save, Wifi, WifiOff, Printer, Bell, Shield, Store, Cpu } from 'lucide-react'
import Header from '../components/Header'
import { getScanners } from '../services/scanners'
import api from '../services/api'

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function Settings() {
  const [scanner, setScanner]     = useState(null)
  const [scanLoading, setScanLoad] = useState(true)
  const [saved, setSaved]         = useState('')
  const [pwForm, setPwForm]       = useState({ currentPassword:'', newPassword:'', confirmPassword:'' })
  const [pwError, setPwError]     = useState('')
  const [pwSaving, setPwSaving]   = useState(false)

  const [storeForm, setStoreForm] = useState({
    name: 'Smart Sauda', address: 'Main Market, Lahore, Pakistan',
    phone: '042-1234567', email: 'smartsauda537@gmail.com',
    currency: 'PKR', taxRate: '0',
  })
  const [notifs, setNotifs] = useState({
    lowStock: true, newOrder: true, scannerOffline: true, dailyReport: false,
  })

  const loadScanner = useCallback(async () => {
    try {
      const data = await getScanners()
      setScanner(data[0] || null)
    } catch {
      setScanner(null)
    } finally {
      setScanLoad(false)
    }
  }, [])

  useEffect(() => {
    loadScanner()
    // Poll scanner status every 10 seconds
    const interval = setInterval(loadScanner, 10000)
    return () => clearInterval(interval)
  }, [loadScanner])

  function handleSave(section) {
    setSaved(section)
    setTimeout(() => setSaved(''), 2000)
  }

  async function handleChangePassword(e) {
    e.preventDefault()
    setPwError('')
    if (pwForm.newPassword !== pwForm.confirmPassword) { setPwError('Passwords do not match'); return }
    if (pwForm.newPassword.length < 6) { setPwError('Password must be at least 6 characters'); return }
    setPwSaving(true)
    try {
      const user = JSON.parse(localStorage.getItem('pos_user') || '{}')
      await api.post('/auth/change-password', {
        email: user.email,
        currentPassword: pwForm.currentPassword,
        newPassword: pwForm.newPassword,
      })
      setPwForm({ currentPassword:'', newPassword:'', confirmPassword:'' })
      handleSave('security')
    } catch (err) {
      setPwError(err.response?.data?.error || 'Failed to change password.')
    } finally {
      setPwSaving(false)
    }
  }

  const online = scanner?.status === 'online'

  return (
    <div className="flex flex-col h-full">
      <Header title="Settings" subtitle="Configure store, hardware, and system preferences" />

      <div className="flex-1 overflow-y-auto p-8 space-y-6">

        {/* Live Scanner Status Banner */}
        {scanLoading ? <Skeleton className="h-12" /> : scanner ? (
          <div className={`border rounded-2xl px-5 py-3 flex items-center justify-between ${
            online ? 'bg-success/10 border-success/30' : 'bg-slate-100 border-slate-200'
          }`}>
            <div className="flex items-center gap-3">
              {online ? <Wifi size={18} className="text-success" /> : <WifiOff size={18} className="text-slate-400" />}
              <span className={`text-sm font-medium ${online ? 'text-green-800' : 'text-slate-500'}`}>
                <strong>{scanner.id}</strong> is <strong>{scanner.status}</strong> · {scanner.port}
                {scanner.pairedUser && <> · Paired with <strong>{scanner.pairedUser}</strong></>}
                {scanner.lastSeen && (
                  <span className="text-xs font-normal ml-2">
                    Last seen: {new Date(scanner.lastSeen).toLocaleTimeString('en-PK')}
                  </span>
                )}
              </span>
            </div>
            <button onClick={loadScanner} className="text-xs text-slate-400 hover:text-slate-600 underline">Refresh</button>
          </div>
        ) : (
          <div className="bg-slate-100 border border-slate-200 rounded-2xl px-5 py-3 flex items-center gap-3">
            <Cpu size={18} className="text-slate-400" />
            <span className="text-sm text-slate-500">No scanner found in database. Run the migration script first.</span>
          </div>
        )}

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">

          {/* Store Settings */}
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm">
            <div className="flex items-center gap-3 px-6 py-4 border-b border-slate-100">
              <div className="w-8 h-8 rounded-xl bg-primary/10 flex items-center justify-center"><Store size={16} className="text-primary" /></div>
              <h3 className="font-semibold text-slate-800">Store Information</h3>
            </div>
            <div className="px-6 py-5 space-y-4">
              <div><label className="label">Store Name</label><input className="input" value={storeForm.name} onChange={e=>setStoreForm(f=>({...f,name:e.target.value}))} /></div>
              <div><label className="label">Address</label><input className="input" value={storeForm.address} onChange={e=>setStoreForm(f=>({...f,address:e.target.value}))} /></div>
              <div className="grid grid-cols-2 gap-4">
                <div><label className="label">Phone</label><input className="input" value={storeForm.phone} onChange={e=>setStoreForm(f=>({...f,phone:e.target.value}))} /></div>
                <div><label className="label">Email</label><input className="input" value={storeForm.email} onChange={e=>setStoreForm(f=>({...f,email:e.target.value}))} /></div>
                <div>
                  <label className="label">Currency</label>
                  <select className="input" value={storeForm.currency} onChange={e=>setStoreForm(f=>({...f,currency:e.target.value}))}>
                    <option value="PKR">PKR — Pakistani Rupee</option>
                    <option value="USD">USD — US Dollar</option>
                  </select>
                </div>
                <div><label className="label">Tax Rate (%)</label><input className="input" type="number" min="0" max="100" value={storeForm.taxRate} onChange={e=>setStoreForm(f=>({...f,taxRate:e.target.value}))} /></div>
              </div>
              <div className="flex justify-end pt-1">
                <button onClick={()=>handleSave('store')} className="btn-success">
                  <Save size={15}/> {saved==='store' ? 'Saved!' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>

          {/* Scanner Config */}
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm">
            <div className="flex items-center gap-3 px-6 py-4 border-b border-slate-100">
              <div className="w-8 h-8 rounded-xl bg-purple-50 flex items-center justify-center"><Wifi size={16} className="text-purple-600" /></div>
              <h3 className="font-semibold text-slate-800">NFC Scanner / Hardware</h3>
            </div>
            <div className="px-6 py-5 space-y-4">
              {scanLoading ? <Skeleton className="h-32" /> : scanner ? (
                <div className="bg-slate-50 rounded-xl p-4 text-xs font-mono space-y-1.5 text-slate-600">
                  <p>Scanner ID: <span className="text-slate-800 font-semibold">{scanner.id}</span></p>
                  <p>Port: <span className="text-slate-800">{scanner.port}</span></p>
                  <p>Status: <span className={`font-bold ${online ? 'text-success' : 'text-slate-400'}`}>{scanner.status}</span></p>
                  {scanner.pairedCart && <p>Paired cart: {scanner.pairedCart}</p>}
                  {scanner.pairedUser && <p>Paired user: {scanner.pairedUser}</p>}
                  {scanner.lastSeen && <p>Last seen: {new Date(scanner.lastSeen).toLocaleString('en-PK')}</p>}
                </div>
              ) : (
                <p className="text-sm text-slate-400">Run <code className="bg-slate-100 px-1 rounded">migrate_pos.sql</code> to register the scanner.</p>
              )}
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 text-xs text-amber-700">
                Scanner port and baud rate are configured in <code>backend/serial_bridge.js</code>. Restart the bridge after any changes.
              </div>
            </div>
          </div>

          {/* Notifications */}
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm">
            <div className="flex items-center gap-3 px-6 py-4 border-b border-slate-100">
              <div className="w-8 h-8 rounded-xl bg-warning/10 flex items-center justify-center"><Bell size={16} className="text-warning" /></div>
              <h3 className="font-semibold text-slate-800">Notifications</h3>
            </div>
            <div className="px-6 py-5 space-y-4">
              {[
                { key:'lowStock',       label:'Low Stock Alerts',      desc:'Notify when product stock < 20 units' },
                { key:'newOrder',       label:'New Order Alerts',      desc:'Notify when a new order is placed' },
                { key:'scannerOffline', label:'Scanner Offline Alert', desc:'Notify when NFC scanner disconnects' },
                { key:'dailyReport',    label:'Daily Revenue Report',  desc:'Send daily summary at end of day' },
              ].map(n=>(
                <div key={n.key} className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-slate-700">{n.label}</p>
                    <p className="text-xs text-slate-400">{n.desc}</p>
                  </div>
                  <button onClick={()=>setNotifs(f=>({...f,[n.key]:!f[n.key]}))}
                    className={`w-11 h-6 rounded-full transition-colors relative ${notifs[n.key]?'bg-success':'bg-slate-200'}`}>
                    <span className={`absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-all ${notifs[n.key]?'left-5':'left-0.5'}`} />
                  </button>
                </div>
              ))}
              <div className="flex justify-end pt-1">
                <button onClick={()=>handleSave('notifs')} className="btn-success">
                  <Save size={15}/> {saved==='notifs' ? 'Saved!' : 'Save Changes'}
                </button>
              </div>
            </div>
          </div>

          {/* Security */}
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm">
            <div className="flex items-center gap-3 px-6 py-4 border-b border-slate-100">
              <div className="w-8 h-8 rounded-xl bg-danger/10 flex items-center justify-center"><Shield size={16} className="text-danger" /></div>
              <h3 className="font-semibold text-slate-800">Change Password</h3>
            </div>
            <form onSubmit={handleChangePassword} className="px-6 py-5 space-y-4">
              {pwError && <div className="bg-danger/10 border border-danger/20 rounded-xl px-3 py-2 text-xs text-danger">{pwError}</div>}
              {saved==='security' && <div className="bg-success/10 border border-success/20 rounded-xl px-3 py-2 text-xs text-success">Password updated successfully.</div>}
              <div><label className="label">Current Password</label><input className="input" type="password" placeholder="••••••••" value={pwForm.currentPassword} onChange={e=>setPwForm(f=>({...f,currentPassword:e.target.value}))} /></div>
              <div><label className="label">New Password</label><input className="input" type="password" placeholder="••••••••" value={pwForm.newPassword} onChange={e=>setPwForm(f=>({...f,newPassword:e.target.value}))} /></div>
              <div><label className="label">Confirm New Password</label><input className="input" type="password" placeholder="••••••••" value={pwForm.confirmPassword} onChange={e=>setPwForm(f=>({...f,confirmPassword:e.target.value}))} /></div>
              <div className="flex justify-end pt-1">
                <button type="submit" disabled={pwSaving} className="btn-success disabled:opacity-60">
                  <Save size={15}/> {pwSaving ? 'Updating…' : 'Update Password'}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* Printer placeholder */}
        <div className="bg-white rounded-2xl border border-slate-100 shadow-sm">
          <div className="flex items-center gap-3 px-6 py-4 border-b border-slate-100">
            <div className="w-8 h-8 rounded-xl bg-slate-100 flex items-center justify-center"><Printer size={16} className="text-slate-500" /></div>
            <h3 className="font-semibold text-slate-800">Receipt Printer</h3>
            <span className="badge bg-slate-100 text-slate-400 ml-auto">Not Configured</span>
          </div>
          <div className="px-6 py-5">
            <p className="text-sm text-slate-400">No thermal printer configured. Receipts will be generated as PDFs until a printer is connected.</p>
          </div>
        </div>
      </div>
    </div>
  )
}
