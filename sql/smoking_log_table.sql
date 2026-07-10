-- Smoking log table for scientific tracking
-- Each row = one day's data

CREATE TABLE IF NOT EXISTS smoking_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  cigarettes INTEGER NOT NULL DEFAULT 0,
  trigger TEXT,
  craving_intensity INTEGER CHECK (craving_intensity >= 1 AND craving_intensity <= 5),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, date)
);

-- RLS policies
ALTER TABLE smoking_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own smoking log"
  ON smoking_log FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own smoking log"
  ON smoking_log FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own smoking log"
  ON smoking_log FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own smoking log"
  ON smoking_log FOR DELETE
  USING (auth.uid() = user_id);

-- Index for fast date-range queries
CREATE INDEX IF NOT EXISTS idx_smoking_log_user_date ON smoking_log(user_id, date);
