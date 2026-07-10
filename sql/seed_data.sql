-- ============================================================
-- Seed Data for Fasting Furious
-- ============================================================
-- NOTE: The app now creates Eric, Ariel, Marcus, Priya & Jake
-- automatically on first run. This SQL file is a fallback.
--
-- Steps:
-- 1. Create auth users in Supabase Dashboard > Auth > Users:
--    - eric@fastingfurious.demo / demo123456
--    - ariel@fastingfurious.demo / demo123456
--    - marcus@fastingfurious.demo / demo123456
--    - priya@fastingfurious.demo / demo123456
--    - jake@fastingfurious.demo / demo123456
-- 2. Copy their UUIDs from the dashboard
-- 3. Replace the UUIDs below
-- 4. Run this SQL
-- ============================================================

DO $$
DECLARE
  eric_id UUID := 'PASTE_ERIC_UUID_HERE';
  ariel_id UUID := 'PASTE_ARIEL_UUID_HERE';
  marcus_id UUID := 'PASTE_MARCUS_UUID_HERE';
  priya_id UUID := 'PASTE_PRIYA_UUID_HERE';
  jake_id UUID := 'PASTE_JAKE_UUID_HERE';
BEGIN

-- Profiles
INSERT INTO public.profiles (id, username, display_name, bio)
VALUES
  (eric_id, 'eric_fasts', 'Eric Torres', '16:8 warrior. Down 15lbs in 2 months. Coffee before noon only.'),
  (ariel_id, 'ariel_fit', 'Ariel Chen', 'Fitness coach. 20:4 OMAD. Runner. Plant-based.'),
  (marcus_id, 'marcus_run', 'Marcus Webb', 'Marathon runner. 18:6 IF. Chasing a sub-3hr marathon.'),
  (priya_id, 'priya_yoga', 'Priya Sharma', 'Yoga teacher. 16:8. Mindfulness + fasting = clarity.'),
  (jake_id, 'jake_gains', 'Jake Morrison', 'New to fasting. Day 12. 50lbs to lose. Let''s go.')
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

-- Habits (last 14 days for Marcus)
INSERT INTO public.habits (user_id, date, exercise, no_sugar, no_smoking, exercise_minutes, fasting_hours)
SELECT marcus_id, (CURRENT_DATE - d)::text,
  true,
  CASE WHEN d < 1 THEN false ELSE true END,
  true,
  (40 + (d * 3) % 25),
  18
FROM generate_series(0, 13) AS d
ON CONFLICT (user_id, date) DO NOTHING;

-- Habits (last 14 days for Priya)
INSERT INTO public.habits (user_id, date, exercise, no_sugar, no_smoking, exercise_minutes, fasting_hours)
SELECT priya_id, (CURRENT_DATE - d)::text,
  true, true, true,
  (60 + (d * 5) % 20),
  16
FROM generate_series(0, 13) AS d
ON CONFLICT (user_id, date) DO NOTHING;

-- Habits (last 14 days for Jake)
INSERT INTO public.habits (user_id, date, exercise, no_sugar, no_smoking, exercise_minutes, fasting_hours)
SELECT jake_id, (CURRENT_DATE - d)::text,
  CASE WHEN d % 2 = 0 THEN true ELSE false END,
  CASE WHEN d < 3 THEN false ELSE true END,
  true,
  CASE WHEN d % 2 = 0 THEN (20 + (d * 5) % 15) ELSE 0 END,
  CASE WHEN d < 1 THEN 14 ELSE 16 END
FROM generate_series(0, 13) AS d
ON CONFLICT (user_id, date) DO NOTHING;

-- Posts for Eric
INSERT INTO public.posts (user_id, type, content, created_at) VALUES
  (eric_id, 'fasting_complete', 'Completed a 16:8 fast! Feeling unstoppable.', NOW() - interval '2 hours'),
  (eric_id, 'exercise', 'Crushing 30min of chest and triceps today', NOW() - interval '8 hours'),
  (eric_id, 'fasting', 'Hour 14 of my 16:8. The hunger waves come and go. Black coffee helps.', NOW() - interval '14 hours'),
  (eric_id, 'general', 'Day 45 of my fasting journey. Down 15lbs total. The energy is unreal.', NOW() - interval '1 day'),
  (eric_id, 'workout_complete', 'Leg day done. Squats, lunges, and calf raises. Walking tomorrow will be interesting.', NOW() - interval '1.5 days'),
  (eric_id, 'fasting_complete', '18:6 today. Extended an extra 2 hours. Surprisingly manageable.', NOW() - interval '2 days'),
  (eric_id, 'exercise', 'Morning 5K run. New personal best: 23:42. The fasting clarity is real.', NOW() - interval '2.5 days'),
  (eric_id, 'general', 'No sugar for 30 days. Had to stare down a birthday cake today. Stayed strong.', NOW() - interval '3 days'),
  (eric_id, 'fasting_complete', '16:8 complete. Broke fast with grilled chicken and avocado.', NOW() - interval '3.5 days'),
  (eric_id, 'workout_complete', 'Push day: bench press, overhead press, tricep dips. 45min total.', NOW() - interval '4 days'),
  (eric_id, 'general', 'Sleep quality since fasting started: from 5hrs to 7.5hrs. Game changer.', NOW() - interval '5 days'),
  (eric_id, 'fasting', 'Starting a 24hr fast. Wish me luck. Water and electrolytes only.', NOW() - interval '5.5 days'),
  (eric_id, 'exercise', 'Pull day: deadlifts, rows, bicep curls. Back is feeling strong.', NOW() - interval '6 days'),
  (eric_id, 'fasting_complete', '24hr fast complete! First one ever. Refeeding carefully tonight.', NOW() - interval '6.5 days');

