import { useState, useEffect, useRef, useCallback } from 'react'
import { Bell, Search, ShoppingCart, AlertTriangle, AlertCircle, UserPlus, ClipboardX, X, CheckCheck } from 'lucide-react'
import { getNotifications } from '../services/notifications'

// ── Notification type config ─────────────────────────────────────────────────
const TYPE_CONFIG = {
  order:         { icon: ShoppingCart, bg: 'bg-blue-50',   ring: 'ring-blue-200',   icon_cls: 'text-blue-500',   dot: 'bg-blue-500'   },
  low_stock:     { icon: AlertTriangle, bg: 'bg-amber-50',  ring: 'ring-amber-200',  icon_cls: 'text-amber-500',  dot: 'bg-amber-500'  },
  out_of_stock:  { icon: AlertCircle,   bg: 'bg-red-50',    ring: 'ring-red-200',    icon_cls: 'text-red-500',    dot: 'bg-red-500'    },
  flagged_audit: { icon: ClipboardX,    bg: 'bg-purple-50', ring: 'ring-purple-200', icon_cls: 'text-purple-500', dot: 'bg-purple-500' },
  new_user:      { icon: UserPlus,      bg: 'bg-green-50',  ring: 'ring-green-200',  icon_cls: 'text-green-500',  dot: 'bg-green-500'  },
}

