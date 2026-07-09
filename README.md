# Fasting Furious

**Train hard. Fast harder.**

A social fitness and intermittent fasting tracker built with Flutter and Supabase. Track your fasts, log workouts, build healthy habits, and connect with friends who share your goals.

## Screenshots

| Home | Feed | Profile | Timer |
|------|------|---------|-------|
| Bento grid dashboard with fasting timer, habit streaks, and exercise tracker | Social activity feed with reactions, comments, and image posts | User profile with posts, stats, friends list, and dark mode toggle | Real-time fasting countdown with milestone markers |

## Features

- **Intermittent Fasting Timer** — 16:8, 18:6, and 20:4 presets with real-time countdown ring and milestone markers
- **Habit Tracking** — Daily toggles for no-smoking, no-sugar, and exercise with streak calculation
- **Workout System** — 26 built-in exercises across warm-up, main, and cool-down categories; custom exercise creation; workout player with timer and rep tracking
- **Social Feed** — Share progress posts with stat badges, images, emoji reactions, and comments
- **Friends System** — Search users, send/accept/decline friend requests, view profiles
- **Notifications** — Real-time notifications for friend requests, acceptances, and interactions
- **Statistics** — Bar charts for fasting history, streak tracking across all habits
- **Metabolic Dashboard** — Science-backed view of metabolic processes during fasting with literature citations
- **Health Recovery Timeline** — Smoking cessation milestone tracker from 20 minutes to 1 year
- **Dark Mode** — Full dark/light theme with persistence
- **Realtime Updates** — Supabase Realtime subscriptions for live feed and notifications

## Architecture

```
lib/
├── config/
│   ├── theme.dart              # Colors, gradients, light/dark themes
│   └── page_transitions.dart   # Custom route transitions
├── models/
│   ├── models.dart             # Profile, Habit, Post, Reaction, Notification
│   └── exercise.dart           # Exercise, WorkoutSession, 26 built-in exercises
├── providers/
│   ├── auth_provider.dart      # Authentication state
│   ├── habit_provider.dart     # Habit tracking, streaks, timer
│   ├── feed_provider.dart      # Social feed, reactions
│   ├── friends_provider.dart   # Friend system
│   ├── notifications_provider.dart
│   └── theme_provider.dart     # Dark/light mode persistence
├── screens/
│   ├── landing_screen.dart     # Onboarding
│   ├── auth_screen.dart        # Login/signup
│   ├── home_screen.dart        # Fasting timer + bento habit grid
│   ├── feed_screen.dart        # Social activity feed
│   ├── profile_screen.dart     # User profile, settings, posts
│   ├── friends_screen.dart     # Friends list, search, requests
│   ├── stats_screen.dart       # Charts and streaks
│   ├── workout_*.dart          # Workout setup, player, summary, history
│   └── ...
├── services/
│   └── supabase_service.dart   # Supabase API client
├── widgets/
│   ├── fasting_timer_ring.dart  # Custom painted countdown ring
│   ├── metabolic_dashboard.dart # Science dashboard
│   ├── floating_pill_nav_bar.dart # Custom bottom navigation
│   └── ...
└── main.dart                   # App entry, auth gate, navigation shell
```

**State Management:** Riverpod (`StateNotifierProvider` pattern)
**Backend:** Supabase (Auth, Postgres, Realtime, Storage)
**UI:** Custom glassmorphism components, bento grid layout, Google Fonts (Poppins)

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart |
| State | flutter_riverpod |
| Backend | Supabase |
| Charts | fl_chart |
| Fonts | google_fonts (Poppins) |
| Animations | animate_do |
| Storage | shared_preferences |

## Getting Started

### Prerequisites

- Flutter SDK >= 3.12.2
- A [Supabase](https://supabase.com) project with the following tables:
  - `profiles`, `habits`, `active_timers`, `posts`, `reactions`, `friendships`, `notifications`, `workout_history`
- Supabase Storage bucket: `post-images`

### Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/dmlza/fasting_furious.git
   cd fasting_furious
   ```

2. Create a `.env` file (gitignored) or pass via `--dart-define`:
   ```bash
   flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
   ```

3. Seed demo data (Eric & Ariel) — run `sql/seed_data.sql` in your Supabase SQL editor. This creates:
   - 2 demo profiles with bios
   - 14 days of habit history for each
   - 8 sample posts (fasting, workouts, general updates)
   - Reactions between the demo users

4. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

New users are automatically friended with Eric and Ariel so the feed has content from day one.

### Database Schema

Run the migrations in `sql/` to set up tables with RLS policies.

## Testing

```bash
flutter test
```

## Security

- Row Level Security (RLS) enabled on all tables
- Supabase credentials passed via `--dart-define` (not hardcoded)
- User emails are not exposed in notifications

## License

Private project.