-- Posts for Ariel
INSERT INTO public.posts (user_id, type, content, created_at) VALUES
  (ariel_id, 'fasting_complete', '20:4 OMAD complete. Bone broth to break the fast.', NOW() - interval '3 hours'),
  (ariel_id, 'workout_complete', 'Just finished a 45min HIIT session. Heart rate peaked at 175.', NOW() - interval '5 hours'),
  (ariel_id, 'exercise', 'Morning run done before sunrise. 5K in 24min.', NOW() - interval '1 day'),
  (ariel_id, 'general', 'Week 3 of 20:4. Sleep has improved dramatically. No more 2am wakes.', NOW() - interval '3 days'),
  (ariel_id, 'fasting', 'Currently fasting. 14 hours in. Black coffee is keeping me going.', NOW() - interval '6 hours');

-- Posts for Marcus
INSERT INTO public.posts (user_id, type, content, created_at) VALUES
  (marcus_id, 'exercise', '10K tempo run this morning. Negative splits the whole way. Fasted running hits different.', NOW() - interval '4 hours'),
  (marcus_id, 'fasting_complete', '18:6 done. Refueled with oatmeal and banana. Ready for tomorrow''s long run.', NOW() - interval '10 hours'),
  (marcus_id, 'general', 'Race day in 3 weeks. Peak training week. 60 miles scheduled. Fasting is keeping my energy stable.', NOW() - interval '1 day'),
  (marcus_id, 'workout_complete', 'Hill repeats x8. Quads are screaming. Worth it.', NOW() - interval '2 days'),
  (marcus_id, 'fasting', 'Hour 16 of 18. The last 2 hours are always the mental game.', NOW() - interval '2 hours'),
  (marcus_id, 'exercise', 'Easy recovery run. 5K at conversational pace. Legs still sore from yesterday.', NOW() - interval '3 days'),
  (marcus_id, 'general', 'PR on my 5K: 19:47. Under 20 min for the first time! Fasting + consistent training = results.', NOW() - interval '4 days');

-- Posts for Priya
INSERT INTO public.posts (user_id, type, content, created_at) VALUES
  (priya_id, 'general', 'Morning meditation + 16:8 fasting. My mind has never been this clear. 60 days in.', NOW() - interval '2 hours'),
  (priya_id, 'exercise', '90min vinyasa flow. Balance and focus are on another level since I started fasting.', NOW() - interval '8 hours'),
  (priya_id, 'fasting_complete', '16:8 complete. Broke fast with a smoothie bowl. Nourish to flourish.', NOW() - interval '1 day'),
  (priya_id, 'general', 'Teaching my first class since starting IF. Students noticed the change in my energy. Sharing the practice.', NOW() - interval '2 days'),
  (priya_id, 'fasting', 'Hour 12. Deep breathing through the hunger. It''s just a wave. It passes.', NOW() - interval '4 hours'),
  (priya_id, 'general', 'Day 60 no sugar. My skin is glowing. Cravings are gone. This is freedom.', NOW() - interval '3 days');

-- Posts for Jake
INSERT INTO public.posts (user_id, type, content, created_at) VALUES
  (jake_id, 'general', 'Day 12 of 16:8. Down 6lbs already. First week was brutal. Now it''s routine.', NOW() - interval '3 hours'),
  (jake_id, 'exercise', 'Walked 10K steps today. Not much but for a 280lb guy, it''s a start.', NOW() - interval '7 hours'),
  (jake_id, 'fasting_complete', '16:8 done! Meal prepped for the week. Chicken, rice, broccoli. Simple.', NOW() - interval '1 day'),
  (jake_id, 'general', 'My doctor said keep going. Blood pressure already improving. This is why I''m doing this.', NOW() - interval '2 days'),
  (jake_id, 'fasting', 'Hour 14. Hungry but determined. 50lbs to go. One day at a time.', NOW() - interval '5 hours'),
  (jake_id, 'exercise', 'First time in a gym in 2 years. Just did machines. Felt good to be back.', NOW() - interval '3 days'),
  (jake_id, 'general', 'My wife started fasting too. Couple goals. Accountability is everything.', NOW() - interval '4 days'),
  (jake_id, 'general', 'Scale said 274 this morning. Started at 280. 6lbs down. Small wins.', NOW() - interval '5 days');

END $$;
