-- unlock_metadata: stores text-unlock progress info per unit (e.g. {text_name, section, percentage})
ALTER TABLE units ADD COLUMN IF NOT EXISTS unlock_metadata JSONB DEFAULT '{}'::jsonb;

-- Group accountability (Halaqah) streak tracking
ALTER TABLE groups ADD COLUMN IF NOT EXISTS group_streak INT DEFAULT 0;
ALTER TABLE groups ADD COLUMN IF NOT EXISTS last_streak_update TIMESTAMPTZ;

-- Allow any group member to update group_streak + last_streak_update (fire-and-forget from client)
CREATE POLICY "members update group streak" ON groups FOR UPDATE
  USING (exists (
    select 1 from group_memberships gm
    where gm.group_id = groups.id and gm.user_id = auth.uid()
  ))
  WITH CHECK (exists (
    select 1 from group_memberships gm
    where gm.group_id = groups.id and gm.user_id = auth.uid()
  ));

-- Optimized view for FSRS memory-decay notifier cron
-- Flags users with ≥1 card that is due (or overdue) for review today.
CREATE OR REPLACE VIEW v_decaying_srs_cards AS
SELECT
    s.user_id,
    p.display_name,
    COUNT(s.id) AS decaying_count
FROM srs_cards s
JOIN profiles p ON s.user_id = p.id
WHERE s.stability > 0
  AND (NOW()::date - s.due_date::date) >= 0
GROUP BY s.user_id, p.display_name;
