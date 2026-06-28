import { supabase } from '../lib/supabase.js'
import { useStore } from '../store/useStore.js'

const EMOJIS = ['🔥', '🙌', '💯', '👏', '💪']

const typeConfig = {
  fasting: { emoji: '🍽️', label: 'Fasting', color: 'indigo' },
  fasting_complete: { emoji: '✅', label: 'Fast Complete', color: 'indigo' },
  exercise: { emoji: '🏃', label: 'Exercise', color: 'emerald' },
  workout_complete: { emoji: '🏆', label: 'Workout Done', color: 'emerald' },
  checkin: { emoji: '📸', label: 'Check-in', color: 'neutral' },
  general: { emoji: '💬', label: 'Update', color: 'neutral' },
}

export async function renderFeed(container, user) {
  const store = useStore.getState()
  store.setUser(user)
  await store.fetchFeed(user.id)

  container.innerHTML = `
    <div class="screen feed fade-in">
      <div class="feed-header">
        <h1>🔥 Feed</h1>
      </div>
      <div id="stories-bar" class="stories-bar"></div>
      <div id="feed-list">
        ${renderFeedList()}
      </div>
    </div>
  `

  renderStories()
  subscribeRealtime()

  function renderFeedList() {
    const feed = useStore.getState().feed
    if (!feed.length) {
      return '<div class="empty-state">No updates yet. Add friends to see their progress!</div>'
    }
    return feed.map(post => {
      const cfg = typeConfig[post.type] || typeConfig.general
      const name = post.profile?.display_name || post.profile?.username || 'Someone'
      const initial = name[0].toUpperCase()
      const elapsed = timeAgo(post.created_at)

      const hasReacted = post.reactions?.some(r => r.user_id === user.id)
      const reactionCounts = {}
      post.reactions?.forEach(r => {
        reactionCounts[r.emoji || '🔥'] = (reactionCounts[r.emoji || '🔥'] || 0) + 1
      })

      let body = ''
      if (post.type === 'fasting') {
        body = `<strong>${name}</strong> is currently <strong>Fasting</strong>${post.duration_minutes ? ` (${dh(post.duration_minutes)} in)` : ''}`
      } else if (post.type === 'fasting_complete') {
        body = `<strong>${name}</strong> completed a <strong>Fast</strong>${post.duration_minutes ? ` (${dh(post.duration_minutes)})` : ''}`
      } else if (post.type === 'exercise') {
        body = `<strong>${name}</strong> is working out${post.duration_minutes ? ` (${post.duration_minutes}min)` : ''}`
      } else if (post.type === 'workout_complete') {
        body = `<strong>${name}</strong> crushed a <strong>Workout</strong>!`
      } else {
        body = `<strong>${name}</strong> ${post.content}`
      }

      const hypeCount = post.hype_count || 0
      const userHyped = post.reactions?.some(r => r.user_id === user.id && r.emoji === '🔥') || false

      return `
        <div class="status-card ${cfg.color} fade-in" data-post-id="${post.id}">
          <div class="status-card-header">
            <div class="status-card-avatar" style="background:${avatarColor(name)}">${initial}</div>
            <span class="status-card-name">${name}</span>
            <span class="status-card-type">${cfg.emoji} ${cfg.label}</span>
            <span class="status-card-time">${elapsed}</span>
          </div>
          <div class="status-card-body">${body}</div>
          ${post.image_url ? `<div class="status-card-image"><img src="${post.image_url}" alt="Check-in" loading="lazy" /></div>` : ''}
          <div class="status-card-footer" id="reactions-${post.id}">
            ${EMOJIS.map(emoji => {
              const count = reactionCounts[emoji] || 0
              const active = post.reactions?.some(r => r.user_id === user.id && (r.emoji || '🔥') === emoji)
              return `
                <button class="status-reaction ${active ? 'active' : ''}" data-post="${post.id}" data-emoji="${emoji}">
                  ${emoji} ${count > 0 ? `<span class="status-reaction-count">${count}</span>` : ''}
                </button>
              `
            }).join('')}
          </div>
          <button class="hype-btn ${userHyped ? 'active' : ''}" data-post="${post.id}">
            🔥 Send Hype${hypeCount > 0 ? `<span class="hype-count">${hypeCount}</span>` : ''}
          </button>
        </div>
      `
    }).join('')
  }

  function subscribeRealtime() {
    const channel = supabase
      .channel('feed-changes')
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'posts',
      }, () => {
        store.fetchFeed(user.id).then(() => {
          const list = document.getElementById('feed-list')
          if (list) list.innerHTML = renderFeedList()
          attachReactionHandlers()
        })
      })
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'reactions',
      }, () => {
        store.fetchFeed(user.id).then(() => {
          const list = document.getElementById('feed-list')
          if (list) list.innerHTML = renderFeedList()
          attachReactionHandlers()
        })
      })
      .subscribe()

    attachReactionHandlers()

    return () => {
      supabase.removeChannel(channel)
    }
  }

  function attachReactionHandlers() {
    document.querySelectorAll('.status-reaction').forEach(btn => {
      btn.addEventListener('click', async () => {
        const postId = btn.dataset.post
        const emoji = btn.dataset.emoji
        const store = useStore.getState()
        const hasActive = btn.classList.contains('active')

        if (hasActive) {
          await supabase.from('reactions').delete().eq('user_id', user.id).eq('post_id', postId)
        } else {
          await supabase.from('reactions').insert({ user_id: user.id, post_id: postId, emoji })
        }

        store.fetchFeed(user.id).then(() => {
          const list = document.getElementById('feed-list')
          if (list) list.innerHTML = renderFeedList()
          attachReactionHandlers()
        })
      })
    })

    document.querySelectorAll('.hype-btn').forEach(btn => {
      btn.addEventListener('click', async () => {
        const postId = btn.dataset.post
        const store = useStore.getState()
        const isActive = btn.classList.contains('active')

        if (isActive) {
          await supabase.from('reactions').delete().eq('user_id', user.id).eq('post_id', postId)
        } else {
          await supabase.from('reactions').insert({ user_id: user.id, post_id: postId, emoji: '🔥' })
          spawnParticles(btn)
        }

        store.fetchFeed(user.id).then(() => {
          const list = document.getElementById('feed-list')
          if (list) list.innerHTML = renderFeedList()
          attachReactionHandlers()
        })
      })
    })
  }

  function spawnParticles(btn) {
    const card = btn.closest('.status-card')
    if (!card) return
    const box = card.getBoundingClientRect()
    const bbox = btn.getBoundingClientRect()
    const cx = bbox.left - box.left + bbox.width / 2
    const cy = bbox.top - box.top + bbox.height / 2

    const canvas = document.createElement('canvas')
    canvas.className = 'particle-container'
    canvas.width = box.width
    canvas.height = box.height
    canvas.style.cssText = 'position:absolute;inset:0;pointer-events:none;z-index:10;width:100%;height:100%'
    card.appendChild(canvas)
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const colors = ['#FF4757', '#FF6B81', '#FFA502', '#FF4757', '#FFD93D', '#FF6B81']
    const particles = []
    for (let i = 0; i < 24; i++) {
      const angle = (Math.PI * 2 * i) / 24 + (Math.random() - 0.5) * 0.3
      const dist = 50 + Math.random() * 100
      const size = 4 + Math.random() * 8
      particles.push({
        x: cx, y: cy,
        dx: Math.cos(angle) * dist,
        dy: Math.sin(angle) * dist,
        size,
        color: colors[i % colors.length],
        alpha: 1,
        decay: 0.008 + Math.random() * 0.015,
        rotation: Math.random() * 360,
        rotSpeed: (Math.random() - 0.5) * 6,
      })
    }

    let frame
    function animate() {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      let alive = false
      for (const p of particles) {
        if (p.alpha <= 0) continue
        alive = true
        p.x += (p.dx - (p.x - cx)) * 0.04
        p.y += (p.dy - (p.y - cy)) * 0.04 - 0.3
        p.alpha -= p.decay
        p.rotation += p.rotSpeed
        ctx.save()
        ctx.globalAlpha = Math.max(0, p.alpha)
        ctx.translate(p.x, p.y)
        ctx.rotate((p.rotation * Math.PI) / 180)
        ctx.fillStyle = p.color
        const s = p.size * (0.3 + 0.7 * p.alpha)
        ctx.fillRect(-s / 2, -s / 2, s, s)
        ctx.restore()
      }
      if (alive) frame = requestAnimationFrame(animate)
      else canvas.remove()
    }
    animate()
  }

  function renderStories() {
    const stories = useStore.getState().feed
    const seen = new Set()
    const recent = stories.filter(p => {
      if (seen.has(p.user_id)) return false
      const age = Date.now() - new Date(p.created_at).getTime()
      if (age > 86400000) return false
      seen.add(p.user_id)
      return true
    })

    const bar = document.getElementById('stories-bar')
    if (!bar) return

    if (!recent.length) {
      bar.style.display = 'none'
      return
    }

    bar.style.display = ''
    bar.innerHTML = recent.map(p => {
      const name = p.profile?.display_name || p.profile?.username || '?'
      const initial = name[0].toUpperCase()
      const ringColor = typeConfig[p.type]?.color || 'neutral'
      return `
        <div class="story-ring" data-user="${p.user_id}">
          <div class="story-ring-circle ${ringColor}">
            <span class="story-ring-initial">${initial}</span>
          </div>
          <span class="story-ring-name">${name.split(' ')[0]}</span>
        </div>
      `
    }).join('')

    bar.querySelectorAll('.story-ring').forEach(el => {
      el.addEventListener('click', () => {
        const userId = el.dataset.user
        const post = recent.find(p => p.user_id === userId)
        if (!post) return
        const name = post.profile?.display_name || post.profile?.username || 'Someone'
        const label = typeConfig[post.type]?.label || 'Update'
        const body = post.image_url
          ? `<img src="${post.image_url}" style="width:100%;border-radius:12px;margin-top:8px" />`
          : post.content || ''
        const overlay = document.createElement('div')
        overlay.className = 'story-overlay'
        overlay.innerHTML = `
          <div class="story-popup">
            <div class="story-popup-header">
              <strong>${name}</strong>
              <span class="text-muted" style="font-size:12px">${label} · ${timeAgo(post.created_at)}</span>
            </div>
            <div class="story-popup-body">${body}</div>
            <button class="btn btn-sm btn-secondary" id="close-story">Close</button>
          </div>
        `
        overlay.addEventListener('click', (e) => {
          if (e.target === overlay) overlay.remove()
        })
        document.body.appendChild(overlay)
        overlay.querySelector('#close-story').addEventListener('click', () => overlay.remove())
      })
    })
  }

  return () => {
    document.querySelectorAll('.bottom-nav a').forEach(a => {
      a.classList.remove('active')
      if (a.getAttribute('href') === '#/feed') a.classList.add('active')
    })
  }
}

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h ago`
  return `${Math.floor(hours / 24)}d ago`
}

function dh(minutes) {
  if (!minutes) return ''
  if (minutes >= 60) {
    const h = Math.floor(minutes / 60)
    const m = minutes % 60
    return m ? `${h}h ${m}m` : `${h}h`
  }
  return `${minutes}m`
}

function avatarColor(name) {
  const colors = ['#6366F1', '#F59E0B', '#10B981', '#EF4444', '#ADB5BD']
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash)
  return colors[Math.abs(hash) % colors.length]
}
