import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Sidebar from './components/Sidebar'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Products from './pages/Products'
import Sales from './pages/Sales'
import UserManagement from './pages/UserManagement'
import Contacts from './pages/Contacts'
import Purchase from './pages/Purchase'
import Reports from './pages/Reports'
import Settings from './pages/Settings'

function Layout() {
  return (
    <div className="flex h-screen overflow-hidden bg-slate-50">
      <Sidebar />
      <main className="flex-1 overflow-hidden flex flex-col">
        <Routes>
          <Route path="/"          element={<Dashboard />} />
          <Route path="/products"  element={<Products />} />
          <Route path="/sales"     element={<Sales />} />
          <Route path="/users"     element={<UserManagement />} />
          <Route path="/contacts"  element={<Contacts />} />
          <Route path="/purchase"  element={<Purchase />} />
          <Route path="/reports"   element={<Reports />} />
          <Route path="/settings"  element={<Settings />} />
        </Routes>
      </main>
    </div>
  )
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/*" element={
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          } />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  )
}
