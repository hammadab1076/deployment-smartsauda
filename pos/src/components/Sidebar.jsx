import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard, Package, ShoppingCart, Users, BookUser,
  ShoppingBag, BarChart3, Settings, LogOut,
} from 'lucide-react'
import { useAuth } from '../context/AuthContext'

const nav = [
  { to: '/',            icon: LayoutDashboard, label: 'Dashboard'        },
  { to: '/products',    icon: Package,          label: 'Products'         },
  { to: '/sales',       icon: ShoppingCart,     label: 'Sales'            },
  { to: '/users',       icon: Users,            label: 'User Management'  },
  { to: '/contacts',    icon: BookUser,         label: 'Contacts'         },
  { to: '/purchase',    icon: ShoppingBag,      label: 'Purchase'         },
  { to: '/reports',     icon: BarChart3,        label: 'Reports'          },
  { to: '/settings',    icon: Settings,         label: 'Settings'         },
]

export default function Sidebar() {
  const { logout, user } = useAuth()
  const navigate = useNavigate()

  function handleLogout() {
    logout()
    navigate('/login', { replace: true })
  }

  return (
    <aside className="w-64 min-h-screen bg-sidebar flex flex-col shrink-0">
      {/* Logo */}
      <div className="flex items-center gap-3 px-6 py-6 border-b border-white/10">
        {/* Green container → white inner box → green cart — mirrors the app icon */}
        <div className="w-10 h-10 bg-success rounded-xl flex items-center justify-center shrink-0">
          <div className="w-6 h-6 bg-white rounded-md flex items-center justify-center">
            <ShoppingCart size={14} className="text-success" strokeWidth={2.5} />
          </div>
        </div>
        <div>
          <p className="text-white font-bold text-base leading-tight">Smart Sauda</p>
          <p className="text-slate-400 text-xs">POS Terminal</p>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1">
        {nav.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `sidebar-link ${isActive ? 'active' : ''}`
            }
          >
            <Icon size={18} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Bottom user */}
      <div className="px-3 py-4 border-t border-white/10">
        <div className="flex items-center gap-3 px-4 py-3">
          <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center text-white text-xs font-bold">
            {user?.name?.charAt(0)?.toUpperCase() || 'A'}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-white text-sm font-medium truncate">{user?.name || 'Admin'}</p>
            <p className="text-slate-400 text-xs truncate">{user?.email || ''}</p>
          </div>
          <LogOut size={16} onClick={handleLogout} className="text-slate-400 hover:text-white cursor-pointer shrink-0" />
        </div>
      </div>
    </aside>
  )
}
