import { supabase } from '../lib/supabase.js'
import { useStore } from '../store/useStore.js'

export async function renderProfile(container, user, { navigate }) {
  const store = useStore.getState()
  store.setUser(user)
  if (!store.profile) await store.fetchProfile(user.id)
  await store.fetchFriends(user.id)
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
          <div class="profile-stat-value">🔥</div>
          <div class="profile-stat-label">Streak</div>
        </div>
        <div class="profile-stat">
          <div class="profile-stat-value" id="post-count">0</div>
          <div class="profile-stat-label">Posts</div>
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
