export function renderNav(container, currentRoute, onNavigate) {
  const links = [
    { id: 'dashboard', href: '#/', icon: 'dashboard', label: 'Dashboard' },
    { id: 'feed', href: '#/feed', icon: 'feed', label: 'Feed' },
    { id: 'friends', href: '#/friends', icon: 'friends', label: 'Friends' },
    { id: 'profile', href: '#/profile', icon: 'profile', label: 'Profile' },
  ]

  const nav = document.createElement('nav')
  nav.className = 'bottom-nav'
  nav.innerHTML = links.map(link => `
    <a href="${link.href}" class="${currentRoute === link.id ? 'active' : ''}">
      ${renderIcon(link.icon)}
      ${link.label}
    </a>
  `).join('')

  nav.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', (e) => {
      e.preventDefault()
      onNavigate(a.getAttribute('href'))
    })
  })

  container.appendChild(nav)
  return nav
}

function renderIcon(name) {
  const icons = {
    dashboard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><rect x="3" y="3" width="7" height="9" rx="1"/><rect x="14" y="3" width="7" height="5" rx="1"/><rect x="14" y="12" width="7" height="9" rx="1"/><rect x="3" y="16" width="7" height="5" rx="1"/></svg>`,
    feed: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M4 6h16M4 12h16M4 18h12"/></svg>`,
    friends: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>`,
    profile: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor"><circle cx="12" cy="8" r="4"/><path d="M20 21a8 8 0 1 0-16 0"/></svg>`,
  }
  return icons[name] || ''
}
