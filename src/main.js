import { supabase } from './lib/supabase.js'
import { renderAuth } from './pages/auth.js'
import { renderLanding } from './pages/landing.js'
import { renderNav } from './components/Navigation.js'
import { renderHome } from './screens/Home.js'
import { renderFeed } from './screens/Feed.js'
import { renderProfile } from './screens/Profile.js'
import { NotificationManager } from './components/notifications.js'
import { useStore } from './store/useStore.js'

let currentUser = null
let currentCleanup = null
let notifManager = null
let navEl = null

const app = document.getElementById('app')

const routes = {
  '/': renderHome,
  '/feed': renderFeed,
  '/profile': renderProfile,
}

function getRoute(path) {
  for (const [pattern, handler] of Object.entries(routes)) {
    if (pattern === path) return { handler, params: {} }
  }
  return { handler: renderHome, params: {} }
}

function showAuth() {
  if (currentCleanup) { currentCleanup(); currentCleanup = null }
  app.innerHTML = ''
  setNavVisible(false)
  currentCleanup = renderAuth(app, async (user) => {
    currentUser = user
    useStore.getState().setUser(user)
    await useStore.getState().fetchProfile(user.id)
    initNotifManager()
    navigate(window.location.hash.slice(1) || '/')
  })
}

async function navigate(path) {
  if (currentCleanup) { currentCleanup(); currentCleanup = null }

  if (!currentUser) {
    app.innerHTML = ''
    setNavVisible(false)
    currentCleanup = renderLanding(app, showAuth)
    return
  }

  setNavVisible(true)

  const hashPath = path || '/'
  const { handler, params } = getRoute(hashPath)
  app.innerHTML = '<div class="loading"><div class="spinner"></div></div>'

  const cleanup = await handler(app, currentUser, { navigate, params })
  currentCleanup = cleanup
}

function setNavVisible(visible) {
  if (navEl) navEl.style.display = visible ? '' : 'none'
}

function updateBottomNavActive(path) {
  if (!navEl) return
  const route = path || '/'
  navEl.querySelectorAll('a').forEach(a => {
    const href = a.getAttribute('href')
    a.classList.toggle('active', href === '#' + route)
  })
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
    useStore.getState().setUser(session.user)
    await useStore.getState().fetchProfile(session.user.id)
    initNotifManager()
  }

  // Create bottom nav (hidden until auth)
  navEl = document.createElement('div')
  navEl.id = 'nav-container'
  document.body.appendChild(navEl)
  renderNav(navEl, 'dashboard', (href) => {
    window.location.hash = href.replace(/^#/, '')
  })
  setNavVisible(false)

  navigate(window.location.hash.slice(1) || '/')

  supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN' && session?.user) {
      currentUser = session.user
      useStore.getState().setUser(session.user)
      useStore.getState().fetchProfile(session.user.id)
      initNotifManager()
      navigate(window.location.hash.slice(1) || '/')
    } else if (event === 'SIGNED_OUT') {
      currentUser = null
      useStore.getState().setUser(null)
      useStore.getState().setProfile(null)
      if (notifManager) { notifManager.destroy(); notifManager = null }
      setNavVisible(false)
      app.innerHTML = ''
      currentCleanup = renderLanding(app, showAuth)
    }
  })
}

init()
