import { supabase } from './lib/supabase.js'
import { renderAuth } from './pages/auth.js'
import { renderFeed } from './pages/feed.js'
import { renderProfile } from './pages/profile.js'
import { renderFriends } from './pages/friends.js'
import { renderTimers } from './components/timer.js'
import { NotificationManager } from './components/notifications.js'

let currentUser = null
let currentCleanup = null
let notifManager = null

const app = document.getElementById('app')

const routes = {
  '/': renderFeed,
  '/profile': renderProfile,
  '/profile/:id': renderProfile,
  '/friends': renderFriends,
  '/timers': renderTimers,
}

function getRoute(path) {
  for (const [pattern, handler] of Object.entries(routes)) {
    const paramMatch = pattern.match(/^\/profile\/:id$/)
    if (paramMatch && path.match(/^\/profile\//)) {
      const id = path.replace('/profile/', '')
      return { handler, params: { id } }
    }
    if (pattern === path) {
      return { handler, params: {} }
    }
  }
  return { handler: renderFeed, params: {} }
}

async function navigate(path) {
  if (currentCleanup) {
    currentCleanup()
    currentCleanup = null
  }

  if (!currentUser) {
    app.innerHTML = ''
    currentCleanup = renderAuth(app, async (user) => {
      currentUser = user
      initNotifManager()
      navigate(window.location.hash.slice(1) || '/')
    })
    return
  }

  const hashPath = path || '/'
  const { handler, params } = getRoute(hashPath)
  app.innerHTML = '<div class="loading"><div class="spinner"></div></div>'

  const cleanup = await handler(app, currentUser, {
    navigate,
    params,
  })
  currentCleanup = cleanup

  updateNavActive(hashPath)
}

function updateNavActive(path) {
  document.querySelectorAll('.nav a').forEach(a => {
    const href = a.getAttribute('href').replace(/^#/, '')
    a.classList.toggle('active', href === path || (path.startsWith('/profile') && href === '/profile'))
  })
}

function renderNav() {
  const nav = document.createElement('nav')
  nav.className = 'nav'
  nav.innerHTML = `
    <a href="#/">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 12h2l2-5 3 10 3-10 2 5h2"/></svg>
      Feed
    </a>
    <a href="#/timers">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
      Timer
    </a>
    <a href="#/friends">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
      Friends
    </a>
    <a href="#/profile">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
      Profile
    </a>
  `
  return nav
}

function initNotifManager() {
  if (notifManager) return
  notifManager = new NotificationManager(currentUser.id, app)
}

window.addEventListener('hashchange', () => {
  navigate(window.location.hash.slice(1) || '/')
})

async function init() {
  const { data: { session } } = await supabase.auth.getSession()

  if (session?.user) {
    currentUser = session.user
    initNotifManager()
  }

  if (!document.querySelector('.nav')) {
    document.body.prepend(renderNav())
  }

  navigate(window.location.hash.slice(1) || '/')

  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN' && session?.user) {
      currentUser = session.user
      initNotifManager()
      navigate(window.location.hash.slice(1) || '/')
    } else if (event === 'SIGNED_OUT') {
      currentUser = null
      if (notifManager) {
        notifManager.destroy()
        notifManager = null
      }
      navigate('/login')
    }
  })
}

init()
