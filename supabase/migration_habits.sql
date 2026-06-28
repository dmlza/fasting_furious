-- Run this in Supabase SQL editor after the base schema

-- 10. Habits (daily binary checkmarks)
CREATE TABLE habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  exercise BOOLEAN DEFAULT false,
  no_sugar BOOLEAN DEFAULT false,
  no_smoking BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, date)
);

ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can see friends' habits"
  ON habits FOR SELECT
  USING (
    auth.uid() = user_id OR
    EXISTS (
      SELECT 1 FROM friendships
      WHERE status = 'accepted'
      AND ((sender_id = auth.uid() AND receiver_id = habits.user_id) OR (receiver_id = auth.uid() AND sender_id = habits.user_id))
    )
  );

CREATE POLICY "Users can upsert their own habits"
  ON habits FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own habits"
  ON habits FOR UPDATE
  USING (auth.uid() = user_id);

-- Add emoji reaction type to existing reactions (for feed reactions)
ALTER TABLE reactions DROP CONSTRAINT IF EXISTS reactions_user_id_post_id_key;
ALTER TABLE reactions ADD COLUMN IF NOT EXISTS emoji TEXT DEFAULT '🔥';

-- Add preset_type to active_timers for fasting presets
ALTER TABLE active_timers ADD COLUMN IF NOT EXISTS preset_type TEXT CHECK (preset_type IN ('16:8', '18:6', '20:4', 'custom'));

-- Add exercise_minutes column for daily exercise tracking
ALTER TABLE habits ADD COLUMN IF NOT EXISTS exercise_minutes INTEGER DEFAULT 0;
ALTER TABLE habits ADD COLUMN IF NOT EXISTS exercise_updated_at TIMESTAMPTZ;

-- Add image_url column for photo check-in posts
ALTER TABLE posts ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Enable realtime for habits
ALTER PUBLICATION supabase_realtime ADD TABLE habits;
