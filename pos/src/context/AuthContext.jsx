import { createContext, useContext, useState, useCallback } from 'react'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser]   = useState(() => {
    try { return JSON.parse(localStorage.getItem('pos_user')) } catch { return null }
  })
  const [token, setToken] = useState(() => localStorage.getItem('pos_token') || null)

  const login = useCallback((tokenVal, userVal) => {
    localStorage.setItem('pos_token', tokenVal)
    localStorage.setItem('pos_user',  JSON.stringify(userVal))
    setToken(tokenVal)
    setUser(userVal)
  }, [])

  const logout = useCallback(() => {
    localStorage.removeItem('pos_token')
    localStorage.removeItem('pos_user')
    setToken(null)
    setUser(null)
  }, [])

  return (
    <AuthContext.Provider value={{ user, token, login, logout, isLoggedIn: !!token }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
