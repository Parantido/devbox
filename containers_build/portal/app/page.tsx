'use client'

import { useEffect, useState } from 'react'

interface UserInfo {
  user: string
  email: string
}

interface Workspace {
  name: string
  path: string
  description: string
}

// Workspaces configuration - can be made dynamic via API later
const WORKSPACES: Workspace[] = [
  {
    name: 'Danilo',
    path: '/code/danilo/',
    description: 'Personal development workspace',
  },
  {
    name: 'Dropinc',
    path: '/code/dropinc/',
    description: 'Dropinc project workspace',
  },
]

function GitHubIcon() {
  return (
    <svg className="github-icon" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
    </svg>
  )
}

function LogoutIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  )
}

function CodeIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <polyline points="16 18 22 12 16 6" />
      <polyline points="8 6 2 12 8 18" />
    </svg>
  )
}

export default function Home() {
  const [user, setUser] = useState<UserInfo | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    // Check if user is authenticated by calling the userinfo endpoint
    const checkAuth = async () => {
      try {
        const res = await fetch('/oauth2/userinfo', {
          credentials: 'include',
          headers: {
            'Accept': 'application/json',
          },
        })

        if (!res.ok) {
          // Not authenticated - this is expected for anonymous users
          setUser(null)
          setLoading(false)
          return
        }

        const contentType = res.headers.get('content-type')
        if (!contentType || !contentType.includes('application/json')) {
          // Response is not JSON - treat as not authenticated
          setUser(null)
          setLoading(false)
          return
        }

        const data = await res.json()
        setUser(data)
        setLoading(false)
      } catch (err) {
        // Network error or other issue - treat as not authenticated
        console.log('Auth check failed:', err)
        setUser(null)
        setLoading(false)
      }
    }

    checkAuth()
  }, [])

  const handleLogin = () => {
    // Redirect to OAuth2 Proxy login, then back to home
    window.location.href = `/oauth2/start?rd=${encodeURIComponent(window.location.href)}`
  }

  const handleLogout = () => {
    // Sign out and redirect to home
    window.location.href = `/oauth2/sign_out?rd=${encodeURIComponent(window.location.origin)}`
  }

  if (loading) {
    return (
      <>
        <header className="header">
          <h1>DevBox Portal</h1>
        </header>
        <main className="main">
          <div className="loading">
            <div className="spinner"></div>
          </div>
        </main>
      </>
    )
  }

  // Not logged in - show login page
  if (!user) {
    return (
      <>
        <header className="header">
          <h1>DevBox Portal</h1>
        </header>
        <div className="login-container">
          <div className="login-box">
            <div className="login-logo">
              <CodeIcon />
            </div>
            <h2>Welcome to DevBox</h2>
            <p>Your cloud development environment. Sign in with GitHub to access your workspaces.</p>
            {error && <div className="error-message">{error}</div>}
            <button className="btn github-btn" onClick={handleLogin}>
              <GitHubIcon />
              Sign in with GitHub
            </button>
            <div className="login-features">
              <div className="feature">
                <span className="feature-icon">&#9889;</span>
                <span>Instant access to VS Code</span>
              </div>
              <div className="feature">
                <span className="feature-icon">&#9729;</span>
                <span>Cloud-based workspaces</span>
              </div>
              <div className="feature">
                <span className="feature-icon">&#128274;</span>
                <span>Secure GitHub authentication</span>
              </div>
            </div>
          </div>
        </div>
        <footer className="footer">
          <p>Powered by Tech Fusion ITc</p>
        </footer>
      </>
    )
  }

  // Logged in - show dashboard
  return (
    <>
      <header className="header">
        <h1>DevBox Portal</h1>
        <div className="header-actions">
          <div className="user-info">
            <div className="user-avatar">{user.user.charAt(0).toUpperCase()}</div>
            <span className="user-name">{user.user}</span>
          </div>
          <button className="btn btn-danger" onClick={handleLogout}>
            <LogoutIcon />
            Sign Out
          </button>
        </div>
      </header>

      <main className="main">
        <section className="welcome-section">
          <h2>Welcome back, {user.user}!</h2>
          <p>Select a workspace to start coding</p>
        </section>

        <section className="workspaces-section">
          <div className="section-header">
            <h3>Your Workspaces</h3>
            <span className="status-badge online">All systems operational</span>
          </div>

          <div className="workspaces-grid">
            {WORKSPACES.map((workspace) => (
              <div key={workspace.path} className="workspace-card">
                <h4>{workspace.name}</h4>
                <p>{workspace.description}</p>
                <a href={workspace.path} className="btn btn-primary">
                  <CodeIcon />
                  Open Workspace
                </a>
              </div>
            ))}
          </div>
        </section>
      </main>

      <footer className="footer">
        <p>Powered by Tech Fusion ITc</p>
      </footer>
    </>
  )
}
