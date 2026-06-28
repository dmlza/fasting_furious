import { createStore } from 'zustand/vanilla'
import { supabase } from '../lib/supabase.js'

const today = () => new Date().toISOString().split('T')[0]

const DEFAULT_GRID = ['fasting', 'no_sugar', 'exercise', 'no_smoking']

function loadGridLayout() {
  try {
    const saved = localStorage.getItem('ff_grid_layout')
    return saved ? JSON.parse(saved) : DEFAULT_GRID
  } catch { return DEFAULT_GRID }
}

function saveGridLayout(layout) {
  try { localStorage.setItem('ff_grid_layout', JSON.stringify(layout)) } catch {}
}

export const useStore = createStore((set, get) => ({
  user: null,
  profile: null,
  habits: { exercise: false, no_sugar: false, no_smoking: false, exercise_minutes: 0 },
  habitHistory: [],
  activeTimer: null,
  feed: [],
  friends: [],
  loading: false,
  gridLayout: loadGridLayout(),
  isEditingGrid: false,

  setEditingGrid: (editing) => set({ isEditingGrid: editing }),

  mountHabit: (habitId) => {
    const { gridLayout } = get()
    if (gridLayout.includes(habitId)) return
    const updated = [...gridLayout, habitId]
    set({ gridLayout: updated })
    saveGridLayout(updated)
  },

  unmountHabit: (habitId) => {
    const { gridLayout } = get()
    if (habitId === 'fasting') return
    const updated = gridLayout.filter(id => id !== habitId)
    set({ gridLayout: updated })
    saveGridLayout(updated)
  },

  setUser: (user) => set({ user }),

  setProfile: (profile) => set({ profile }),

  fetchProfile: async (userId) => {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle()
    if (data) set({ profile: data })
  },

  fetchHabits: async (userId) => {
    const { data } = await supabase
      .from('habits')
      .select('*')
      .eq('user_id', userId)
      .eq('date', today())
      .maybeSingle()
    if (data) {
      set({ habits: {
        exercise: data.exercise,
        no_sugar: data.no_sugar,
        no_smoking: data.no_smoking,
        exercise_minutes: data.exercise_minutes || 0,
      }})
    }
  },

  toggleHabit: async (habit) => {
    const { user, habits } = get()
    if (!user) return
    const wasOff = !habits[habit]
    const updated = { ...habits, [habit]: !habits[habit] }
    set({ habits: updated })

    const upsertData = {
      user_id: user.id,
      date: today(),
      [habit]: updated[habit],
      updated_at: new Date().toISOString(),
    }
    if (habit === 'exercise') {
      upsertData.exercise_minutes = habits.exercise_minutes || 0
    }
    await supabase.from('habits').upsert(upsertData, { onConflict: 'user_id,date' })

    if (wasOff && updated[habit]) {
      const yesterday = new Date()
      yesterday.setDate(yesterday.getDate() - 1)
      const yStr = yesterday.toISOString().split('T')[0]
      const { data: yData } = await supabase
        .from('habits')
        .select(habit)
        .eq('user_id', user.id)
        .eq('date', yStr)
        .maybeSingle()

      const habitLabels = { exercise: 'Exercise', no_sugar: 'No Sugar', no_smoking: 'No Smoking' }
      if (!yData || !yData[habit]) {
        get().dispatchMilestonePost('STREAK_START', habitLabels[habit] || habit)
      }
    }
  },

  fetchHabitHistory: async (userId, limitDays = 90) => {
    const start = new Date()
    start.setDate(start.getDate() - limitDays)
    const { data } = await supabase
      .from('habits')
      .select('*')
      .eq('user_id', userId)
      .gte('date', start.toISOString().split('T')[0])
      .order('date', { ascending: true })
    set({ habitHistory: data || [] })
  },

  logExerciseMinutes: async (minutes) => {
    const { user } = get()
    if (!user) return
    const habits = get().habits
    const updated = { ...habits, exercise: true }
    const upserted = await supabase.from('habits').upsert({
      user_id: user.id,
      date: today(),
      exercise: true,
      exercise_minutes: (habits.exercise_minutes || 0) + minutes,
      exercise_updated_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    }, { onConflict: 'user_id,date' }).select().single()

    if (!upserted.error && upserted.data) {
      set({ habits: {
        exercise: upserted.data.exercise,
        no_sugar: upserted.data.no_sugar,
        no_smoking: upserted.data.no_smoking,
        exercise_minutes: upserted.data.exercise_minutes,
      }})
    } else {
      set({ habits: updated })
    }
  },

  fetchActiveTimer: async (userId) => {
    const { data } = await supabase
      .from('active_timers')
      .select('*')
      .eq('user_id', userId)
      .eq('active', true)
      .maybeSingle()
    set({ activeTimer: data })
  },

  setActiveTimer: (timer) => set({ activeTimer: timer }),

  fetchFeed: async (userId) => {
    const { data: friendships } = await supabase
      .from('friendships')
      .select('sender_id, receiver_id')
      .or(`sender_id.eq.${userId},receiver_id.eq.${userId}`)
      .eq('status', 'accepted')

    if (!friendships?.length) {
      set({ feed: [] })
      return
    }

    const friendIds = friendships.map(f =>
      f.sender_id === userId ? f.receiver_id : f.sender_id
    )
    friendIds.push(userId)

    const { data: posts } = await supabase
      .from('posts')
      .select('*, profile:user_id(username, display_name)')
      .in('user_id', friendIds)
      .order('created_at', { ascending: false })
      .limit(50)

    const postIds = (posts || []).map(p => p.id)
    let reactions = []
    if (postIds.length) {
      const { data: r } = await supabase
        .from('reactions')
        .select('*')
        .in('post_id', postIds)
      reactions = r || []
    }

    const reactionsByPost = {}
    reactions.forEach(r => {
      if (!reactionsByPost[r.post_id]) reactionsByPost[r.post_id] = []
      reactionsByPost[r.post_id].push(r)
    })

    const feed = (posts || []).map(p => {
      const postReactions = reactionsByPost[p.id] || []
      return {
        ...p,
        reactions: postReactions,
        hype_count: postReactions.filter(r => r.emoji === '🔥').length,
      }
    })

    set({ feed })
  },

  addReaction: async (postId, userId, emoji) => {
    await supabase.from('reactions').insert({
      user_id: userId,
      post_id: postId,
      emoji,
    })
    get().fetchFeed(userId)
  },

  removeReaction: async (postId, userId) => {
    await supabase
      .from('reactions')
      .delete()
      .eq('user_id', userId)
      .eq('post_id', postId)
    get().fetchFeed(userId)
  },

  fetchFriends: async (userId) => {
    const { data: sent } = await supabase
      .from('friendships')
      .select('*, receiver:receiver_id(username, display_name)')
      .eq('sender_id', userId)
      .eq('status', 'accepted')

    const { data: received } = await supabase
      .from('friendships')
      .select('*, sender:sender_id(username, display_name)')
      .eq('receiver_id', userId)
      .eq('status', 'accepted')

    const friends = [
      ...(sent || []).map(f => f.receiver),
      ...(received || []).map(f => f.sender),
    ]
    set({ friends })
  },

  getStreak: (habit, habitsList) => {
    if (!habitsList?.length) return 0
    let streak = 0
    for (let i = habitsList.length - 1; i >= 0; i--) {
      if (habitsList[i][habit]) streak++
      else break
    }
    return streak
  },

  dispatchMilestonePost: async (eventType, habitLabel, metaValue) => {
    const { user, profile } = get()
    if (!user) return
    const userName = profile?.display_name || profile?.username || 'Someone'
    const templates = {
      STREAK_START: `${userName} started their ${habitLabel} journey today! Send some fuel to crush Day 1. 🚭`,
      PHASE_UNLOCK: `${userName} unlocked Phase ${metaValue}: The Gut & Skin Glow on their ${habitLabel} Journey! 🌟`,
      FAST_COMPLETE: `${userName} successfully locked down a strict ${metaValue} Fasting window! 🙌`,
    }
    const content = templates[eventType]
    if (!content) return
    await supabase.from('posts').insert({
      user_id: user.id,
      type: eventType === 'FAST_COMPLETE' ? 'fasting_complete' : 'general',
      content,
    })
  },
}))
