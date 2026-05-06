import { Bell, Search } from 'lucide-react'

export default function Header({ title, subtitle }) {
  const now = new Date()
  const dateStr = now.toLocaleDateString('en-PK', { weekday:'long', year:'numeric', month:'long', day:'numeric' })

  return (
    <header className="bg-white border-b border-slate-100 px-8 py-4 flex items-center justify-between shrink-0">
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

        {/* Notifications */}
        <div className="relative cursor-pointer">
          <div className="w-9 h-9 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-center hover:bg-slate-100 transition-colors">
            <Bell size={16} className="text-slate-600" />
          </div>
          <span className="absolute -top-1 -right-1 w-4 h-4 bg-danger rounded-full text-white text-[10px] flex items-center justify-center font-bold">3</span>
        </div>
      </div>
    </header>
  )
}
