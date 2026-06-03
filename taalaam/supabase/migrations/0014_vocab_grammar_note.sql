-- Add grammar_note_bn to vocabulary table
-- The regenerate-vocab edge function generates per-word grammar notes
ALTER TABLE vocabulary
  ADD COLUMN IF NOT EXISTS grammar_note_bn TEXT;
