import { supabase } from '../lib/supabase.js'
import { useStore } from '../store/useStore.js'

const EMOJIS = ['🔥', '🙌', '💯', '👏', '💪']

const typeConfig = {
  fasting: { emoji: '🍽️', label: 'Fasting', color: 'sage' },
  fasting_complete: { emoji: '✅', label: 'Fast Complete', color: 'sage' },
  exercise: { emoji: '🏃', label: 'Exercise', color: 'terracotta' },
  workout_complete: { emoji: '🏆', label: 'Workout Done', color: 'terracotta' },
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
      <div id="feed-list">
        ${renderFeedList()}
      </div>
    </div>
  `

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

      return `
        <div class="status-card ${cfg.color} fade-in" data-post-id="${post.id}">
          <div class="status-card-header">
            <div class="status-card-avatar" style="background:${avatarColor(name)}">${initial}</div>
            <span class="status-card-name">${name}</span>
            <span class="status-card-time">${elapsed}</span>
          </div>
          <div class="status-card-body">${body}</div>
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
  const colors = ['#6CB49C', '#C4B8D8', '#EDB8B8', '#EDD9A8', '#A8C8E0']
  let hash = 0
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash)
  return colors[Math.abs(hash) % colors.length]
}