function timeAgo(isoStr) {
  if (!isoStr) return null
  const diff = (Date.now() - new Date(isoStr).getTime()) / 1000
  if (diff < 60)   return 'just now'
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`
  return `${Math.floor(diff / 86400)}d ago`
}

// ── Single notification row ───────────────────────────────────────────────────
function NotifRow({ notif, isRead, onRead }) {
  const cfg   = TYPE_CONFIG[notif.type] ?? TYPE_CONFIG.order
  const Icon  = cfg.icon
  const ago   = timeAgo(notif.time)

  return (
    <div
      onClick={() => onRead(notif.id)}
      className={`flex items-start gap-3 px-4 py-3 cursor-pointer transition-colors rounded-xl
                  ${isRead ? 'opacity-60 hover:bg-slate-50' : 'hover:bg-slate-50'}`}
    >
      {/* Icon bubble */}
      <div className={`shrink-0 w-9 h-9 rounded-xl flex items-center justify-center ring-1 ${cfg.bg} ${cfg.ring}`}>
        <Icon size={16} className={cfg.icon_cls} />
      </div>

      {/* Text */}
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <p className={`text-sm font-semibold text-slate-800 leading-tight ${isRead ? '' : ''}`}>
            {notif.title}
          </p>
          {!isRead && <span className={`shrink-0 w-2 h-2 rounded-full ${cfg.dot}`} />}
        </div>
        <p className="text-xs text-slate-500 mt-0.5 leading-relaxed line-clamp-2">{notif.message}</p>
        {ago && <p className="text-[11px] text-slate-400 mt-1">{ago}</p>}
      </div>
    </div>
  )
}

// ── Main Header ───────────────────────────────────────────────────────────────
export default function Header({ title, subtitle }) {
  const now     = new Date()
  const dateStr = now.toLocaleDateString('en-PK', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })

  const [open, setOpen]           = useState(false)
  const [notifs, setNotifs]       = useState([])
  const [readIds, setReadIds]     = useState(() => {
    try { return new Set(JSON.parse(localStorage.getItem('pos_read_notifs') || '[]')) }
    catch { return new Set() }
  })
  const [loading, setLoading]     = useState(false)
  const [error, setError]         = useState(false)
  const panelRef                  = useRef(null)

  // ── Fetch notifications ───────────────────────────────────────────────────
  const fetchNotifs = useCallback(async () => {
    setLoading(true)
    setError(false)
    try {
      const data = await getNotifications()
      setNotifs(data)
    } catch {
      setError(true)
    } finally {
      setLoading(false)
    }
  }, [])

  // Fetch on mount + poll every 60 seconds
  useEffect(() => {
    fetchNotifs()
    const interval = setInterval(fetchNotifs, 60000)
    return () => clearInterval(interval)
  }, [fetchNotifs])

  // Close panel on outside click
  useEffect(() => {
    if (!open) return
    const handler = (e) => {
      if (panelRef.current && !panelRef.current.contains(e.target)) setOpen(false)
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [open])

  // ── Badge count: unread ───────────────────────────────────────────────────
  const unreadCount = notifs.filter(n => !readIds.has(n.id)).length

  // ── Mark single as read ───────────────────────────────────────────────────
  const markRead = (id) => {
    setReadIds(prev => {
      const next = new Set(prev)
      next.add(id)
      localStorage.setItem('pos_read_notifs', JSON.stringify([...next]))
      return next
    })
  }

  // ── Mark all as read ─────────────────────────────────────────────────────
  const markAllRead = () => {
    const all = new Set(notifs.map(n => n.id))
    setReadIds(all)
    localStorage.setItem('pos_read_notifs', JSON.stringify([...all]))
  }

  return (
    <header className="bg-white border-b border-slate-100 px-8 py-4 flex items-center justify-between shrink-0 relative z-50">
      <div>
        <h1 className="text-xl font-bold text-slate-800">{title}</h1>
        {subtitle && <p className="text-sm text-slate-500 mt-0.5">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-4">
        {/* Search */}
        <div className="relative hidden md:flex items-center">
          <Search size={15} className="absolute left-3 text-slate-400 pointer-events-none" />
          <input
            type="text"
            placeholder="Quick search..."
            style={{ paddingLeft: '2rem' }}
            className="pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm w-56
                       focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary"
          />
        </div>

        {/* Date */}
        <span className="text-xs text-slate-400 hidden lg:block">{dateStr}</span>

        {/* ── Notifications bell ──────────────────────────────────────────── */}
        <div className="relative" ref={panelRef}>
          {/* Bell button */}
          <button
            onClick={() => { setOpen(o => !o); if (!open) fetchNotifs() }}
            className="relative w-9 h-9 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-center hover:bg-slate-100 transition-colors"
          >
            <Bell size={16} className={`transition-colors ${unreadCount > 0 ? 'text-primary' : 'text-slate-600'}`} />
            {unreadCount > 0 && (
              <span className="absolute -top-1.5 -right-1.5 min-w-[18px] h-[18px] px-1 bg-red-500 rounded-full text-white text-[10px] flex items-center justify-center font-bold leading-none">
                {unreadCount > 99 ? '99+' : unreadCount}
              </span>
            )}
          </button>

          {/* ── Dropdown panel ─────────────────────────────────────────────── */}
          {open && (
            <div className="absolute right-0 top-12 w-[380px] bg-white border border-slate-200 rounded-2xl shadow-xl overflow-hidden">

              {/* Panel header */}
              <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100 bg-slate-50">
                <div className="flex items-center gap-2">
                  <Bell size={15} className="text-slate-500" />
                  <span className="text-sm font-bold text-slate-800">Notifications</span>
                  {unreadCount > 0 && (
                    <span className="px-2 py-0.5 bg-red-500 text-white text-[10px] font-bold rounded-full">
                      {unreadCount} new
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-2">
                  {unreadCount > 0 && (
                    <button
                      onClick={markAllRead}
                      className="flex items-center gap-1 text-xs text-primary font-medium hover:underline"
                    >
                      <CheckCheck size={12} />
                      Mark all read
                    </button>
                  )}
                  <button onClick={() => setOpen(false)} className="text-slate-400 hover:text-slate-600 transition-colors">
                    <X size={15} />
                  </button>
                </div>
              </div>

              {/* Panel body */}
              <div className="max-h-[420px] overflow-y-auto divide-y divide-slate-50 py-1">
                {loading && (
                  <div className="flex items-center justify-center py-10">
                    <div className="w-5 h-5 border-2 border-primary border-t-transparent rounded-full animate-spin" />
                  </div>
                )}

                {error && !loading && (
                  <div className="flex flex-col items-center justify-center py-10 gap-2">
                    <AlertCircle size={28} className="text-slate-300" />
                    <p className="text-sm text-slate-400">Could not load notifications</p>
                    <button onClick={fetchNotifs} className="text-xs text-primary hover:underline">Retry</button>
                  </div>
                )}

                {!loading && !error && notifs.length === 0 && (
                  <div className="flex flex-col items-center justify-center py-10 gap-2">
                    <Bell size={28} className="text-slate-200" />
                    <p className="text-sm text-slate-400">You're all caught up!</p>
                  </div>
                )}

                {!loading && !error && notifs.map(n => (
                  <NotifRow
                    key={n.id}
                    notif={n}
                    isRead={readIds.has(n.id)}
                    onRead={markRead}
                  />
                ))}
              </div>

              {/* Panel footer */}
              {notifs.length > 0 && (
                <div className="px-4 py-2.5 border-t border-slate-100 bg-slate-50 text-center">
                  <p className="text-xs text-slate-400">{notifs.length} total alert{notifs.length !== 1 ? 's' : ''}</p>
                </div>
              )}
            </div>
          )}
        </div>
        {/* ── End notifications ──────────────────────────────────────────── */}
      </div>
    </header>
  )
}
