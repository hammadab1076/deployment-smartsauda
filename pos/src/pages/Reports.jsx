import { useState, useEffect, useCallback } from 'react'
import Header from '../components/Header'
import {
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts'
import { getDashboard } from '../services/dashboard'
import { getOrders } from '../services/orders'

const CHART_COLORS = ['#1A73E8','#00C853','#FF6D00','#AA00FF','#D32F2F']
const RADIAN = Math.PI / 180

function Skeleton({ className = '' }) {
  return <div className={`animate-pulse bg-slate-200 rounded-xl ${className}`} />
}

const renderLabel = ({ cx, cy, midAngle, innerRadius, outerRadius, percent }) => {
  if (percent < 0.06) return null
  const r = innerRadius + (outerRadius - innerRadius) * 0.5
  const x = cx + r * Math.cos(-midAngle * RADIAN)
  const y = cy + r * Math.sin(-midAngle * RADIAN)
  return (
    <text x={x} y={y} fill="white" textAnchor="middle" dominantBaseline="central" fontSize={11} fontWeight={600}>
      {`${(percent * 100).toFixed(0)}%`}
    </text>
  )
}

export default function Reports() {
  const [dash, setDash]       = useState(null)
  const [orders, setOrders]   = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState('')

  const load = useCallback(async () => {
    try {
      const [d, o] = await Promise.all([getDashboard(), getOrders()])
      setDash(d)
      setOrders(o)
      setError('')
    } catch {
      setError('Failed to load report data.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { load() }, [load])

  const completed     = orders.filter(o => o.status === 'completed')
  const totalRevenue  = completed.reduce((s, o) => s + Number(o.total_amount || 0), 0)
  const avgOrder      = completed.length ? Math.round(totalRevenue / completed.length) : 0
  const refundRate    = orders.length ? ((orders.filter(o => o.status === 'refunded').length / orders.length) * 100).toFixed(1) : '0.0'

  return (
    <div className="flex flex-col h-full">
      <Header title="Reports" subtitle="Analytics and business performance overview" />

      <div className="flex-1 overflow-y-auto p-8 space-y-6">

        {error && <div className="bg-danger/10 border border-danger/20 rounded-xl px-4 py-3 text-sm text-danger">{error}</div>}

        {/* KPI row */}
        <div className="grid grid-cols-4 gap-4">
          {[
            { label:'Total Revenue',      value: loading ? '—' : `Rs. ${totalRevenue.toLocaleString()}`,  color:'text-primary' },
            { label:'Completed Orders',   value: loading ? '—' : completed.length,                        color:'text-success' },
            { label:'Avg Order Value',    value: loading ? '—' : `Rs. ${avgOrder.toLocaleString()}`,      color:'text-slate-800' },
            { label:'Refund Rate',        value: loading ? '—' : `${refundRate}%`,                        color:'text-danger' },
          ].map(s => (
            <div key={s.label} className="bg-white rounded-xl p-4 border border-slate-100 shadow-sm">
              <p className="text-xs text-slate-400">{s.label}</p>
              <p className={`text-2xl font-bold mt-1 ${s.color}`}>{s.value}</p>
            </div>
          ))}
        </div>

        {/* Weekly + Top Products */}
        <div className="grid grid-cols-1 xl:grid-cols-2 gap-5">
          <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-100">
            <h3 className="font-semibold text-slate-800 mb-1">Weekly Revenue</h3>
            <p className="text-xs text-slate-400 mb-4">Last 7 days</p>
            {loading ? <Skeleton className="h-[220px]" /> : (
              <ResponsiveContainer width="100%" height={220}>
                <LineChart data={dash?.weeklyRevenue || []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                  <XAxis dataKey="day" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip formatter={v => [`Rs. ${v}`, 'Revenue']} />
                  <Line type="monotone" dataKey="revenue" stroke="#1A73E8" strokeWidth={2.5} dot={{ r: 4 }} activeDot={{ r: 6 }} />
                </LineChart>
              </ResponsiveContainer>
            )}
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-sm border border-slate-100">
            <h3 className="font-semibold text-slate-800 mb-1">Top Products</h3>
            <p className="text-xs text-slate-400 mb-4">By units sold</p>
            {loading ? <Skeleton className="h-[220px]" /> : (
              <ResponsiveContainer width="100%" height={220}>
                <BarChart data={dash?.topProducts || []} layout="vertical">
                  <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                  <XAxis type="number" tick={{ fontSize: 11 }} />
                  <YAxis type="category" dataKey="name" tick={{ fontSize: 11 }} width={120} />
                  <Tooltip />
                  <Bar dataKey="sales" fill="#00C853" radius={[0, 6, 6, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        {/* Category Pie */}
        {(dash?.salesByCategory?.length > 0) && (
          <div className="grid grid-cols-1 xl:grid-cols-5 gap-5">
            <div className="xl:col-span-2 bg-white rounded-2xl p-5 shadow-sm border border-slate-100">
              <h3 className="font-semibold text-slate-800 mb-1">Sales by Category</h3>
              <p className="text-xs text-slate-400 mb-4">Revenue share</p>
              <ResponsiveContainer width="100%" height={240}>
                <PieChart>
                  <Pie data={dash.salesByCategory} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={95} labelLine={false} label={renderLabel}>
                    {dash.salesByCategory.map((_, i) => <Cell key={i} fill={CHART_COLORS[i % CHART_COLORS.length]} />)}
                  </Pie>
                  <Tooltip formatter={v => [v, 'Orders']} />
                  <Legend iconType="circle" iconSize={10} />
                </PieChart>
              </ResponsiveContainer>
            </div>

            {/* Orders summary */}
            <div className="xl:col-span-3 bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
              <div className="px-5 py-4 border-b border-slate-100">
                <h3 className="font-semibold text-slate-800">Recent Orders</h3>
                <p className="text-xs text-slate-400 mt-0.5">Latest transactions</p>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-slate-50 text-slate-400 text-xs border-b border-slate-100">
                      <th className="text-left px-5 py-3 font-medium">Order ID</th>
                      <th className="text-left px-5 py-3 font-medium">Date</th>
                      <th className="text-left px-5 py-3 font-medium">Total</th>
                      <th className="text-left px-5 py-3 font-medium">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {orders.slice(0, 8).map(o => (
                      <tr key={o.id} className="border-b border-slate-50 hover:bg-slate-50 transition-colors">
                        <td className="px-5 py-2.5 font-mono text-xs text-slate-500">{o.id?.slice(0, 10)}…</td>
                        <td className="px-5 py-2.5 text-slate-500 text-xs">{o.created_at ? new Date(o.created_at).toLocaleDateString('en-PK') : '—'}</td>
                        <td className="px-5 py-2.5 font-semibold text-slate-800">Rs. {Number(o.total_amount || 0).toLocaleString()}</td>
                        <td className="px-5 py-2.5">
                          <span className={`badge ${o.status === 'completed' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>{o.status}</span>
                        </td>
                      </tr>
                    ))}
                    {!orders.length && (
                      <tr><td colSpan={4} className="px-5 py-6 text-center text-slate-400 text-sm">No orders yet</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* Fallback if no category data */}
        {!loading && !dash?.salesByCategory?.length && (
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
            <div className="px-5 py-4 border-b border-slate-100">
              <h3 className="font-semibold text-slate-800">All Orders</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-slate-50 text-slate-400 text-xs border-b border-slate-100">
                    <th className="text-left px-5 py-3 font-medium">Order ID</th>
                    <th className="text-left px-5 py-3 font-medium">Date</th>
                    <th className="text-left px-5 py-3 font-medium">Total</th>
                    <th className="text-left px-5 py-3 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {orders.map(o => (
                    <tr key={o.id} className="border-b border-slate-50 hover:bg-slate-50 transition-colors">
                      <td className="px-5 py-3 font-mono text-xs text-slate-500">{o.id?.slice(0, 12)}…</td>
                      <td className="px-5 py-3 text-slate-500">{o.created_at ? new Date(o.created_at).toLocaleDateString('en-PK') : '—'}</td>
                      <td className="px-5 py-3 font-semibold text-slate-800">Rs. {Number(o.total_amount || 0).toLocaleString()}</td>
                      <td className="px-5 py-3">
                        <span className={`badge ${o.status === 'completed' ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>{o.status}</span>
                      </td>
                    </tr>
                  ))}
                  {!orders.length && (
                    <tr><td colSpan={4} className="px-5 py-8 text-center text-slate-400 text-sm">No orders yet</td></tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
