import { useState, useEffect, useCallback } from 'react'
import { TrendingUp, ShoppingCart, Users, Package, ArrowUpRight, Wifi, WifiOff, RefreshCw } from 'lucide-react'
import {
  LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer,
} from 'recharts'
import Header from '../components/Header'
import { getDashboard } from '../services/dashboard'

function StatCard({ icon: Icon, label, value, sub, color }) {
  return (
    <div className="stat-card flex items-start justify-between">
      <div>
        <p className="text-sm text-slate-500 font-medium">{label}</p>
        <p className="text-2xl font-bold text-slate-800 mt-1">{value}</p>
        {sub && <p className="text-xs text-slate-400 mt-1">{sub}</p>}
      </div>
      <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${color}`}>
        <Icon size={20} className="text-white" />
      </div>
    </div>
  )
}

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

export default function Dashboard() {
  const [data, setData]       = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState('')

  const load = useCallback(async () => {
    try {
      const d = await getDashboard()
      setData(d)
      setError('')
    } catch {
      setError('Failed to load dashboard data.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
    // Poll every 30 seconds for real-time updates
    const interval = setInterval(load, 30000)
    return () => clearInterval(interval)
  }, [load])

  const scanner = data?.scanner

  return (
    <div className="flex flex-col h-full">
      <Header title="Dashboard" subtitle="Welcome back — here's what's happening today" />

      <div className="flex-1 overflow-y-auto p-8 space-y-6">

        {/* Scanner Status Banner */}
        {scanner ? (
          <div className={`border rounded-2xl px-5 py-3 ${
            scanner.status === 'online'
              ? 'bg-success/10 border-success/30'
              : scanner.pairedCarts?.length > 0
                ? 'bg-blue-50 border-blue-200'
                : 'bg-slate-100 border-slate-200'
          }`}>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                {scanner.status === 'online'
                  ? <Wifi size={18} className="text-success" />
                  : <WifiOff size={18} className={scanner.pairedCarts?.length > 0 ? 'text-blue-400' : 'text-slate-400'} />}
                <span className={`text-sm font-medium ${
                  scanner.status === 'online'
                    ? 'text-green-800'
                    : scanner.pairedCarts?.length > 0
                      ? 'text-blue-700'
                      : 'text-slate-500'
                }`}>
                  <strong>{scanner.id}</strong> · {scanner.port} ·{' '}
                  <strong>{scanner.status}</strong>
                  {scanner.pairedCarts?.length > 0 && (
                    <> · {scanner.pairedCarts.length} paired customer{scanner.pairedCarts.length > 1 ? 's' : ''}</>
                  )}
                </span>
              </div>
              <button onClick={load} className="text-slate-400 hover:text-slate-600 transition-colors">
                <RefreshCw size={14} />
              </button>
            </div>
            {scanner.pairedCarts?.length > 0 && (
              <div className="flex flex-wrap gap-2 mt-2 ml-7">
                {scanner.pairedCarts.map(c => (
                  <span key={c.cartId} className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                    scanner.status === 'online'
                      ? 'bg-success/20 text-green-800'
                      : 'bg-blue-100 text-blue-700'
                  }`}>
                    {c.customer}
                  </span>
                ))}
              </div>
            )}
          </div>
        ) : !loading && (
          <div className="bg-slate-100 border border-slate-200 rounded-2xl px-5 py-3 flex items-center gap-3">
            <WifiOff size={18} className="text-slate-400" />
            <span className="text-sm text-slate-500">No scanner configured</span>
          </div>
        )}

        {/* Active Shopping Sessions */}
        {!loading && data?.activeSessions?.length > 0 && (
          <div className="bg-white rounded-2xl shadow-sm border border-slate-100">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
              <div>
                <h3 className="font-semibold text-slate-800">Active Sessions</h3>
                <p className="text-xs text-slate-400">{data.activeSessions.length} customer{data.activeSessions.length > 1 ? 's' : ''} currently shopping</p>
              </div>
              <span className="w-2.5 h-2.5 bg-success rounded-full animate-pulse" />
            </div>
            <div className="divide-y divide-slate-50">
              {data.activeSessions.map(s => (
                <div key={s.cartId} className="flex items-center justify-between px-6 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-success/10 flex items-center justify-center">
                      <Users size={14} className="text-success" />
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-slate-800">{s.customer}</p>
                      <p className="text-xs text-slate-400 font-mono">{s.cartId}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-slate-600">{s.itemCount} item{s.itemCount !== 1 ? 's' : ''}</p>
                    <p className="text-xs text-slate-400">{s.scannerId || 'No scanner'}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {error && (
          <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger">{error}</div>
        )}

        {/* Stat Cards */}
        {loading ? (
          <div className="grid grid-cols-2 xl:grid-cols-4 gap-5">
            {[...Array(4)].map((_, i) => <Skeleton key={i} className="h-28" />)}
          </div>
        ) : (
          <div className="grid grid-cols-2 xl:grid-cols-4 gap-5">
            <StatCard icon={TrendingUp}  label="Today's Revenue"   value={`Rs. ${(data?.todayRevenue||0).toLocaleString()}`}  sub="Live from orders"      color="bg-primary" />
            <StatCard icon={ShoppingCart} label="Orders Today"      value={data?.todayOrders ?? 0}                              sub="All statuses"          color="bg-success" />
            <StatCard icon={Users}        label="Active Customers"  value={data?.activeUsers ?? 0}                              sub="Registered & active"   color="bg-[#AA00FF]" />
            <StatCard icon={Package}      label="Total Products"    value={data?.totalProducts ?? 0}                            sub={`${data?.lowStock||0} low stock`} color="bg-warning" />
          </div>
        )}

        {/* Charts Row */}
        <div className="grid grid-cols-1 xl:grid-cols-5 gap-5">
          <div className="xl:col-span-3 bg-white rounded-2xl p-5 shadow-sm border border-slate-100">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="font-semibold text-slate-800">Weekly Revenue</h3>
                <p className="text-xs text-slate-400">Last 7 days</p>
              </div>
              {data?.weeklyRevenue && (
                <span className="badge bg-success/10 text-success">
                  Rs. {data.weeklyRevenue.reduce((s,d)=>s+d.revenue,0).toLocaleString()}
                </span>
              )}
            </div>
            {loading ? <Skeleton className="h-[220px]" /> : (
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={data?.weeklyRevenue || []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                  <XAxis dataKey="day" tick={{ fontSize:12 }} />
                  <YAxis tick={{ fontSize:12 }} />
                  <Tooltip formatter={v => [`Rs. ${v}`, 'Revenue']} />
                  <Line type="monotone" dataKey="revenue" stroke="#1A73E8" strokeWidth={2.5} dot={{ r:4 }} activeDot={{ r:6 }} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>

          <div className="xl:col-span-2 bg-white rounded-2xl p-5 shadow-sm border border-slate-100">
            <div className="mb-4">
              <h3 className="font-semibold text-slate-800">Top Products</h3>
              <p className="text-xs text-slate-400">By units sold</p>
            </div>
            {loading ? <Skeleton className="h-[220px]" /> : (
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={data?.topProducts || []} layout="vertical">
                  <XAxis type="number" tick={{ fontSize:11 }} />
                  <YAxis type="category" dataKey="name" tick={{ fontSize:11 }} width={110} />
                  <Tooltip />
                  <Bar dataKey="sales" fill="#00C853" radius={[0,6,6,0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Recent Orders */}
        <div className="bg-white rounded-2xl shadow-sm border border-slate-100">
          <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <h3 className="font-semibold text-slate-800">Recent Orders</h3>
            <button onClick={load} className="text-sm text-primary font-medium flex items-center gap-1 hover:underline">
              Refresh <ArrowUpRight size={14} />
            </button>
          </div>
          <div className="overflow-x-auto">
            {loading ? (
              <div className="p-6 space-y-3">{[...Array(5)].map((_,i)=><Skeleton key={i} className="h-10" />)}</div>
            ) : (
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-slate-400 text-xs border-b border-slate-50">
                    <th className="text-left px-6 py-3 font-medium">Order ID</th>
                    <th className="text-left px-6 py-3 font-medium">Customer</th>
                    <th className="text-left px-6 py-3 font-medium">Date</th>
                    <th className="text-left px-6 py-3 font-medium">Items</th>
                    <th className="text-left px-6 py-3 font-medium">Total</th>
                    <th className="text-left px-6 py-3 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {(data?.recentOrders || []).map(o => (
                    <tr key={o.id} className="border-b border-slate-50 hover:bg-slate-50 transition-colors">
                      <td className="px-6 py-3 font-mono text-xs text-slate-500">{o.id?.slice(0,12)}…</td>
                      <td className="px-6 py-3 font-medium text-slate-700">{o.customer}</td>
                      <td className="px-6 py-3 text-slate-500">{o.date}</td>
                      <td className="px-6 py-3 text-slate-500">{o.items} items</td>
                      <td className="px-6 py-3 font-semibold text-slate-800">Rs. {o.total?.toLocaleString()}</td>
                      <td className="px-6 py-3">
                        <span className={`badge ${o.status === 'completed' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>
                          {o.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                  {!data?.recentOrders?.length && (
                    <tr><td colSpan={6} className="px-6 py-8 text-center text-slate-400 text-sm">No orders yet</td></tr>
                  )}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
