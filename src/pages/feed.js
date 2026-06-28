import { supabase } from '../lib/supabase.js'

export async function renderFeed(container, user, { navigate }) {
  container.innerHTML = `
    <div class="feed-page fade-in">
      <div class="feed-top-bar">
        <h1>🔥 FASTING FURIOUS</h1>
        <div id="notif-bell-container"></div>
      </div>

      <div class="carousel-wrap" id="carousel-wrap">
        <div class="carousel-track" id="carousel-track"></div>
      </div>

      <div class="carousel-nav" id="carousel-nav">
        <button class="carousel-arrow" id="carousel-prev">‹</button>
        <div class="carousel-dots" id="carousel-dots"></div>
        <button class="carousel-arrow" id="carousel-next">›</button>
      </div>

      <div class="feed-composer-toggle">
        <button id="composer-fab">＋</button>
      </div>
    </div>
  `

  let cards = []
  let currentIndex = 0
  let isComposerOpen = false

  await buildCardData()

  document.getElementById('carousel-prev').addEventListener('click', () => goTo(currentIndex - 1))
  document.getElementById('carousel-next').addEventListener('click', () => goTo(currentIndex + 1))
  document.getElementById('composer-fab').addEventListener('click', openComposer)

  setupTouchGestures()

  function goTo(index) {
    if (index < 0) index = cards.length - 1
    if (index >= cards.length) index = 0
    currentIndex = index
    updateCarousel()
  }

  function updateCarousel() {
    const track = document.getElementById('carousel-track')
    if (!track) return

    const slideWidth = track.children[0]?.offsetWidth || 0
    track.style.transform = `translateX(-${currentIndex * slideWidth}px)`

    document.querySelectorAll('.carousel-dot').forEach((dot, i) => {
      dot.classList.toggle('active', i === currentIndex)
    })
  }

  async function buildCardData() {
    const track = document.getElementById('carousel-track')
    track.innerHTML = '<div class="loading" style="width:100%;padding:80px 0"><div class="spinner"></div></div>'

    const todayStart = new Date()
    todayStart.setHours(0, 0, 0, 0)

    const profile = await getMyProfile(user.id)
    const friendProfiles = await getFriendProfiles(user.id)

    const allProfiles = [profile, ...friendProfiles].filter(Boolean)
    const userIds = allProfiles.map(p => p.id)

    const allTodayPosts = await getTodayPosts(userIds, todayStart)
    const allReactions = await getReactions(allTodayPosts.map(p => p.id))
    const activeTimers = await getActiveTimers(userIds)

    const postsByUser = groupBy(allTodayPosts, 'user_id')
    const timersByUser = groupBy(activeTimers, 'user_id')

    const kudosByPost = {}
    allReactions.forEach(r => {
      if (!kudosByPost[r.post_id]) kudosByPost[r.post_id] = []
      kudosByPost[r.post_id].push(r)
    })

    cards = allProfiles.map(p => buildFriendCard(p, postsByUser[p.id] || [], timersByUser[p.id]?.[0] || null, kudosByPost, user.id))

    renderCards(cards)
  }

  function renderCards(cardsData) {
    const track = document.getElementById('carousel-track')
    track.innerHTML = cardsData.map((c, i) => `
      <div class="carousel-slide">
        ${c}
      </div>
    `).join('')

    renderDots(cardsData.length)
    updateCarousel()

    attachKudosHandlers()
    attachAvatarHandlers(navigate)
  }

  function renderDots(count) {
    const dots = document.getElementById('carousel-dots')
    dots.innerHTML = Array.from({ length: count }, (_, i) =>
      `<div class="carousel-dot ${i === currentIndex ? 'active' : ''}" data-index="${i}"></div>`
    ).join('')

    dots.querySelectorAll('.carousel-dot').forEach(dot => {
      dot.addEventListener('click', () => goTo(parseInt(dot.dataset.index)))
    })
  }

  function setupTouchGestures() {
    const wrap = document.getElementById('carousel-wrap')
    let startX = 0
    let isDragging = false

    wrap.addEventListener('touchstart', (e) => {
      startX = e.touches[0].clientX
      isDragging = true
    }, { passive: true })

    wrap.addEventListener('touchmove', (e) => {
      if (!isDragging) return
      const diff = e.touches[0].clientX - startX
      const threshold = 60
      if (Math.abs(diff) > threshold) {
        isDragging = false
        if (diff > 0) goTo(currentIndex - 1)
        else goTo(currentIndex + 1)
      }
    }, { passive: true })

    wrap.addEventListener('touchend', () => { isDragging = false }, { passive: true })
  }

  function openComposer() {
    if (isComposerOpen) return
    isComposerOpen = true

    const overlay = document.createElement('div')
    overlay.className = 'modal-overlay'
    overlay.id = 'composer-modal'

    let selectedType = 'general'

    overlay.innerHTML = `
      <div class="modal-content">
        <button class="close-modal" id="close-composer">✕</button>
        <h3>New Post</h3>
        <div class="post-type-selector">
          <button data-type="general" class="active">💬 General</button>
          <button data-type="fasting">🍽️ Fasting</button>
          <button data-type="exercise">💪 Exercise</button>
        </div>
        <textarea id="composer-content" placeholder="What are you up to?" rows="3" style="margin-bottom:12px"></textarea>
        <div id="composer-duration-wrap" class="hidden" style="margin-bottom:12px">
          <input type="number" id="composer-duration" placeholder="Duration (min)" min="1" />
        </div>
        <button id="composer-submit" class="btn btn-primary btn-block">Post</button>
      </div>
    `

    document.body.appendChild(overlay)

    overlay.querySelectorAll('.post-type-selector button').forEach(btn => {
      btn.addEventListener('click', () => {
        overlay.querySelectorAll('.post-type-selector button').forEach(b => b.classList.remove('active'))
        btn.classList.add('active')
        selectedType = btn.dataset.type
        const dw = document.getElementById('composer-duration-wrap')
        dw.classList.toggle('hidden', selectedType !== 'fasting' && selectedType !== 'exercise')
      })
    })

    document.getElementById('close-composer').addEventListener('click', closeComposer)
    overlay.addEventListener('click', (e) => { if (e.target === overlay) closeComposer() })

    document.getElementById('composer-submit').addEventListener('click', async () => {
      const content = document.getElementById('composer-content').value.trim()
      if (!content) return

      const btn = document.getElementById('composer-submit')
      btn.disabled = true
      btn.textContent = 'Posting...'

      let duration = null
      if (selectedType === 'fasting' || selectedType === 'exercise') {
        duration = parseInt(document.getElementById('composer-duration').value) || null
      }

      const { error } = await supabase.from('posts').insert({
        user_id: user.id,
        type: selectedType,
        content,
        duration_minutes: duration,
      })

      if (error) {
        btn.disabled = false
        btn.textContent = 'Post'
        return
      }

      closeComposer()
      await buildCardData()
    })
  }

  function closeComposer() {
    isComposerOpen = false
    document.getElementById('composer-modal')?.remove()
  }

  return () => {
    document.getElementById('composer-modal')?.remove()
  }
}

