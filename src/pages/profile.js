import { supabase } from '../lib/supabase.js'

export async function renderProfile(container, currentUser, { params, navigate }) {
  const profileId = params?.id || currentUser.id
  const isOwn = profileId === currentUser.id

  container.innerHTML = `
    <div class="page">
      <div class="loading"><div class="spinner"></div></div>
    </div>
  `

  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', profileId)
    .single()

  if (!profile) {
    container.innerHTML = '<div class="page"><div class="empty-state">Profile not found</div></div>'
    return
  }

  const { count: friendCount } = await supabase
    .from('friendships')
    .select('*', { count: 'exact', head: true })
    .or(`sender_id.eq.${profileId},receiver_id.eq.${profileId}`)
    .eq('status', 'accepted')

  const { count: postCount } = await supabase
    .from('posts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', profileId)

  let friendshipStatus = null
  if (!isOwn) {
    const { data: f1 } = await supabase
      .from('friendships')
      .select('*')
      .eq('sender_id', currentUser.id)
      .eq('receiver_id', profileId)
      .maybeSingle()

    const { data: f2 } = await supabase
      .from('friendships')
      .select('*')
      .eq('sender_id', profileId)
      .eq('receiver_id', currentUser.id)
      .maybeSingle()

    friendshipStatus = f1 || f2
  }

  const initial = (profile.display_name || profile.username || '?')[0].toUpperCase()

  container.innerHTML = `
    <div class="page fade-in">
      <div class="profile-header card">
        <div class="avatar-large">${initial}</div>
        <h2>${profile.display_name || profile.username}</h2>
        <span class="username">@${profile.username}</span>
        ${profile.bio ? `<p class="bio">${profile.bio}</p>` : ''}
        <div style="display:flex;gap:24px;margin-top:16px;font-size:14px">
          <span><strong>${postCount || 0}</strong> posts</span>
          <span><strong>${friendCount || 0}</strong> friends</span>
        </div>
        ${isOwn ? `
          <div class="profile-actions">
            <button id="edit-profile-btn" class="btn btn-secondary btn-sm">Edit Profile</button>
            <button id="signout-btn" class="btn btn-danger btn-sm">Sign Out</button>
          </div>
        ` : `
          <div class="profile-actions">
            ${!friendshipStatus
              ? `<button id="friend-action" class="btn btn-primary btn-sm" data-action="add">+ Add Friend</button>`
              : friendshipStatus.status === 'pending'
                ? friendshipStatus.sender_id === currentUser.id
                  ? `<button class="btn btn-secondary btn-sm" disabled>Request Sent</button>`
                  : `<button id="friend-action" class="btn btn-primary btn-sm" data-action="accept">Accept Request</button>`
                : `<button class="btn btn-secondary btn-sm" disabled>✅ Friends</button>`
            }
          </div>
        `}
      </div>

      ${isOwn ? `
        <div id="edit-profile-form" class="card hidden">
          <div class="flex flex-col gap-8">
            <input type="text" id="edit-display-name" placeholder="Display Name" value="${profile.display_name || ''}" />
            <input type="text" id="edit-username" placeholder="Username" value="${profile.username}" />
            <textarea id="edit-bio" placeholder="Bio">${profile.bio || ''}</textarea>
            <button id="save-profile-btn" class="btn btn-primary">Save</button>
          </div>
        </div>
      ` : ''}

      <h3 class="text-muted" style="font-size:13px;margin-bottom:12px;text-transform:uppercase;letter-spacing:1px">Recent Posts</h3>
      <div id="profile-posts">
        <div class="loading"><div class="spinner"></div></div>
      </div>
    </div>
  `

  loadProfilePosts()

  if (isOwn) {
    document.getElementById('edit-profile-btn')?.addEventListener('click', () => {
      const form = document.getElementById('edit-profile-form')
      form.classList.toggle('hidden')
    })

    document.getElementById('save-profile-btn')?.addEventListener('click', async () => {
      const display_name = document.getElementById('edit-display-name').value.trim()
      const username = document.getElementById('edit-username').value.trim()
      const bio = document.getElementById('edit-bio').value.trim()

      if (!username) return

      await supabase.from('profiles').update({ display_name, username, bio }).eq('id', currentUser.id)
      renderProfile(container, currentUser, { params, navigate })
    })

    document.getElementById('signout-btn')?.addEventListener('click', async () => {
      await supabase.auth.signOut()
    })
  }

  document.getElementById('friend-action')?.addEventListener('click', async (e) => {
    const action = e.target.dataset.action
    if (action === 'add') {
      const { error } = await supabase.from('friendships').insert({
        sender_id: currentUser.id,
        receiver_id: profileId,
        status: 'pending'
      })
      if (!error) {
        await supabase.from('notifications').insert({
          user_id: profileId,
          from_user_id: currentUser.id,
          type: 'friend_request',
          message: `${profile.display_name || profile.username} sent you a friend request`
        })
        renderProfile(container, currentUser, { params, navigate })
      }
    } else if (action === 'accept') {
      const { error } = await supabase
        .from('friendships')
        .update({ status: 'accepted' })
        .eq('id', friendshipStatus.id)
      if (!error) {
        await supabase.from('notifications').insert({
          user_id: profileId,
          from_user_id: currentUser.id,
          type: 'friend_accept',
          message: `${profile.display_name || profile.username} accepted your friend request`
        })
        renderProfile(container, currentUser, { params, navigate })
      }
    }
  })

  async function loadProfilePosts() {
    const { data: posts } = await supabase
      .from('posts')
      .select('*')
      .eq('user_id', profileId)
      .order('created_at', { ascending: false })
      .limit(20)

    const postsEl = document.getElementById('profile-posts')
    if (!posts?.length) {
      postsEl.innerHTML = '<div class="empty-state text-muted">No posts yet</div>'
      return
    }

    postsEl.innerHTML = posts.map(post => {
      const typeLabels = {
        fasting: '🍽️ Fasting',
        exercise: '💪 Exercise',
        workout_complete: '✅ Workout Complete',
        fasting_complete: '✅ Fast Complete',
        general: '💬 General',
      }
      const durationStr = post.duration_minutes ? ` · ${post.duration_minutes} min` : ''
      return `
        <div class="card post fade-in">
          <div class="avatar">${initial}</div>
          <div class="post-body">
            <div class="post-header">
              <span class="name">${profile.display_name || profile.username || 'Anonymous'}</span>
              <span class="time">${new Date(post.created_at).toLocaleDateString()}</span>
            </div>
            <div class="post-type-badge ${post.type === 'fasting' ? 'fasting' : post.type.includes('complete') ? 'complete' : 'exercise'}">${typeLabels[post.type] || post.type}${durationStr}</div>
            <div class="post-content">${post.content}</div>
          </div>
        </div>
      `
    }).join('')
  }

  return () => {}
}
