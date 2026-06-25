import { supabase } from '../lib/supabase.js'

export async function renderTimers(container, user, { navigate }) {
  container.innerHTML = `
    <div class="page fade-in">
      <h2 style="margin-bottom:16px">⏱️ Timer</h2>

      <div class="timer-type-selector">
        <button id="timer-type-fasting" class="active">🍽️ Fasting</button>
        <button id="timer-type-workout" class="workout-btn">💪 Workout</button>
      </div>

      <div class="card timer-card" id="timer-card">
        <div id="timer-no-active">
          <p class="text-muted text-center mb-16">Start a new timer</p>
          <div class="timer-input-group">
            <input type="number" id="timer-target" placeholder="Target (min)" min="1" value="60" />
          </div>
          <div class="timer-input-group">
            <input type="text" id="timer-note" placeholder="Note (e.g. OMAD, upper body)" />
          </div>
          <button id="timer-start-btn" class="btn btn-primary btn-block">Start Timer</button>
        </div>

        <div id="timer-active" class="hidden">
          <div class="timer-display" id="timer-display">00:00:00</div>
          <div class="timer-progress">
            <div class="timer-progress-bar" id="timer-progress-bar"></div>
          </div>
          <div class="text-muted" id="timer-label" style="font-size:13px"></div>
          <div class="timer-note" id="timer-active-note"></div>
          <div class="timer-controls mt-16">
            <button id="timer-complete-btn" class="btn btn-primary">✅ Complete</button>
            <button id="timer-stop-btn" class="btn btn-danger">Stop</button>
          </div>
        </div>
      </div>

      <h3 class="text-muted" style="font-size:13px;margin-bottom:12px;margin-top:24px;text-transform:uppercase;letter-spacing:1px">History</h3>
      <div id="timer-history">
        <div class="loading"><div class="spinner"></div></div>
      </div>
    </div>
  `

  let currentType = 'fasting'
  let activeTimer = null
  let tickInterval = null

  document.getElementById('timer-type-fasting').addEventListener('click', () => {
    currentType = 'fasting'
    document.getElementById('timer-type-fasting').className = 'active'
    document.getElementById('timer-type-workout').className = 'workout-btn'
    document.getElementById('timer-target').value = localStorage.getItem('ff_last_fasting') || '60'
    updateTimerUI()
  })

  document.getElementById('timer-type-workout').addEventListener('click', () => {
    currentType = 'workout'
    document.getElementById('timer-type-workout').className = 'active workout-btn'
    document.getElementById('timer-type-fasting').className = ''
    document.getElementById('timer-target').value = localStorage.getItem('ff_last_workout') || '45'
    updateTimerUI()
  })

  async function checkActiveTimer() {
    const { data } = await supabase
      .from('active_timers')
      .select('*')
      .eq('user_id', user.id)
      .eq('active', true)
      .order('started_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (data) {
      currentType = data.type
      activeTimer = data
      if (data.type === 'fasting') {
        document.getElementById('timer-type-fasting').click()
      } else {
        document.getElementById('timer-type-workout').click()
      }
      showActiveTimer()
    }
  }

  function updateTimerUI() {
    if (activeTimer) return
    document.getElementById('timer-no-active').classList.remove('hidden')
    document.getElementById('timer-active').classList.add('hidden')

    const target = document.getElementById('timer-target')
    if (currentType === 'fasting') {
      target.placeholder = 'Target (hours)'
      target.value = localStorage.getItem('ff_last_fasting') || '16'
    } else {
      target.placeholder = 'Target (min)'
      target.value = localStorage.getItem('ff_last_workout') || '45'
    }
  }

  updateTimerUI()
  await checkActiveTimer()
  await loadHistory()

  document.getElementById('timer-start-btn').addEventListener('click', async () => {
    let target = parseInt(document.getElementById('timer-target').value)
    const note = document.getElementById('timer-note').value.trim()

    if (!target || target < 1) target = currentType === 'fasting' ? 16 : 45

    if (currentType === 'fasting') {
      localStorage.setItem('ff_last_fasting', String(target))
      target = target * 60
    } else {
      localStorage.setItem('ff_last_workout', String(target))
    }

    const { data, error } = await supabase.from('active_timers').insert({
      user_id: user.id,
      type: currentType,
      target_minutes: target,
      note,
      active: true
    }).select().single()

    if (!error && data) {
      activeTimer = data
      showActiveTimer()
    }
  })

  document.getElementById('timer-complete-btn').addEventListener('click', async () => {
    if (!activeTimer) return
    await completeTimer(true)
  })

  document.getElementById('timer-stop-btn').addEventListener('click', async () => {
    if (!activeTimer) return
    await completeTimer(false)
  })

  async function completeTimer(goalMet) {
    if (tickInterval) {
      clearInterval(tickInterval)
      tickInterval = null
    }

    const elapsed = Math.floor((Date.now() - new Date(activeTimer.started_at).getTime()) / 1000)
    const elapsedMin = Math.round(elapsed / 60)

    await supabase.from('active_timers').update({ active: false }).eq('id', activeTimer.id)

    const postType = activeTimer.type === 'fasting'
      ? (goalMet ? 'fasting_complete' : 'fasting')
      : (goalMet ? 'workout_complete' : 'exercise')

    const content = goalMet
      ? `Completed ${activeTimer.type} goal${activeTimer.note ? ': ' + activeTimer.note : ''} — ${elapsedMin} min`
      : `${activeTimer.type === 'fasting' ? 'Fasted' : 'Worked out'} for ${elapsedMin} min${activeTimer.note ? ': ' + activeTimer.note : ''}`

    const { data: post } = await supabase.from('posts').insert({
      user_id: user.id,
      type: postType,
      content,
      duration_minutes: elapsedMin,
    }).select().single()

    if (goalMet) {
      const { data: friends } = await supabase
        .from('friendships')
        .select('sender_id, receiver_id')
        .or(`sender_id.eq.${user.id},receiver_id.eq.${user.id}`)
        .eq('status', 'accepted')

      if (friends) {
        const friendIds = friends.map(f => f.sender_id === user.id ? f.receiver_id : f.sender_id)
        const label = activeTimer.type === 'fasting' ? '🍽️ fast' : '💪 workout'
        const notifs = friendIds.map(fid => ({
          user_id: fid,
          from_user_id: user.id,
          type: 'goal_complete',
          message: `completed a ${label} goal! (${elapsedMin} min)`
        }))
        if (notifs.length) {
          await supabase.from('notifications').insert(notifs)
        }
      }
    }

    activeTimer = null
    updateTimerUI()
    await loadHistory()
  }

  function showActiveTimer() {
    document.getElementById('timer-no-active').classList.add('hidden')
    document.getElementById('timer-active').classList.remove('hidden')

    const display = document.getElementById('timer-display')
    const progressBar = document.getElementById('timer-progress-bar')
    const label = document.getElementById('timer-label')
    const note = document.getElementById('timer-active-note')

    display.className = 'timer-display' + (activeTimer.type === 'workout' ? ' workout' : '')
    progressBar.className = 'timer-progress-bar' + (activeTimer.type === 'workout' ? ' workout' : '')

    const targetLabel = activeTimer.type === 'fasting'
      ? `Target: ${Math.round(activeTimer.target_minutes / 60 * 10) / 10}h`
      : `Target: ${activeTimer.target_minutes} min`

    label.textContent = `${activeTimer.type === 'fasting' ? '🍽️ Fasting' : '💪 Workout'} · ${targetLabel}`
    note.textContent = activeTimer.note || ''

    if (tickInterval) clearInterval(tickInterval)
    tickInterval = setInterval(() => {
      const elapsed = Math.floor((Date.now() - new Date(activeTimer.started_at).getTime()) / 1000)
      const hrs = Math.floor(elapsed / 3600)
      const mins = Math.floor((elapsed % 3600) / 60)
      const secs = elapsed % 60
      display.textContent = `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`

      const targetSecs = activeTimer.target_minutes * 60
      const pct = Math.min((elapsed / targetSecs) * 100, 100)
      progressBar.style.width = pct + '%'
    }, 1000)
  }

  async function loadHistory() {
    const { data: timers } = await supabase
      .from('active_timers')
      .select('*')
      .eq('user_id', user.id)
      .eq('active', false)
      .order('started_at', { ascending: false })
      .limit(20)

    const el = document.getElementById('timer-history')
    if (!timers?.length) {
      el.innerHTML = '<div class="empty-state text-muted">No timer history yet</div>'
      return
    }

    el.innerHTML = timers.map(t => {
      const elapsed = Math.floor((new Date(t.started_at).getTime()) / 1000)
      const duration = t.target_minutes
      const label = t.type === 'fasting' ? '🍽️ Fast' : '💪 Workout'
      return `
        <div class="card fade-in" style="padding:12px">
          <div style="display:flex;justify-content:space-between;align-items:center">
            <div>
              <strong>${label}</strong>
              ${t.note ? `<span class="text-muted">· ${t.note}</span>` : ''}
            </div>
            <span class="text-muted" style="font-size:13px">${duration} min target</span>
          </div>
          <div class="text-muted" style="font-size:12px;margin-top:4px">${new Date(t.started_at).toLocaleDateString()}</div>
        </div>
      `
    }).join('')
  }

  return () => {
    if (tickInterval) clearInterval(tickInterval)
  }
}