/* ─── Data Helpers ─── */

async function getMyProfile(userId) {
  const { data } = await supabase.from('profiles').select('*').eq('id', userId).single()
  return data
}

async function getFriendProfiles(userId) {
  const { data: friendships } = await supabase
    .from('friendships')
    .select('sender_id, receiver_id')
    .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
    .eq('status', 'accepted')

  if (!friendships?.length) return []

  const friendIds = friendships.map(f => f.sender_id === userId ? f.receiver_id : f.sender_id)
  const { data: profiles } = await supabase
    .from('profiles')
    .select('*')
    .in('id', friendIds)

  return profiles || []
}

async function getTodayPosts(userIds, todayStart) {
  if (!userIds.length) return []
  const { data } = await supabase
    .from('posts')
    .select('*')
    .in('user_id', userIds)
    .gte('created_at', todayStart.toISOString())
    .order('created_at', { ascending: false })

  return data || []
}

async function getReactions(postIds) {
  if (!postIds.length) return []
  const { data } = await supabase
    .from('reactions')
    .select('*')
    .in('post_id', postIds)
  return data || []
}

async function getActiveTimers(userIds) {
  if (!userIds.length) return []
  const { data } = await supabase
    .from('active_timers')
    .select('*')
    .in('user_id', userIds)
    .eq('active', true)
  return data || []
}

