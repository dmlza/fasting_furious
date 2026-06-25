import { supabase } from '../lib/supabase.js'

export class NotificationManager {
  constructor(userId, appEl) {
    this.userId = userId
    this.appEl = appEl
    this.unreadCount = 0
    this.open = false
    this.notifications = []
    this.subscription = null

    this.createBell()
    this.loadNotifications()
    this.subscribe()
  }

  createBell() {
    const bellContainer = document.getElementById('notif-bell-container')
    if (!bellContainer) return

    bellContainer.innerHTML = `
      <div class="notif-bell" id="notif-bell">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="24" height="24">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
          <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
        </svg>
        <div class="notif-badge hidden" id="notif-badge">0</div>
      </div>
    `

    document.getElementById('notif-bell').addEventListener('click', () => this.togglePanel())
  }

  async loadNotifications() {
    const { data } = await supabase
      .from('notifications')
      .select('*, from_user:from_user_id(username, display_name)')
      .eq('user_id', this.userId)
      .order('created_at', { ascending: false })
      .limit(50)

    if (data) {
      this.notifications = data
      this.unreadCount = data.filter(n => !n.read).length
      this.updateBadge()
    }
  }

  subscribe() {
    const channel = supabase
      .channel('notifications')
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
        filter: `user_id=eq.${this.userId}`
      }, (payload) => {
        const newNotif = payload.new
        this.notifications.unshift(newNotif)
        this.unreadCount++
        this.updateBadge()
        if (this.open) this.renderPanel()
      })
      .subscribe()
  }

  updateBadge() {
    const badge = document.getElementById('notif-badge')
    if (!badge) return
    if (this.unreadCount > 0) {
      badge.classList.remove('hidden')
      badge.textContent = this.unreadCount > 99 ? '99+' : this.unreadCount
    } else {
      badge.classList.add('hidden')
    }
  }

  togglePanel() {
    this.open = !this.open
    if (this.open) {
      this.renderPanel()
      this.markAllRead()
    } else {
      this.removePanel()
    }
  }

  renderPanel() {
    this.removePanel()

    const overlay = document.createElement('div')
    overlay.className = 'notif-overlay'
    overlay.id = 'notif-overlay'
    overlay.addEventListener('click', () => this.togglePanel())

    const panel = document.createElement('div')
    panel.className = 'notif-panel open'
    panel.id = 'notif-panel'

    panel.innerHTML = `
      <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:16px">
        <h3>Notifications</h3>
        <button class="btn btn-sm btn-secondary" id="close-notif-panel">✕</button>
      </div>
      ${this.notifications.length === 0
        ? '<div class="text-muted">No notifications yet</div>'
        : this.notifications.map(n => {
          const fromName = n.from_user?.display_name || n.from_user?.username || 'Someone'
          const time = new Date(n.created_at).toLocaleDateString()
          return `
            <div class="notif-item ${n.read ? '' : 'unread'}">
              <div>${fromName} ${n.message}</div>
              <div class="notif-time">${time}</div>
            </div>
          `
        }).join('')
      }
    `

    document.body.appendChild(overlay)
    document.body.appendChild(panel)

    document.getElementById('close-notif-panel').addEventListener('click', () => this.togglePanel())
  }

  removePanel() {
    document.getElementById('notif-overlay')?.remove()
    document.getElementById('notif-panel')?.remove()
  }

  async markAllRead() {
    if (this.unreadCount === 0) return
    await supabase
      .from('notifications')
      .update({ read: true })
      .eq('user_id', this.userId)
      .eq('read', false)
    this.unreadCount = 0
    this.updateBadge()
  }

  destroy() {
    this.subscription?.unsubscribe()
    this.removePanel()
  }
}
