import { supabase } from '../lib/supabase.js'

export function renderAuth(container, onAuth) {
  let mode = 'login'
  let error = ''

  function render() {
    container.innerHTML = `
      <div class="auth-page">
        <div class="fade-in" style="text-align:center">
          <h1>🔥 Fasting Furious</h1>
          <p class="subtitle">train hard. fast harder.</p>
        </div>
        <form class="auth-form fade-in" id="auth-form">
          ${mode === 'signup' ? `
            <input type="text" id="username" placeholder="Username" required minlength="3" />
          ` : ''}
          <input type="email" id="email" placeholder="Email" required />
          <input type="password" id="password" placeholder="Password" required minlength="6" />
          ${error ? `<p class="error">${error}</p>` : ''}
          <button type="submit" class="btn btn-primary btn-block">
            ${mode === 'login' ? 'Sign In' : 'Create Account'}
          </button>
        </form>
        <div class="auth-toggle">
          ${mode === 'login'
            ? `Don't have an account? <a id="toggle-auth">Sign up</a>`
            : `Already have an account? <a id="toggle-auth">Sign in</a>`}
        </div>
      </div>
    `

    const form = document.getElementById('auth-form')
    const toggle = document.getElementById('toggle-auth')

    toggle?.addEventListener('click', (e) => {
      e.preventDefault()
      mode = mode === 'login' ? 'signup' : 'login'
      error = ''
      render()
    })

    form.addEventListener('submit', async (e) => {
      e.preventDefault()
      error = ''
      const email = document.getElementById('email').value
      const password = document.getElementById('password').value
      const username = document.getElementById('username')?.value

      const btn = form.querySelector('button[type="submit"]')
      btn.disabled = true
      btn.textContent = 'Loading...'

      try {
        if (mode === 'login') {
          const { data, error: authError } = await supabase.auth.signInWithPassword({ email, password })
          if (authError) throw authError
          if (data.user) onAuth(data.user)
        } else {
          if (!username || username.length < 3) {
            throw new Error('Username must be at least 3 characters')
          }
          const { data, error: authError } = await supabase.auth.signUp({
            email,
            password,
            options: {
              data: { username, display_name: username }
            }
          })
          if (authError) throw authError
          if (data.user?.identities?.length === 0) {
            throw new Error('An account with this email already exists')
          }
          error = 'Check your email for the confirmation link! (If you already have an account, sign in instead.)'
          mode = 'login'
          render()
        }
      } catch (err) {
        error = err.message
        render()
      }
    })
  }

  render()

  return () => {
    container.innerHTML = ''
  }
}
