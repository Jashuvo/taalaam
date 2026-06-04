-- Add streak_goal column for once-shown goal selection screen
ALTER TABLE streaks ADD COLUMN IF NOT EXISTS streak_goal INT;
