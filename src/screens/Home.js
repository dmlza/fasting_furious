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

const WIDGETS = {
  fasting: {
    id: 'fasting', label: 'Fasting Timer', icon: '⏱️', desc: 'Track intermittent fasting windows',
    gradient: 'from-indigo', removable: false,
  },
  no_sugar: {
    id: 'no_sugar', label: 'No Sugar', icon: '🍬', desc: 'Break free from sugar addiction',
    gradient: 'from-amber', removable: true,
  },
  exercise: {
    id: 'exercise', label: 'Exercise', icon: '🏃', desc: 'Log daily workout minutes',
    gradient: 'from-emerald', removable: true,
  },
  no_smoking: {
    id: 'no_smoking', label: 'No Smoking', icon: '🚭', desc: 'Kick the habit for good',
    gradient: 'from-coral', removable: true,
  },
}

export async function renderHome(container, user) {
  const store = useStore.getState()
  store.setUser(user)
  if (!store.profile) await store.fetchProfile(user.id)
  await store.fetchHabits(user.id)
  await store.fetchActiveTimer(user.id)
  await store.fetchHabitHistory(user.id)

  render()

  function render() {
    const state = useStore.getState()
    const { gridLayout, isEditingGrid } = state

    const widgets = gridLayout
      .map(id => WIDGETS[id])
      .filter(Boolean)

    let gridHTML = widgets.map(w => renderWidget(w)).join('')

    if (isEditingGrid) {
      const hiddenWidgets = Object.values(WIDGETS).filter(w => w.removable && !gridLayout.includes(w.id))
      gridHTML += `
        <div class="challenge-slot" id="add-challenge-btn">
          <div class="challenge-slot-inner">
            <span class="challenge-slot-plus">+</span>
            <span class="challenge-slot-label">Add Challenge</span>
          </div>
        </div>
      `
    }

    container.innerHTML = `
      <div class="screen fade-in">
        <div class="bento-grid ${isEditingGrid ? 'is-editing' : ''}">
          ${gridHTML}
        </div>
        <div class="edit-grid-bar">
          <button class="edit-grid-btn ${isEditingGrid ? 'active' : ''}" id="edit-grid-toggle">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z"/></svg>
            ${isEditingGrid ? 'Done Editing' : 'Edit Grid'}
          </button>
        </div>
        <div class="share-btn-wrap">
          <button class="share-btn" id="share-status-btn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>
            Update & Share Status
          </button>
          <button class="share-btn photo-checkin-btn" id="photo-checkin-btn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
            Photo Check-in
          </button>
        </div>
        <input type="file" id="photo-input" accept="image/*" style="display:none" />
      </div>
    `

    initEditToggle()
    initTimer()
    initHabits()
    initExercise()
    initShare()
    updateRings()
  }

  function renderWidget(w) {
    if (w.id === 'fasting') return renderHero()
    if (w.id === 'no_sugar') return renderSugar()
    if (w.id === 'exercise') return renderExercise()
    if (w.id === 'no_smoking') return renderSmoking()
    return ''
  }

  function renderHero() {
    return `
      <div class="hero-card" id="hero-card">
        <button class="science-trigger" id="fasting-science-btn" title="Fasting Science">🧪</button>
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
                <circle class="ring-bg" cx="90" cy="90" r="82" fill="none"/>
                <circle class="ring-fg ring-fg-outer" id="ring-outer" cx="90" cy="90" r="82" stroke="none" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="515" stroke-dashoffset="515"/>
                <circle class="ring-bg" cx="90" cy="90" r="68" fill="none"/>
                <circle class="ring-fg ring-fg-mid" id="ring-mid" cx="90" cy="90" r="68" stroke="none" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="427" stroke-dashoffset="427"/>
                <circle class="ring-bg" cx="90" cy="90" r="54" fill="none"/>
                <circle class="ring-fg ring-fg-inner" id="ring-inner" cx="90" cy="90" r="54" stroke="none" stroke-width="6" fill="none" stroke-linecap="round" stroke-dasharray="339" stroke-dashoffset="339"/>
              </svg>
            </div>
          </div>
        </div>
      </div>
    `
  }

  function renderSugar() {
    return `
      <div class="bento-card sugar-card" id="sugar-card">
        <button class="science-trigger-card" id="sugar-science-btn" title="Milestone Roadmap">🧪</button>
        <div class="streak-display" id="sugar-streak">🔥 --</div>
        <div class="streak-label">No Sugar Streak</div>
        <div class="micro-progress" id="sugar-progress">
          <div class="micro-progress-track">
            <div class="micro-progress-fill" id="sugar-progress-fill" style="width:0%"></div>
          </div>
          <span class="micro-progress-label" id="sugar-progress-label">--h til next day</span>
        </div>
      </div>
    `
  }

  function renderExercise() {
    return `
      <div class="bento-card exercise-card" id="exercise-card">
        <div class="exercise-head">
          <span class="exercise-icon">🏃</span>
          <button class="exercise-add-btn" id="exercise-add-btn">+</button>
        </div>
        <div class="exercise-stats" id="exercise-stats">0 / ${HABIT_TARGETS.exercise} min</div>
        <div class="exercise-label">Today's Workout</div>
      </div>
    `
  }

  function renderSmoking() {
    return `
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
    `
  }

  function initEditToggle() {
    document.getElementById('edit-grid-toggle').addEventListener('click', () => {
      const store = useStore.getState()
      store.setEditingGrid(!store.isEditingGrid)
      render()
    })
  }

  function initHabits() {
    const state = useStore.getState()
    const history = state.habitHistory
    const habits = state.habits
    const isEditing = state.isEditingGrid

    const sugarEl = document.getElementById('sugar-streak')
    if (sugarEl) {
      const sugarStreak = getStreak('no_sugar', history)
      sugarEl.textContent = `🔥 ${sugarStreak} Day${sugarStreak !== 1 ? 's' : ''}`
    }

    const progFill = document.getElementById('sugar-progress-fill')
    const progLabel = document.getElementById('sugar-progress-label')
    if (progFill && progLabel) {
      const now = new Date()
      const midnight = new Date(now)
      midnight.setDate(midnight.getDate() + 1)
      midnight.setHours(0, 0, 0, 0)
      const msLeft = midnight.getTime() - now.getTime()
      const hoursLeft = msLeft / 1000 / 60 / 60
      const pct = Math.max(0, Math.min(100, ((24 - hoursLeft) / 24) * 100))
      progFill.style.width = `${pct}%`
      progLabel.textContent = `${Math.floor(hoursLeft)}h til next day`
    }

    const smokeStreakEl = document.getElementById('smoking-streak')
    if (smokeStreakEl) {
      const smokeStreak = getStreak('no_smoking', history)
      smokeStreakEl.textContent = `🔥 ${smokeStreak} Day${smokeStreak !== 1 ? 's' : ''}`
    }

    const toggle = document.getElementById('smoking-toggle')
    if (toggle) {
      if (habits.no_smoking) toggle.classList.add('checked')
      toggle.addEventListener('click', async (e) => {
        e.stopPropagation()
        await useStore.getState().toggleHabit('no_smoking')
        const updated = useStore.getState().habits
        toggle.classList.toggle('checked', updated.no_smoking)
        const newHistory = useStore.getState().habitHistory
        const s = getStreak('no_smoking', newHistory)
        const el = document.getElementById('smoking-streak')
        if (el) el.textContent = `🔥 ${s} Day${s !== 1 ? 's' : ''}`
        updateRings()
      })
    }

    const sugarCard = document.getElementById('sugar-card')
    if (sugarCard) {
      sugarCard.addEventListener('click', (e) => {
        if (e.target.closest('.science-trigger-card')) return
        if (isEditing) return
        openContinuityCalendar(history)
      })
    }

    const scienceBtn = document.getElementById('fasting-science-btn')
    if (scienceBtn) {
      scienceBtn.addEventListener('click', (e) => {
        e.stopPropagation()
        openFastingScience()
      })
    }

    const sugarScienceBtn = document.getElementById('sugar-science-btn')
    if (sugarScienceBtn) {
      sugarScienceBtn.addEventListener('click', (e) => {
        e.stopPropagation()
        openSugarMilestones()
      })
    }

    const addBtn = document.getElementById('add-challenge-btn')
    if (addBtn) {
      addBtn.addEventListener('click', openChallengeDrawer)
    }
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

  function openChallengeDrawer() {
    const state = useStore.getState()
    const { gridLayout } = state
    const hidden = Object.values(WIDGETS).filter(w => w.removable && !gridLayout.includes(w.id))

    const overlay = document.createElement('div')
    overlay.className = 'modal-overlay'
    overlay.innerHTML = `
      <div class="modal-content challenge-drawer">
        <div class="challenge-drawer-handle"></div>
        <h3>⚡ Choose Your Challenge</h3>
        <p class="challenge-drawer-sub">Pick a habit to add to your dashboard. Each challenge tracks your streak and progress.</p>
        <div class="challenge-list">
          ${hidden.length === 0 ? '<div class="challenge-empty">All challenges active! 🎯</div>' :
            hidden.map(w => `
              <button class="challenge-card" data-id="${w.id}">
                <span class="challenge-card-icon">${w.icon}</span>
                <div class="challenge-card-body">
                  <div class="challenge-card-title">${w.label}</div>
                  <div class="challenge-card-desc">${w.desc}</div>
                </div>
                <span class="challenge-card-add">+</span>
              </button>
            `).join('')
          }
        </div>
      </div>
    `
    document.body.appendChild(overlay)

    overlay.querySelectorAll('.challenge-card').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id
        useStore.getState().mountHabit(id)
        overlay.remove()
        render()
      })
    })
    overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove() })
  }

  function openFastingScience() {
    const timer = useStore.getState().activeTimer
    const elapsedH = timer
      ? (Date.now() - new Date(timer.started_at).getTime()) / 1000 / 60 / 60
      : 0
    const stages = [
      { range: [0, 4], label: 'Blood Sugar Rise / Decline', icon: '🩸', key: 'bloodSugar' },
      { range: [5, 12], label: 'Gluconeogenesis', icon: '⚡', key: 'gluconeogenesis' },
      { range: [13, 16], label: 'Autophagy Phase', icon: '🔄', key: 'autophagy' },
    ]

    const overlay = document.createElement('div')
    overlay.className = 'modal-overlay'
    overlay.innerHTML = `
      <div class="modal-content science-modal">
        <button class="close-modal" id="close-science">&times;</button>
        <h3>🧪 Fasting Science Timeline</h3>
        ${stages.map(s => {
          const completed = elapsedH >= s.range[1]
          const active = elapsedH >= s.range[0] && elapsedH < s.range[1]
          const locked = elapsedH < s.range[0]
          const cls = completed ? 'completed' : active ? 'active' : 'locked'
          const status = completed ? '✅' : active ? '○' : '🔒'
          return `
            <div class="science-stage ${cls}">
              <span class="stage-icon">${s.icon}</span>
              <div class="stage-info">
                <div class="stage-title">${s.label}</div>
                <div class="stage-desc">Hours ${s.range[0]}–${s.range[1]}</div>
              </div>
              <span class="stage-status">${status}</span>
            </div>
          `
        }).join('')}
      </div>
    `
    document.body.appendChild(overlay)
    overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove() })
    overlay.querySelector('#close-science').addEventListener('click', () => overlay.remove())
  }

  function openSugarMilestones() {
    const state = useStore.getState()
    const streak = getStreak('no_sugar', state.habitHistory)
    const milestones = [
      { range: [1, 3], label: 'The Withdrawal Phase', icon: '⚡', desc: 'Cravings peak, energy dips' },
      { range: [4, 7], label: 'Stabilization', icon: '⚖️', desc: 'Blood sugar normalizes' },
      { range: [8, 14], label: 'The Gut & Skin Glow', icon: '✨', desc: 'Digestion improves, skin clears' },
      { range: [15, 30], label: 'Fat Burning & Habit Shift', icon: '🔥', desc: 'Deep metabolic adaptation' },
    ]

    const overlay = document.createElement('div')
    overlay.className = 'modal-overlay'
    overlay.innerHTML = `
      <div class="modal-content milestone-modal">
        <button class="close-modal" id="close-milestone">&times;</button>
        <h3>🧪 No Sugar Milestone Roadmap</h3>
        ${milestones.map(m => {
          const completed = streak >= m.range[1]
          const active = streak >= m.range[0] && streak < m.range[1]
          const locked = streak < m.range[0]
          const cls = completed ? 'completed' : active ? 'active' : 'locked'
          return `
            <div class="milestone-stage ${cls}">
              <span class="milestone-icon">${m.icon}</span>
              <div class="milestone-info">
                <div class="milestone-title">${m.label}</div>
                <div class="milestone-desc">Days ${m.range[0]}–${m.range[1]} — ${m.desc}</div>
              </div>
              <span class="milestone-check">${completed ? '✅' : locked ? '<span class="milestone-lock-icon">🔒</span>' : '○'}</span>
            </div>
          `
        }).join('')}
      </div>
    `
    document.body.appendChild(overlay)
    overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.remove() })
    overlay.querySelector('#close-milestone').addEventListener('click', () => overlay.remove())
  }

  function openContinuityCalendar(history) {
    const fullscreen = document.createElement('div')
    fullscreen.className = 'calendar-fullscreen fade-in'
    const weeks = 52
    const days = weeks * 7
    const now = new Date()
    const monthLabels = []
    for (let w = 0; w < weeks; w++) {
      const d = new Date(now)
      d.setDate(d.getDate() - (days - w * 7))
      const mon = d.toLocaleString('en', { month: 'short' })
      monthLabels.push(w % 4 === 0 ? mon : '')
    }

    let cells = '<div class="calendar-label"></div>'
    cells += monthLabels.map(m => `<div class="calendar-label">${m}</div>`).join('')

    for (let dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
      const dayNames = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
      cells += `<div class="calendar-label">${dayNames[dayOfWeek]}</div>`
      for (let w = 0; w < weeks; w++) {
        const dayOffset = (weeks - 1 - w) * 7 + dayOfWeek
        const d = new Date(now)
        d.setDate(d.getDate() - (days - 1 - dayOffset))
        const dateStr = d.toISOString().split('T')[0]
        const entry = history.find(h => h.date === dateStr)
        const val = entry?.no_sugar ? 1 : 0
        let intensity = 0
        if (val > 0) {
          const streak = getStreakAtDate('no_sugar', history, dateStr)
          if (streak <= 3) intensity = 1
          else if (streak <= 7) intensity = 2
          else intensity = 3
        }
        cells += `<div class="calendar-cell intensity-${intensity}" title="${dateStr}"></div>`
      }
    }

    fullscreen.innerHTML = `
      <div class="calendar-header">
        <h2>📅 No Sugar — 52-Week Continuity</h2>
        <button id="close-calendar">&times;</button>
      </div>
      <div class="calendar-scroll">
        <div class="calendar-grid">${cells}</div>
        <div class="calendar-legend">
          <span style="font-size:11px;color:var(--text-muted)">Rest</span>
          <div class="calendar-legend-item" style="background:var(--surface2)"></div>
          <div class="calendar-legend-item" style="background:rgba(245,158,11,0.25)"></div>
          <div class="calendar-legend-item" style="background:rgba(245,158,11,0.60)"></div>
          <div class="calendar-legend-item" style="background:var(--amber)"></div>
          <span style="font-size:11px;color:var(--text-muted)">Streak</span>
        </div>
      </div>
    `
    document.body.appendChild(fullscreen)
    fullscreen.querySelector('#close-calendar').addEventListener('click', () => fullscreen.remove())
    fullscreen.addEventListener('click', (e) => { if (e.target === fullscreen) fullscreen.remove() })
  }

  function getStreakAtDate(habit, list, dateStr) {
    const idx = list.findIndex(h => h.date === dateStr)
    if (idx === -1 || !list[idx][habit]) return 0
    let streak = 0
    for (let i = idx; i >= 0; i--) {
      if (list[i][habit]) streak++
      else break
    }
    return streak
  }

  function initExercise() {
    const state = useStore.getState()
    const minutes = state.habits.exercise_minutes || 0
    const el = document.getElementById('exercise-stats')
    if (el) el.textContent = `${minutes} / ${HABIT_TARGETS.exercise} min`

    const addBtn = document.getElementById('exercise-add-btn')
    if (addBtn) {
      addBtn.addEventListener('click', (e) => {
        e.stopPropagation()
        if (state.isEditingGrid) return
        openExerciseModal()
      })
    }

    const card = document.getElementById('exercise-card')
    if (card) {
      card.addEventListener('click', () => {
        if (state.isEditingGrid) return
        openExerciseModal()
      })
    }
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
      const el = document.getElementById('exercise-stats')
      if (el) el.textContent = `${total} / ${HABIT_TARGETS.exercise} min`
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
    const outerRing = document.getElementById('ring-outer')
    const midRing = document.getElementById('ring-mid')
    const innerRing = document.getElementById('ring-inner')
    if (!outerRing) return

    const state = useStore.getState()
    const habits = state.habits
    const timer = state.activeTimer

    const outerCirc = 515
    const midCirc = 427
    const innerCirc = 339

    if (timer && timer.target_minutes) {
      const started = new Date(timer.started_at).getTime()
      const elapsed = (Date.now() - started) / 1000 / 60
      const progress = Math.min(elapsed / timer.target_minutes, 1)
      outerRing.style.strokeDashoffset = String(outerCirc * (1 - progress))
      outerRing.setAttribute('stroke', '#6366F1')
    } else {
      outerRing.style.strokeDashoffset = String(outerCirc)
      outerRing.style.stroke = '#E2E4E9'
    }

    const exerciseMin = habits.exercise_minutes || 0
    const exerciseProgress = Math.min(exerciseMin / HABIT_TARGETS.exercise, 1)
    midRing.style.strokeDashoffset = String(midCirc * (1 - exerciseProgress))
    midRing.setAttribute('stroke', exerciseProgress > 0 ? '#10B981' : '#E2E4E9')

    const sugarStreak = getStreak('no_sugar', state.habitHistory)
    const habitScore = Math.min(sugarStreak / 14, 1)
    innerRing.style.strokeDashoffset = String(innerCirc * (1 - habitScore))
    innerRing.setAttribute('stroke', habitScore > 0 ? '#F59E0B' : '#E2E4E9')
  }

  function initTimer() {
    const activeTimer = useStore.getState().activeTimer
    let tickInterval = null
    let selectedPreset = '16:8'

    const startWrap = document.getElementById('timer-ring-start')
    const activeWrap = document.getElementById('timer-ring-active')

    if (activeTimer) {
      if (startWrap) startWrap.classList.add('hidden')
      if (activeWrap) activeWrap.classList.remove('hidden')
      startTick(activeTimer)
    }

    document.querySelectorAll('.preset-pill').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.preset-pill').forEach(b => b.classList.remove('active'))
        btn.classList.add('active')
        selectedPreset = btn.dataset.preset
      })
    })
    const defaultPreset = document.querySelector('[data-preset="16:8"]')
    if (defaultPreset) defaultPreset.classList.add('active')

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
        if (startWrap) startWrap.classList.add('hidden')
        if (activeWrap) activeWrap.classList.remove('hidden')
        startTick(data)
      }
    })

    document.getElementById('timer-stop-btn').addEventListener('click', async () => {
      const timer = useStore.getState().activeTimer
      if (timer) {
        const elapsed = Math.floor((Date.now() - new Date(timer.started_at).getTime()) / 1000)
        const type = elapsed >= timer.target_minutes * 60 ? 'fasting_complete' : 'fasting'
        await supabase.from('active_timers').update({ active: false }).eq('id', timer.id)
        if (type === 'fasting_complete') {
          const presetLabel = timer.preset_type || `${timer.target_minutes}min`
          await useStore.getState().dispatchMilestonePost('FAST_COMPLETE', 'Fasting', presetLabel)
        } else {
          await supabase.from('posts').insert({
            user_id: user.id,
            type,
            content: 'Broke fast early',
            duration_minutes: Math.floor(elapsed / 60),
          })
        }
        useStore.getState().setActiveTimer(null)
        if (tickInterval) clearInterval(tickInterval)
        if (startWrap) startWrap.classList.remove('hidden')
        if (activeWrap) activeWrap.classList.add('hidden')
        const display = document.getElementById('timer-display')
        if (display) display.textContent = '--:--:--'
        const label = document.getElementById('timer-phase-label')
        if (label) label.textContent = 'READY'
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
        const display = document.getElementById('timer-display')
        if (display) display.textContent = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`

        const label = document.getElementById('timer-phase-label')
        if (label) {
          label.textContent = remaining > 0 ? 'FASTING WINDOW' : '✅ EATING WINDOW'
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

  function initPhotoCheckin() {
    const btn = document.getElementById('photo-checkin-btn')
    if (!btn) return
    const input = document.getElementById('photo-input')
    if (!input) return

    btn.addEventListener('click', () => input.click())

    input.addEventListener('change', async () => {
      const file = input.value ? input.files[0] : null
      if (!file) return
      input.value = ''

      const img = await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onload = (e) => {
          const i = new Image()
          i.onload = () => resolve(i)
          i.onerror = reject
          i.src = e.target.result
        }
        reader.readAsDataURL(file)
      })

      const canvas = document.createElement('canvas')
      const maxW = 800
      let { width, height } = img
      if (width > maxW) { height *= maxW / width; width = maxW }
      canvas.width = width; canvas.height = height
      const ctx = canvas.getContext('2d')
      ctx.drawImage(img, 0, 0, width, height)
      const dataUrl = canvas.toDataURL('image/jpeg', 0.8)

      await supabase.from('posts').insert({
        user_id: user.id,
        type: 'checkin',
        content: '📸 Photo check-in',
        image_url: dataUrl,
      })
    })
  }

  initPhotoCheckin()

  return () => {
    document.querySelectorAll('.bottom-nav a').forEach(a => {
      a.classList.remove('active')
      if (a.getAttribute('href') === '#/') a.classList.add('active')
    })
  }
}
