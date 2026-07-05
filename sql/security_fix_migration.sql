-- ============================================================
-- Security Fix Migration for Supabase
-- Applied: 2026-07-05
-- Idempotent: Safe to re-run
-- ============================================================

-- ============================================================
-- 1. FIX: Enable RLS on comments table (CRITICAL)
-- ============================================================

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to re-apply cleanly
DROP POLICY IF EXISTS "Comments are public" ON public.comments;
DROP POLICY IF EXISTS "Users can insert comments" ON public.comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON public.comments;

-- Comments are public for reads (fast, no joins)
CREATE POLICY "Comments are public" ON public.comments
  FOR SELECT USING (true);

-- Users can insert comments as themselves
CREATE POLICY "Users can insert comments" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update their own comments" ON public.comments
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments" ON public.comments
  FOR DELETE USING (auth.uid() = user_id);


-- ============================================================
-- 2. FIX: Add missing DELETE policies
-- ============================================================

DROP POLICY IF EXISTS "Users can delete their own timers" ON public.active_timers;
CREATE POLICY "Users can delete their own timers" ON public.active_timers
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete friendships they're involved in" ON public.friendships;
CREATE POLICY "Users can delete friendships they're involved in" ON public.friendships
  FOR DELETE USING (
    auth.uid() = sender_id
    OR auth.uid() = receiver_id
  );

DROP POLICY IF EXISTS "Users can delete their own habits" ON public.habits;
CREATE POLICY "Users can delete their own habits" ON public.habits
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;
CREATE POLICY "Users can delete their own notifications" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON public.profiles;
CREATE POLICY "Users can delete their own profile" ON public.profiles
  FOR DELETE USING (auth.uid() = id);


-- ============================================================
-- 3. FIX: Add missing foreign key ON DELETE rules
-- ============================================================

ALTER TABLE public.comments
  DROP CONSTRAINT IF EXISTS comments_post_id_fkey,
  ADD CONSTRAINT comments_post_id_fkey
    FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;

ALTER TABLE public.comments
  DROP CONSTRAINT IF EXISTS comments_user_id_fkey,
  ADD CONSTRAINT comments_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;


-- ============================================================
-- 4. updated_at auto-update triggers
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at to tables that don't have it (ignore if exists)
DO $$ BEGIN
  ALTER TABLE active_timers ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE comments ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE friendships ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE notifications ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE posts ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE profiles ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;
DO $$ BEGIN
  ALTER TABLE reactions ADD COLUMN updated_at timestamp with time zone DEFAULT now();
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- Create triggers (drop first to avoid duplicates)
DROP TRIGGER IF EXISTS set_updated_at ON active_timers;
DROP TRIGGER IF EXISTS set_updated_at ON comments;
DROP TRIGGER IF EXISTS set_updated_at ON friendships;
DROP TRIGGER IF EXISTS set_updated_at ON habits;
DROP TRIGGER IF EXISTS set_updated_at ON notifications;
DROP TRIGGER IF EXISTS set_updated_at ON posts;
DROP TRIGGER IF EXISTS set_updated_at ON profiles;
DROP TRIGGER IF EXISTS set_updated_at ON reactions;

CREATE TRIGGER set_updated_at BEFORE UPDATE ON active_timers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON friendships FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON habits FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON reactions FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ============================================================
-- 5. Performance: Indexes for RLS policy lookups
-- ============================================================

CREATE INDEX IF NOT EXISTS friendships_accepted_idx ON friendships (sender_id, receiver_id)
  WHERE status = 'accepted';

CREATE INDEX IF NOT EXISTS idx_active_timers_user_id ON active_timers (user_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments (user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments (post_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_from_user_id ON notifications (from_user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts (user_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user_id ON reactions (user_id);
CREATE INDEX IF NOT EXISTS idx_reactions_post_id ON reactions (post_id);


-- ============================================================
-- 6. VERIFICATION: Run these to confirm fixes
-- ============================================================

SELECT
  relname,
  relrowsecurity as rls_enabled,
  relforcerowsecurity as rls_enforced
FROM pg_class
WHERE relnamespace = 'public'::regnamespace
  AND relkind = 'r'
ORDER BY relname;

SELECT
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS references_table,
  rc.delete_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
JOIN information_schema.referential_constraints rc ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