function groupBy(arr, key) {
  const map = {}
  arr.forEach(item => {
    const k = item[key]
    if (!map[k]) map[k] = []
    map[k].push(item)
  })
  return map
}

/* ─── Card Builder ─── */

function buildFriendCard(profile, todayPosts, activeTimer, kudosByPost, currentUserId) {
  const initial = (profile.display_name || profile.username || '?')[0].toUpperCase()
  const name = profile.display_name || profile.username || 'Anonymous'

  const streak = calculateStreak(todayPosts)
  const title = getTrainerTitle(streak)
  const titleClass = streak >= 7 ? 'legendary' : streak >= 3 ? 'elite' : 'beginner'
  const rarity = getRarity(todayPosts, activeTimer)

  const focusBadges = getFocusBadges(todayPosts, activeTimer)
  const moves = buildMoveset(todayPosts)

  const totalKudos = todayPosts.reduce((sum, p) => sum + (kudosByPost[p.id]?.length || 0), 0)
  const userKudos = todayPosts.filter(p => kudosByPost[p.id]?.some(r => r.user_id === currentUserId)).length
  const allPostIds = todayPosts.map(p => p.id)

  return `
    <div class="friend-card rarity-${rarity}">
      <div class="card-portrait">
        <div class="card-avatar profile-link" data-id="${profile.id}">${initial}</div>
        <div class="card-name profile-link" data-id="${profile.id}">${name}</div>
        <div class="card-title ${titleClass}">${title}</div>
      </div>

      <div class="card-badge">
        ${focusBadges}
      </div>

      <div class="card-moveset">
        ${moves.length > 0 ? moves.join('') : `<div class="text-muted" style="text-align:center;padding:20px;font-size:13px">No activity logged today yet</div>`}
      </div>

      <div class="card-kudos">
        <button class="kudos-btn ${userKudos > 0 ? 'kudos-given' : ''}" data-posts='${JSON.stringify(allPostIds)}' data-user="${currentUserId}">
          <svg viewBox="0 0 24 24" fill="${userKudos > 0 ? 'currentColor' : 'none'}" stroke="currentColor" stroke-width="2"><path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3H14zM7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3"/></svg>
          Kudos
        </button>
        <span class="kudos-count">${totalKudos > 0 ? totalKudos : ''}</span>
      </div>
    </div>
  `
}

function getTrainerTitle(streakDays) {
  if (streakDays >= 30) return '🏆 Fasting Legend'
  if (streakDays >= 14) return '⚡ Iron Will'
  if (streakDays >= 7) return '🔥 Fasting Guru'
  if (streakDays >= 3) return '💪 Marathoner'
  if (streakDays >= 1) return '🌟 Apprentice'
  return '🌱 Newcomer'
}

function calculateStreak(todayPosts) {
  if (!todayPosts.length) return 0

  const types = new Set(todayPosts.map(p => p.type))
  const hasComplete = types.has('fasting_complete') || types.has('workout_complete')
  const hasActivity = types.has('fasting') || types.has('exercise')

  if (hasComplete) return 7
  if (hasActivity) return 3
  return 1
}

function getRarity(posts, activeTimer) {
  const types = new Set(posts.map(p => p.type))

  const allComplete = types.has('fasting_complete') && types.has('workout_complete')
  if (allComplete) return 'legendary'

  if (activeTimer?.type === 'fasting') return 'fasting'

  const hasComplete = types.has('fasting_complete') || types.has('workout_complete')
  if (hasComplete) return 'rare'

  return 'common'
}

