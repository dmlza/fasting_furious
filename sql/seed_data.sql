-- ============================================================
-- Seed Data for Fasting Furious
-- ============================================================
-- NOTE: The app now creates Eric & Ariel automatically on first
-- run. This SQL file is a fallback if you want to seed manually.
--
-- Steps:
-- 1. Create auth users in Supabase Dashboard > Auth > Users:
--    - eric@fastingfurious.demo / demo123456
--    - ariel@fastingfurious.demo / demo123456
-- 2. Copy their UUIDs from the dashboard
-- 3. Replace the UUIDs below
-- 4. Run this SQL
-- ============================================================

-- Replace these with actual auth user UUIDs from your dashboard
DO $$
DECLARE
  eric_id UUID := 'PASTE_ERIC_UUID_HERE';
  ariel_id UUID := 'PASTE_ARIEL_UUID_HERE';
BEGIN

-- Profiles
INSERT INTO public.profiles (id, username, display_name, bio)
VALUES
  (eric_id, 'eric_fasts', 'Eric Torres', '16:8 warrior. Down 15lbs in 2 months. Coffee before noon only.'),
  (ariel_id, 'ariel_fit', 'Ariel Chen', 'Fitness coach. 20:4 OMAD. Runner. Plant-based.')
ON CONFLICT (id) DO UPDATE SET
  username = EXCLUDED.username, display_name = EXCLUDED.display_name, bio = EXCLUDED.bio;

-- Habits (last 14 days for Eric)
INSERT INTO public.habits (user_id, date, exercise, no_sugar, no_smoking, exercise_minutes, fasting_hours)
SELECT eric_id, (CURRENT_DATE - d)::text,
  CASE WHEN d % 3 = 0 THEN false ELSE true END,
  CASE WHEN d < 3 THEN false ELSE true END,
  true,
  CASE WHEN d % 3 = 0 THEN 0 ELSE (30 + (d * 5) % 30) END,
  CASE WHEN d % 4 = 0 THEN 14 ELSE 16 END
FROM generate_series(0, 13) AS d
ON CONFLICT (user_id, date) DO NOTHING;

-- Habits (last 14 days for Ariel)
INSERT INTO public.habits (user_id, date, exercise, no_sugar, no_smoking, exercise_minutes, fasting_hours)
SELECT ariel_id, (CURRENT_DATE - d)::text,
  true, true, true,
  (45 + (d * 7) % 20),
  CASE WHEN d % 3 = 0 THEN 18 ELSE 20 END
FROM generate_series(0, 13) AS d
ON CONFLICT (user_id, date) DO NOTHING;

-- Posts
INSERT INTO public.posts (user_id, type, content, created_at) VALUES
  (eric_id, 'fasting_complete', 'Completed a 16:8 fast! Feeling unstoppable.', NOW() - interval '2 hours'),
  (eric_id, 'exercise', 'Crushing 30min of chest and triceps today', NOW() - interval '1 day'),
  (eric_id, 'general', 'Day 45 of my fasting journey. Down 15lbs total. The energy is unreal.', NOW() - interval '2 days'),
  (ariel_id, 'fasting_complete', '20:4 OMAD complete. Bone broth to break the fast.', NOW() - interval '3 hours'),
  (ariel_id, 'workout_complete', 'Just finished a 45min HIIT session. Heart rate peaked at 175.', NOW() - interval '5 hours'),
  (ariel_id, 'exercise', 'Morning run done before sunrise. 5K in 24min.', NOW() - interval '1 day'),
  (ariel_id, 'general', 'Week 3 of 20:4. Sleep has improved dramatically. No more 2am wakes.', NOW() - interval '3 days'),
  (ariel_id, 'fasting', 'Currently fasting. 14 hours in. Black coffee is keeping me going.', NOW() - interval '6 hours');

END $$;
