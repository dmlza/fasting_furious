import { supabase } from '../lib/supabase.js'
import { useStore } from '../store/useStore.js'

export async function renderProfile(container, user, { navigate }) {
  const store = useStore.getState()
  store.setUser(user)
  if (!store.profile) await store.fetchProfile(user.id)
  await store.fetchFriends(user.id)
  await store.fetchHabitHistory(user.id)
  const profile = store.profile
  const friends = store.friends

  const initial = (profile?.display_name || profile?.username || '?')[0].toUpperCase()

  container.innerHTML = `
    <div class="screen fade-in">
      <div class="profile-header card">
        <div class="avatar-large">${initial}</div>
        <h2>${profile?.display_name || profile?.username || 'Anonymous'}</h2>
        <span class="username">@${profile?.username || 'unknown'}</span>
        ${profile?.bio ? `<p class="bio">${profile.bio}</p>` : ''}
        <div class="profile-actions">
          <button id="edit-profile-btn" class="btn btn-secondary btn-sm">Edit Profile</button>
          <button id="signout-btn" class="btn btn-danger btn-sm">Sign Out</button>
        </div>
      </div>

      <div class="profile-stats">
        <div class="profile-stat">
          <div class="profile-stat-value">${friends.length}</div>
          <div class="profile-stat-label">Friends</div>
        </div>
        <div class="profile-stat">
          <div class="profile-stat-value" id="my-streak">0</div>
          <div class="profile-stat-label">Streak 🔥</div>
        </div>
        <div class="profile-stat">
          <div class="profile-stat-value" id="post-count">0</div>
          <div class="profile-stat-label">Posts</div>
        </div>
      </div>

      <div class="card" style="margin-bottom:16px">
        <div style="display:flex;align-items:center;justify-content:space-between;gap:12px">
          <div>
            <div style="font-weight:600;font-size:14px;color:var(--text-primary)">Theme</div>
            <div style="font-size:12px;color:var(--text-muted)">Toggle dark/light mode</div>
          </div>
          <button id="theme-toggle" class="theme-switch" aria-label="Toggle theme">
            <span class="theme-switch-knob"></span>
          </button>
        </div>
      </div>

      <div id="edit-profile-form" class="card hidden">
        <div class="flex flex-col gap-8">
          <input type="text" id="edit-display-name" placeholder="Display Name" value="${profile?.display_name || ''}" />
          <input type="text" id="edit-username" placeholder="Username" value="${profile?.username || ''}" />
          <textarea id="edit-bio" placeholder="Bio">${profile?.bio || ''}</textarea>
          <button id="save-profile-btn" class="btn btn-primary">Save</button>
        </div>
      </div>

      <h3 style="font-size:13px;color:var(--text-muted);text-transform:uppercase;letter-spacing:1px;margin-bottom:12px">Friends (${friends.length})</h3>
      <div id="friends-list">
        ${friends.length ? friends.map(f => {
          const n = f.display_name || f.username || 'Unknown'
          const i = n[0].toUpperCase()
          return `
            <div class="friend-item">
              <div class="friend-info" data-id="${f.id}" style="cursor:pointer">
                <div class="friend-avatar">${i}</div>
                <div>
                  <div class="friend-name">${n}</div>
                  <div class="friend-sub">@${f.username || 'unknown'}</div>
                </div>
              </div>
            </div>
          `
        }).join('') : '<div class="text-muted" style="padding:20px 0">No friends yet</div>'}
      </div>
    </div>
  `

  const { count } = await supabase.from('posts').select('*', { count: 'exact', head: true }).eq('user_id', user.id)
  document.getElementById('post-count').textContent = count || 0

  document.getElementById('edit-profile-btn')?.addEventListener('click', () => {
    document.getElementById('edit-profile-form').classList.toggle('hidden')
  })

  document.getElementById('save-profile-btn')?.addEventListener('click', async () => {
    const display_name = document.getElementById('edit-display-name').value.trim()
    const username = document.getElementById('edit-username').value.trim()
    const bio = document.getElementById('edit-bio').value.trim()
    if (!username) return
    await supabase.from('profiles').update({ display_name, username, bio }).eq('id', user.id)
    store.fetchProfile(user.id)
    renderProfile(container, user, { navigate })
  })

  document.getElementById('signout-btn')?.addEventListener('click', async () => {
    await supabase.auth.signOut()
  })

  const themeToggle = document.getElementById('theme-toggle')
  if (themeToggle) {
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark'
    themeToggle.classList.toggle('dark', isDark)
    themeToggle.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme')
      const next = current === 'dark' ? 'light' : 'dark'
      document.documentElement.setAttribute('data-theme', next)
      themeToggle.classList.toggle('dark', next === 'dark')
      try { localStorage.setItem('ff_theme', next) } catch {}
    })
  }

  const history = useStore.getState().habitHistory
  let maxStreak = 0
  for (const h of ['exercise', 'no_sugar', 'no_smoking']) {
    const s = store.getStreak(h, history)
    if (s > maxStreak) maxStreak = s
  }
  const streakEl = document.getElementById('my-streak')
  if (streakEl) streakEl.textContent = maxStreak

  document.querySelectorAll('.friend-info').forEach(el => {
    el.addEventListener('click', () => navigate && navigate('/profile/' + el.dataset.id))
  })

  return () => {
    document.querySelectorAll('.bottom-nav a').forEach(a => {
      a.classList.remove('active')
      if (a.getAttribute('href') === '#/profile') a.classList.add('active')
    })
  }
}

