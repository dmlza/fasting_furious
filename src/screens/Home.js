import { supabase } from '../lib/supabase.js'
import { useStore } from '../store/useStore.js'
import { renderShareCanvas } from '../utils/shareCanvas.js'

const FASTING_PRESETS = {
  '16:8': 16 * 60,
  '18:6': 18 * 60,
  '20:4': 20 * 60,
}

const HABIT_TARGETS = {
  exercise: 30,
}

export async function renderHome(container, user) {
  const store = useStore.getState()
  store.setUser(user)
  if (!store.profile) await store.fetchProfile(user.id)
  await store.fetchHabits(user.id)
  await store.fetchActiveTimer(user.id)
  await store.fetchHabitHistory(user.id)

  container.innerHTML = `
    <div class="screen fade-in">
      <div class="bento-grid">

        <div class="hero-card" id="hero-card">
          <div class="hero-card-body">
            <div class="hero-left">
              <div class="live-timer" id="timer-display">--:--:--</div>
              <div class="timer-status" id="timer-phase-label">READY</div>
              <div class="preset-row" id="timer-presets">
                ${Object.keys(FASTING_PRESETS).map(p =>
                  `<button class="preset-pill" data-preset="${p}">${p}</button>`
                ).join('')}
              </div>
              <div class="timer-actions" id="timer-ring-start">
                <button class="hero-start-btn" id="timer-start-btn">Start Fast</button>
              </div>
              <div class="timer-actions hidden" id="timer-ring-active">
                <button class="hero-stop-btn" id="timer-stop-btn">End Fast</button>
              </div>
            </div>
            <div class="hero-right">
              <div class="activity-rings" id="activity-rings">
                <svg viewBox="0 0 180 180">
                  <circle class="ring-bg" cx="90" cy="90" r="82" stroke="#E8E3DC" stroke-width="6" fill="none"/>
                  <circle class="ring-fg ring-fg-outer" id="ring-outer" cx="90" cy="90" r="82" stroke="none" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="515" stroke-dashoffset="515"/>
                  <circle class="ring-bg" cx="90" cy="90" r="68" stroke="rgba(0,0,0,0.06)" stroke-width="6" fill="none"/>
                  <circle class="ring-fg ring-fg-mid" id="ring-mid" cx="90" cy="90" r="68" stroke="none" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="427" stroke-dashoffset="427"/>
                  <circle class="ring-bg" cx="90" cy="90" r="54" stroke="rgba(0,0,0,0.06)" stroke-width="6" fill="none"/>
                  <circle class="ring-fg ring-fg-inner" id="ring-inner" cx="90" cy="90" r="54" stroke="none" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="339" stroke-dashoffset="339"/>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <div class="bento-row">
          <div class="bento-card sugar-card" id="sugar-card">
            <div class="streak-display" id="sugar-streak">🔥 --</div>
            <div class="streak-label">No Sugar Streak</div>
            <div class="streak-sub">Tap to view history</div>
          </div>
          <div class="bento-card exercise-card" id="exercise-card">
            <div class="exercise-head">
              <span class="exercise-icon">🏃</span>
              <button class="exercise-add-btn" id="exercise-add-btn">+</button>
            </div>
            <div class="exercise-stats" id="exercise-stats">0 / ${HABIT_TARGETS.exercise} min</div>
            <div class="exercise-label">Today's Workout</div>
          </div>
        </div>

        <div class="bento-card smoking-card" id="smoking-card">
          <div class="smoking-left">
            <div class="streak-display smoke-streak" id="smoking-streak">🔥 --</div>
            <div class="streak-label">No Smoking Streak</div>
          </div>
          <div class="smoking-toggle-wrap">
            <div class="smoking-toggle" id="smoking-toggle">
              <div class="smoking-toggle-knob"></div>
            </div>
          </div>
        </div>

      </div>

      <div class="share-btn-wrap">
        <button class="share-btn" id="share-status-btn">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
          Update & Share Status
        </button>
      </div>
    </div>
  `

  initTimer()
  initHabits()
  initExercise()
  initShare()
  updateRings()

  function initHabits() {
    const state = useStore.getState()
    const history = state.habitHistory
    const habits = state.habits

    const sugarStreak = getStreak('no_sugar', history)
    document.getElementById('sugar-streak').textContent = `🔥 ${sugarStreak} Day${sugarStreak !== 1 ? 's' : ''}`

    const smokeStreak = getStreak('no_smoking', history)
    document.getElementById('smoking-streak').textContent = `🔥 ${smokeStreak} Day${smokeStreak !== 1 ? 's' : ''}`

    const toggle = document.getElementById('smoking-toggle')
    if (habits.no_smoking) toggle.classList.add('checked')

    toggle.addEventListener('click', async (e) => {
      e.stopPropagation()
      await useStore.getState().toggleHabit('no_smoking')
      const updated = useStore.getState().habits
      toggle.classList.toggle('checked', updated.no_smoking)
      const newHistory = useStore.getState().habitHistory
      const s = getStreak('no_smoking', newHistory)
      document.getElementById('smoking-streak').textContent = `🔥 ${s} Day${s !== 1 ? 's' : ''}`
      updateRings()
    })

    document.getElementById('sugar-card').addEventListener('click', () => {
      openContributionModal(history)
    })
  }

  function getStreak(habit, list) {
    if (!list?.length) return 0
    let streak = 0
    for (let i = list.length - 1; i >= 0; i--) {
      if (list[i][habit]) streak++
      else break
    }
    return streak
  }

  function openContributionModal(history) {
    const overlay = document.createElement('div')
    overlay.className = 'modal-overlay'
    overlay.innerHTML = `
      <div class="modal-content contribution-modal">
        <button class="close-modal" id="close-contrib">&times;</button>
        <h3>📅 Sugar-Free History</h3>
        <div class="contrib-grid" id="contrib-grid"></div>
      </div>
    `
    document.body.appendChild(overlay)

    const grid = overlay.querySelector('#contrib-grid')
    const weeks = 13
    const days = weeks * 7
    const cells = []

    for (let i = days - 1; i >= 0; i--) {
      const d = new Date()
      d.setDate(d.getDate() - i)
      const dateStr = d.toISOString().split('T')[0]
      const entry = history.find(h => h.date === dateStr)
      const done = entry?.no_sugar || false
      cells.push(`<div class="contrib-cell ${done ? 'filled' : ''}" title="${dateStr}"></div>`)
    }

    grid.innerHTML = cells.join('')

    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove()
    })
    overlay.querySelector('#close-contrib').addEventListener('click', () => overlay.remove())
  }

  function initExercise() {
    const state = useStore.getState()
    const minutes = state.habits.exercise_minutes || 0
    document.getElementById('exercise-stats').textContent = `${minutes} / ${HABIT_TARGETS.exercise} min`

    document.getElementById('exercise-add-btn').addEventListener('click', (e) => {
      e.stopPropagation()
      openExerciseModal()
    })

    document.getElementById('exercise-card').addEventListener('click', () => {
      openExerciseModal()
    })
  }

  function openExerciseModal() {
    const overlay = document.createElement('div')
    overlay.className = 'modal-overlay'
    overlay.innerHTML = `
      <div class="modal-content exercise-modal">
        <button class="close-modal" id="close-exercise">&times;</button>
        <h3>🏃 Log Workout Minutes</h3>
        <div class="exercise-presets" id="exercise-presets">
          ${[5, 10, 15, 20, 30, 45].map(m =>
            `<button class="exercise-preset-btn" data-min="${m}">${m} min</button>`
          ).join('')}
        </div>
        <div class="exercise-custom-row">
          <input type="number" id="exercise-custom-input" placeholder="Custom minutes" min="1" max="999" />
          <button class="exercise-preset-btn primary" id="exercise-custom-add">Add</button>
        </div>
      </div>
    `
    document.body.appendChild(overlay)

    const doLog = async (minutes) => {
      const store = useStore.getState()
      await store.logExerciseMinutes(minutes)
      await store.fetchHabitHistory(store.user.id)
      const updated = useStore.getState().habits
      const total = updated.exercise_minutes || 0
      document.getElementById('exercise-stats').textContent = `${total} / ${HABIT_TARGETS.exercise} min`
      updateRings()
      overlay.remove()
    }

    overlay.querySelectorAll('.exercise-preset-btn').forEach(btn => {
      btn.addEventListener('click', () => doLog(parseInt(btn.dataset.min)))
    })
    overlay.querySelector('#exercise-custom-add').addEventListener('click', () => {
      const val = parseInt(overlay.querySelector('#exercise-custom-input').value)
      if (val > 0) doLog(val)
    })
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) overlay.remove()
    })
    overlay.querySelector('#close-exercise').addEventListener('click', () => overlay.remove())
  }

  function updateRings() {
    const state = useStore.getState()
    const habits = state.habits
    const timer = state.activeTimer

    const outerRing = document.getElementById('ring-outer')
    const midRing = document.getElementById('ring-mid')
    const innerRing = document.getElementById('ring-inner')

    const outerCirc = 515
    const midCirc = 427
    const innerCirc = 339

    if (timer && timer.target_minutes) {
      const started = new Date(timer.started_at).getTime()
      const elapsed = (Date.now() - started) / 1000 / 60
      const progress = Math.min(elapsed / timer.target_minutes, 1)
      outerRing.style.strokeDashoffset = String(outerCirc * (1 - progress))
      outerRing.setAttribute('stroke', '#6CB49C')
    } else {
      outerRing.style.strokeDashoffset = String(outerCirc)
      outerRing.setAttribute('stroke', '#E8E3DC')
    }

    const exerciseMin = habits.exercise_minutes || 0
    const exerciseProgress = Math.min(exerciseMin / HABIT_TARGETS.exercise, 1)
    midRing.style.strokeDashoffset = String(midCirc * (1 - exerciseProgress))
    midRing.setAttribute('stroke', exerciseProgress > 0 ? '#F4DFD4' : '#E8E3DC')

    const sugarStreak = getStreak('no_sugar', state.habitHistory)
    const smokeStreak = getStreak('no_smoking', state.habitHistory)
    const habitScore = Math.min((sugarStreak + smokeStreak) / 20, 1)
    innerRing.style.strokeDashoffset = String(innerCirc * (1 - habitScore))
    innerRing.setAttribute('stroke', habitScore > 0 ? '#DCE7F3' : '#E8E3DC')
  }

  function initTimer() {
    const activeTimer = useStore.getState().activeTimer
    let tickInterval = null
    let selectedPreset = '16:8'

    if (activeTimer) {
      document.getElementById('timer-ring-start').classList.add('hidden')
      document.getElementById('timer-ring-active').classList.remove('hidden')
      startTick(activeTimer)
    }

    document.querySelectorAll('.preset-pill').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.preset-pill').forEach(b => b.classList.remove('active'))
        btn.classList.add('active')
        selectedPreset = btn.dataset.preset
      })
    })
    document.querySelector('[data-preset="16:8"]').classList.add('active')

    document.getElementById('timer-start-btn').addEventListener('click', async () => {
      const targetMin = FASTING_PRESETS[selectedPreset] || parseInt(prompt('Target minutes:')) || 960
      const { data, error } = await supabase.from('active_timers').insert({
        user_id: user.id,
        type: 'fasting',
        target_minutes: targetMin,
        preset_type: FASTING_PRESETS[selectedPreset] ? selectedPreset : 'custom',
        active: true,
      }).select().single()

      if (!error && data) {
        useStore.getState().setActiveTimer(data)
        document.getElementById('timer-ring-start').classList.add('hidden')
        document.getElementById('timer-ring-active').classList.remove('hidden')
        startTick(data)
      }
    })

    document.getElementById('timer-stop-btn').addEventListener('click', async () => {
      const timer = useStore.getState().activeTimer
      if (timer) {
        const elapsed = Math.floor((Date.now() - new Date(timer.started_at).getTime()) / 1000)
        const type = elapsed >= timer.target_minutes * 60 ? 'fasting_complete' : 'fasting'
        await supabase.from('active_timers').update({ active: false }).eq('id', timer.id)
        await supabase.from('posts').insert({
          user_id: user.id,
          type,
          content: type === 'fasting_complete' ? 'Completed a fast!' : 'Broke fast early',
          duration_minutes: Math.floor(elapsed / 60),
        })
        useStore.getState().setActiveTimer(null)
        if (tickInterval) clearInterval(tickInterval)
        document.getElementById('timer-ring-start').classList.remove('hidden')
        document.getElementById('timer-ring-active').classList.add('hidden')
        document.getElementById('timer-display').textContent = '--:--:--'
        document.getElementById('timer-phase-label').textContent = 'READY'
        updateRings()
      }
    })

    function startTick(timer) {
      if (tickInterval) clearInterval(tickInterval)
      tickInterval = setInterval(() => {
        const now = Date.now()
        const started = new Date(timer.started_at).getTime()
        const elapsed = Math.floor((now - started) / 1000)
        const targetSec = timer.target_minutes * 60
        const remaining = Math.max(0, targetSec - elapsed)

        const h = Math.floor(remaining / 3600)
        const m = Math.floor((remaining % 3600) / 60)
        const s = remaining % 60
        document.getElementById('timer-display').textContent =
          `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`

        if (remaining > 0) {
          document.getElementById('timer-phase-label').textContent = 'FASTING WINDOW'
        } else {
          document.getElementById('timer-phase-label').textContent = '✅ EATING WINDOW'
        }
        updateRings()
      }, 1000)
    }
  }

  function initShare() {
    document.getElementById('share-status-btn').addEventListener('click', async () => {
      const habits = useStore.getState().habits
      const timer = useStore.getState().activeTimer
      const profile = useStore.getState().profile

      const canvas = renderShareCanvas({ profile, habits, timer })
      const blob = await new Promise(resolve => canvas.toBlob(resolve, 'image/png'))
      if (blob && navigator.share) {
        try {
          const file = new File([blob], 'status.png', { type: 'image/png' })
          await navigator.share({ files: [file], title: 'My Fasting Furious Status' })
        } catch {}
      }
    })
  }

  return () => {
    document.querySelectorAll('.bottom-nav a').forEach(a => {
      a.classList.remove('active')
      if (a.getAttribute('href') === '#/') a.classList.add('active')
    })
  }
}
