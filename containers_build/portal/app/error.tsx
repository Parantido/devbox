'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error('Portal error:', error)
  }, [error])

  const handleLogin = () => {
    window.location.href = `/oauth2/start?rd=${encodeURIComponent(window.location.origin)}`
  }

  return (
    <>
      <header className="header">
        <h1>DevBox Portal</h1>
      </header>
      <div className="login-container">
        <div className="login-box">
          <h2>Something went wrong</h2>
          <p>There was an error loading the portal. Please try signing in again.</p>
          <button className="btn github-btn" onClick={handleLogin}>
            Sign in with GitHub
          </button>
          <button
            className="btn btn-secondary"
            style={{ marginTop: '1rem', width: '100%', justifyContent: 'center' }}
            onClick={() => reset()}
          >
            Try again
          </button>
        </div>
      </div>
      <footer className="footer">
        <p>Powered by Tech Fusion ITc</p>
      </footer>
    </>
  )
}