export async function renderPublicProfile(container, user, profileUserId, { navigate }) {
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', profileUserId)
    .maybeSingle()
  if (!profile) {
    container.innerHTML = '<div class="screen fade-in"><div class="card"><div class="text-muted">User not found</div></div></div>'
    return
  }

  const initial = (profile.display_name || profile.username || '?')[0].toUpperCase()
  const { count } = await supabase.from('posts').select('*', { count: 'exact', head: true }).eq('user_id', profileUserId)

  const { data: friendshipRows } = await supabase
    .from('friendships')
    .select('sender_id, receiver_id, status')
    .or(`and(sender_id.eq.${user.id},receiver_id.eq.${profileUserId}),and(sender_id.eq.${profileUserId},receiver_id.eq.${user.id})`)

  let friendStatus = null
  if (friendshipRows?.length) {
    friendStatus = friendshipRows[0].status
  }

  const { count: theirFriendCount } = await supabase
    .from('friendships')
    .select('id', { count: 'exact', head: true })
    .or(`sender_id.eq.${profileUserId},receiver_id.eq.${profileUserId}`)
    .eq('status', 'accepted')

  container.innerHTML = `
    <div class="screen fade-in">
      <div class="profile-header card">
        <div class="avatar-large">${initial}</div>
        <h2>${profile.display_name || profile.username || 'Anonymous'}</h2>
        <span class="username">@${profile.username || 'unknown'}</span>
        ${profile.bio ? `<p class="bio">${profile.bio}</p>` : ''}
        <div class="profile-actions">
          ${profileUserId === user.id ? '' : `
            <button id="friend-action-btn" class="btn btn-sm ${friendStatus === 'pending' ? 'btn-secondary' : 'btn-primary'}" data-status="${friendStatus || 'none'}">
              ${friendStatus === 'accepted' ? '✓ Friends' : friendStatus === 'pending' ? 'Pending' : '+ Add Friend'}
            </button>
          `}
          <button id="back-btn" class="btn btn-secondary btn-sm" onclick="history.back()">Back</button>
        </div>
      </div>
      <div class="profile-stats">
        <div class="profile-stat">
          <div class="profile-stat-value">${theirFriendCount || 0}</div>
          <div class="profile-stat-label">Friends</div>
        </div>
        <div class="profile-stat">
          <div class="profile-stat-value" id="pub-streak">0</div>
          <div class="profile-stat-label">Streak</div>
        </div>
        <div class="profile-stat">
          <div class="profile-stat-value">${count || 0}</div>
          <div class="profile-stat-label">Posts</div>
        </div>
      </div>
    </div>
  `

  const store = useStore.getState()
  const userId = profileUserId
  await store.fetchHabitHistory(userId)
  const history = useStore.getState().habitHistory
  let maxStreak = 0
  const habits = ['exercise', 'no_sugar', 'no_smoking']
  for (const h of habits) {
    const s = store.getStreak(h, history)
    if (s > maxStreak) maxStreak = s
  }
  const streakEl = document.getElementById('pub-streak')
  if (streakEl) streakEl.textContent = maxStreak

  const friendBtn = document.getElementById('friend-action-btn')
  if (friendBtn) {
    if (friendBtn.dataset.status === 'accepted') friendBtn.style.opacity = '0.6'
    friendBtn.addEventListener('click', async () => {
      if (friendBtn.dataset.status === 'accepted' || friendBtn.dataset.status === 'pending') return
      await supabase.from('friendships').insert({
        sender_id: user.id,
        receiver_id: profileUserId,
        status: 'pending',
      })
      friendBtn.textContent = 'Sent ✓'
      friendBtn.dataset.status = 'pending'
      friendBtn.style.opacity = '0.6'
    })
  }
}
