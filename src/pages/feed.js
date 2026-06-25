import { supabase } from '../lib/supabase.js'

export async function renderFeed(container, user, { navigate }) {
  container.innerHTML = `
    <div class="page">
      <div class="feed-header">
        <h2>Feed</h2>
        <div id="notif-bell-container"></div>
      </div>

      <div class="card composer fade-in" id="composer">
        <div class="post-type-selector">
          <button data-type="general" class="active">General</button>
          <button data-type="fasting">🍽️ Fasting</button>
          <button data-type="exercise">💪 Exercise</button>
        </div>
        <textarea id="post-content" placeholder="What are you up to?" rows="2"></textarea>
        <div id="duration-input" class="hidden timer-input-group">
          <input type="number" id="post-duration" placeholder="Duration (min)" min="1" />
        </div>
        <button id="post-btn" class="btn btn-primary btn-block">Post</button>
      </div>

      <div id="feed-posts">
        <div class="loading"><div class="spinner"></div></div>
      </div>
    </div>
  `

  await loadPosts()

  let selectedType = 'general'
  document.querySelectorAll('.post-type-selector button').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.post-type-selector button').forEach(b => b.classList.remove('active'))
      btn.classList.add('active')
      selectedType = btn.dataset.type
      const durationEl = document.getElementById('duration-input')
      if (selectedType === 'fasting' || selectedType === 'exercise') {
        durationEl.classList.remove('hidden')
      } else {
        durationEl.classList.add('hidden')
      }
    })
  })

  document.getElementById('post-btn').addEventListener('click', async () => {
    const content = document.getElementById('post-content').value.trim()
    if (!content) return

    const btn = document.getElementById('post-btn')
    btn.disabled = true
    btn.textContent = 'Posting...'

    let duration = null
    if (selectedType === 'fasting' || selectedType === 'exercise') {
      duration = parseInt(document.getElementById('post-duration').value) || null
    }

    const { error } = await supabase.from('posts').insert({
      user_id: user.id,
      type: selectedType,
      content,
      duration_minutes: duration,
    })

    if (!error) {
      document.getElementById('post-content').value = ''
      document.getElementById('post-duration').value = ''
      document.getElementById('duration-input').classList.add('hidden')
      document.querySelector('.post-type-selector button[data-type="general"]').click()
      await loadPosts()
    }

    btn.disabled = false
    btn.textContent = 'Post'
  })

  async function loadPosts() {
    const { data: posts, error } = await supabase
      .from('posts')
      .select(`
        *,
        profiles:user_id (username, display_name, avatar_url)
      `)
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) {
      document.getElementById('feed-posts').innerHTML = '<div class="empty-state text-muted">Failed to load posts</div>'
      return
    }

    if (!posts?.length) {
      document.getElementById('feed-posts').innerHTML = `
        <div class="empty-state fade-in">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9-4.03-9-9-9z"/><path d="M8 12h8"/><path d="M12 8v8"/></svg>
          <p>No posts yet. Be the first!</p>
        </div>`
      return
    }

    document.getElementById('feed-posts').innerHTML = posts.map(post => renderPost(post, user.id)).join('')
  }

  return () => {}
}

function timeAgo(dateStr) {
  const now = Date.now()
  const diff = now - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  return `${days}d ago`
}

function renderPost(post, currentUserId) {
  const profile = post.profiles || {}
  const name = profile.display_name || profile.username || 'Anonymous'
  const initial = (profile.display_name || profile.username || '?')[0].toUpperCase()

  const typeLabels = {
    fasting: '🍽️ Fasting',
    exercise: '💪 Exercise',
    workout_complete: '✅ Workout Complete',
    fasting_complete: '✅ Fast Complete',
    general: '💬 General',
  }

  const badgeClass = {
    fasting: 'fasting',
    exercise: 'exercise',
    workout_complete: 'complete',
    fasting_complete: 'complete',
    general: '',
  }

  const durationStr = post.duration_minutes ? ` · ${post.duration_minutes} min` : ''

  return `
    <div class="card post fade-in">
      <div class="avatar">${initial}</div>
      <div class="post-body">
        <div class="post-header">
          <span class="name">${name}</span>
          <span class="time">${timeAgo(post.created_at)}</span>
          ${post.user_id === currentUserId ? '<button class="btn btn-sm btn-danger delete-post" data-id="' + post.id + '" style="margin-left:auto;padding:2px 8px;font-size:11px">✕</button>' : ''}
        </div>
        <div class="post-type-badge ${badgeClass[post.type] || ''}">${typeLabels[post.type] || post.type}${durationStr}</div>
        <div class="post-content">${post.content}</div>
      </div>
    </div>
  `
}