function getFocusBadges(posts, activeTimer) {
  const types = new Set(posts.map(p => p.type))
  const badges = []

  if (activeTimer?.type === 'fasting') {
    badges.push(`<div class="focus-badge active-fasting"><span class="badge-icon">🔥</span><span class="badge-label">Fasting Now</span></div>`)
  } else if (activeTimer?.type === 'workout') {
    badges.push(`<div class="focus-badge active-exercise"><span class="badge-icon">💪</span><span class="badge-label">Working Out</span></div>`)
  }

  if (types.has('fasting') || types.has('fasting_complete')) {
    badges.push(`<div class="focus-badge ${activeTimer?.type === 'fasting' ? 'active-fasting' : ''}"><span class="badge-icon">🍽️</span><span class="badge-label">Fasting</span></div>`)
  }
  if (types.has('exercise') || types.has('workout_complete')) {
    badges.push(`<div class="focus-badge ${activeTimer?.type === 'workout' ? 'active-exercise' : ''}"><span class="badge-icon">🏃</span><span class="badge-label">Exercise</span></div>`)
  }

  if (!badges.length) {
    badges.push(`<div class="focus-badge"><span class="badge-icon">💤</span><span class="badge-label">Rest</span></div>`)
  }

  return badges.join('')
}

function buildMoveset(posts) {
  return posts.slice(0, 8).map(p => {
    const { icon, typeClass, name, power, effect } = describeMove(p)
    return `
      <div class="move-item">
        <div class="move-icon ${typeClass}">${icon}</div>
        <div class="move-body">
          <div class="move-name">${name}</div>
          <div class="move-stats">
            ${power ? `<span>⚡ ${power}</span>` : ''}
            <span>🕐 ${timeAgo(p.created_at)}</span>
          </div>
          ${effect ? `<div class="move-effect">✨ ${effect}</div>` : ''}
        </div>
      </div>
    `
  })
}

function describeMove(post) {
  const duration = post.duration_minutes

  switch (post.type) {
    case 'fasting':
      return {
        icon: '🍽️',
        typeClass: 'fasting',
        name: `Water Fast ${duration ? `(${dh(duration)})` : ''}`,
        power: duration ? `${duration}min` : null,
        effect: post.content
      }
    case 'fasting_complete':
      return {
        icon: '✅',
        typeClass: 'complete',
        name: `Fast Complete! ${duration ? `(${dh(duration)})` : ''}`,
        power: duration ? `${duration}min` : null,
        effect: post.content
      }
    case 'exercise':
      return {
        icon: '💪',
        typeClass: 'exercise',
        name: `Workout${duration ? ` (${duration}min)` : ''}`,
        power: duration ? `${duration}min` : null,
        effect: post.content
      }
    case 'workout_complete':
      return {
        icon: '🏆',
        typeClass: 'complete',
        name: `Workout Done! ${duration ? `(${duration}min)` : ''}`,
        power: duration ? `${duration}min` : null,
        effect: post.content
      }
    default:
      return {
        icon: '💬',
        typeClass: '',
        name: 'Update',
        power: null,
        effect: post.content
      }
  }
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

function timeAgo(dateStr) {
  const diff = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}h ago`
  return `${Math.floor(hours / 24)}d ago`
}

function attachKudosHandlers() {
  document.querySelectorAll('.kudos-btn').forEach(btn => {
    btn.addEventListener('click', async () => {
      let postIds
      try {
        postIds = JSON.parse(btn.dataset.posts)
      } catch {
        return
      }
      const userId = btn.dataset.user
      if (!postIds.length) return

      const isGiven = btn.classList.contains('kudos-given')

      if (isGiven) {
        for (const postId of postIds) {
          await supabase.from('reactions').delete().eq('user_id', userId).eq('post_id', postId)
        }
        btn.classList.remove('kudos-given')
        btn.querySelector('svg').setAttribute('fill', 'none')
      } else {
        for (const postId of postIds) {
          await supabase.from('reactions').insert({ user_id: userId, post_id: postId })
        }
        btn.classList.add('kudos-given')
        btn.querySelector('svg').setAttribute('fill', 'currentColor')
      }

      const countEl = btn.parentElement.querySelector('.kudos-count')
      const current = parseInt(countEl.textContent) || 0
      countEl.textContent = isGiven ? (current > 1 ? current - postIds.length : '') : current + postIds.length
    })
  })
}

function attachAvatarHandlers(navigate) {
  document.querySelectorAll('.profile-link').forEach(el => {
    el.addEventListener('click', () => navigate('/profile/' + el.dataset.id))
  })
}
