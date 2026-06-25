import { supabase } from '../lib/supabase.js'

export async function renderFriends(container, user, { navigate }) {
  container.innerHTML = `
    <div class="page fade-in">
      <h2 style="margin-bottom:16px">Friends</h2>

      <div class="friend-search">
        <input type="text" id="friend-search-input" placeholder="Search users by username..." />
        <div id="search-results" class="card hidden" style="margin-top:8px;padding:12px"></div>
      </div>

      <div style="display:flex;gap:8px;margin-bottom:16px">
        <button id="tab-friends" class="btn btn-primary btn-sm">Friends</button>
        <button id="tab-requests" class="btn btn-secondary btn-sm">Requests</button>
        <button id="tab-sent" class="btn btn-secondary btn-sm">Sent</button>
      </div>

      <div id="friends-list">
        <div class="loading"><div class="spinner"></div></div>
      </div>
    </div>
  `

  let currentTab = 'friends'

  async function loadFriends() {
    const list = document.getElementById('friends-list')
    list.innerHTML = '<div class="loading"><div class="spinner"></div></div>'

    if (currentTab === 'friends') {
      const { data: sent } = await supabase
        .from('friendships')
        .select('*, receiver:receiver_id(username, display_name)')
        .eq('sender_id', user.id)
        .eq('status', 'accepted')

      const { data: received } = await supabase
        .from('friendships')
        .select('*, sender:sender_id(username, display_name)')
        .eq('receiver_id', user.id)
        .eq('status', 'accepted')

      const friends = [...(sent || []).map(f => ({ ...f.receiver, friendship_id: f.id })), ...(received || []).map(f => ({ ...f.sender, friendship_id: f.id }))]

      if (!friends.length) {
        list.innerHTML = '<div class="empty-state"><p>No friends yet. Search for users to add!</p></div>'
        return
      }

      list.innerHTML = friends.map(f => {
        const name = f.display_name || f.username || 'Unknown'
        const initial = name[0].toUpperCase()
        return `
          <div class="friend-item fade-in">
            <div class="friend-info" data-id="${f.id}" style="cursor:pointer">
              <div class="friend-avatar">${initial}</div>
              <div>
                <div class="friend-name">${name}</div>
                <div class="friend-sub">@${f.username || 'unknown'}</div>
              </div>
            </div>
            <button class="btn btn-danger btn-sm remove-friend" data-fid="${f.friendship_id}">Remove</button>
          </div>
        `
      }).join('')

      list.querySelectorAll('.friend-info').forEach(el => {
        el.addEventListener('click', () => navigate('/profile/' + el.dataset.id))
      })

      list.querySelectorAll('.remove-friend').forEach(btn => {
        btn.addEventListener('click', async () => {
          await supabase.from('friendships').delete().eq('id', btn.dataset.fid)
          loadFriends()
        })
      })
    } else if (currentTab === 'requests') {
      const { data: requests } = await supabase
        .from('friendships')
        .select('*, sender:sender_id(username, display_name)')
        .eq('receiver_id', user.id)
        .eq('status', 'pending')

      if (!requests?.length) {
        list.innerHTML = '<div class="empty-state"><p>No pending requests</p></div>'
        return
      }

      list.innerHTML = requests.map(r => {
        const name = r.sender?.display_name || r.sender?.username || 'Unknown'
        const initial = name[0].toUpperCase()
        return `
          <div class="friend-item fade-in">
            <div class="friend-info" data-id="${r.sender_id}" style="cursor:pointer">
              <div class="friend-avatar">${initial}</div>
              <div>
                <div class="friend-name">${name}</div>
                <div class="friend-sub">@${r.sender?.username || 'unknown'}</div>
              </div>
            </div>
            <div style="display:flex;gap:6px">
              <button class="btn btn-primary btn-sm accept-request" data-id="${r.id}" data-from="${r.sender_id}">Accept</button>
              <button class="btn btn-danger btn-sm decline-request" data-id="${r.id}">✕</button>
            </div>
          </div>
        `
      }).join('')

      list.querySelectorAll('.friend-info').forEach(el => {
        el.addEventListener('click', () => navigate('/profile/' + el.dataset.id))
      })

      list.querySelectorAll('.accept-request').forEach(btn => {
        btn.addEventListener('click', async () => {
          await supabase.from('friendships').update({ status: 'accepted' }).eq('id', btn.dataset.id)
          await supabase.from('notifications').insert({
            user_id: btn.dataset.from,
            from_user_id: user.id,
            type: 'friend_accept',
            message: 'accepted your friend request'
          })
          loadFriends()
        })
      })

      list.querySelectorAll('.decline-request').forEach(btn => {
        btn.addEventListener('click', async () => {
          await supabase.from('friendships').update({ status: 'declined' }).eq('id', btn.dataset.id)
          loadFriends()
        })
      })
    } else if (currentTab === 'sent') {
      const { data: sent } = await supabase
        .from('friendships')
        .select('*, receiver:receiver_id(username, display_name)')
        .eq('sender_id', user.id)
        .eq('status', 'pending')

      if (!sent?.length) {
        list.innerHTML = '<div class="empty-state"><p>No pending requests</p></div>'
        return
      }

      list.innerHTML = sent.map(s => {
        const name = s.receiver?.display_name || s.receiver?.username || 'Unknown'
        const initial = name[0].toUpperCase()
        return `
          <div class="friend-item fade-in">
            <div class="friend-info" data-id="${s.receiver_id}" style="cursor:pointer">
              <div class="friend-avatar">${initial}</div>
              <div>
                <div class="friend-name">${name}</div>
                <div class="friend-sub">@${s.receiver?.username || 'unknown'}</div>
              </div>
            </div>
            <button class="btn btn-danger btn-sm cancel-request" data-id="${s.id}">Cancel</button>
          </div>
        `
      }).join('')

      list.querySelectorAll('.friend-info').forEach(el => {
        el.addEventListener('click', () => navigate('/profile/' + el.dataset.id))
      })

      list.querySelectorAll('.cancel-request').forEach(btn => {
        btn.addEventListener('click', async () => {
          await supabase.from('friendships').delete().eq('id', btn.dataset.id)
          loadFriends()
        })
      })
    }
  }

  document.getElementById('tab-friends').addEventListener('click', () => {
    currentTab = 'friends'
    document.getElementById('tab-friends').className = 'btn btn-primary btn-sm'
    document.getElementById('tab-requests').className = 'btn btn-secondary btn-sm'
    document.getElementById('tab-sent').className = 'btn btn-secondary btn-sm'
    loadFriends()
  })

  document.getElementById('tab-requests').addEventListener('click', () => {
    currentTab = 'requests'
    document.getElementById('tab-friends').className = 'btn btn-secondary btn-sm'
    document.getElementById('tab-requests').className = 'btn btn-primary btn-sm'
    document.getElementById('tab-sent').className = 'btn btn-secondary btn-sm'
    loadFriends()
  })

  document.getElementById('tab-sent').addEventListener('click', () => {
    currentTab = 'sent'
    document.getElementById('tab-friends').className = 'btn btn-secondary btn-sm'
    document.getElementById('tab-requests').className = 'btn btn-secondary btn-sm'
    document.getElementById('tab-sent').className = 'btn btn-primary btn-sm'
    loadFriends()
  })

  loadFriends()

  let searchTimeout
  document.getElementById('friend-search-input').addEventListener('input', (e) => {
    clearTimeout(searchTimeout)
    const q = e.target.value.trim()
    if (q.length < 2) {
      document.getElementById('search-results').classList.add('hidden')
      return
    }
    searchTimeout = setTimeout(async () => {
      const { data: results } = await supabase
        .from('profiles')
        .select('id, username, display_name')
        .ilike('username', `%${q}%`)
        .limit(10)

      const resultsEl = document.getElementById('search-results')
      if (!results?.length) {
        resultsEl.innerHTML = '<div class="text-muted">No users found</div>'
        resultsEl.classList.remove('hidden')
        return
      }

      resultsEl.innerHTML = results.map(r => {
        const name = r.display_name || r.username
        const initial = name[0].toUpperCase()
        return `
          <div class="friend-item" style="cursor:pointer" data-id="${r.id}">
            <div class="friend-info">
              <div class="friend-avatar">${initial}</div>
              <div>
                <div class="friend-name">${name}</div>
                <div class="friend-sub">@${r.username}</div>
              </div>
            </div>
          </div>
        `
      }).join('')
      resultsEl.classList.remove('hidden')

      resultsEl.querySelectorAll('.friend-item').forEach(el => {
        el.addEventListener('click', () => {
          navigate('/profile/' + el.dataset.id)
        })
      })
    }, 300)
  })

  return () => {}
}
