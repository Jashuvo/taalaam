-- Add Islamic context snippet fields to the remote vocabulary table.
-- These are populated by the process-content and regenerate-vocab edge functions.

ALTER TABLE vocabulary
  ADD COLUMN IF NOT EXISTS context_snippet_ar TEXT,
  ADD COLUMN IF NOT EXISTS context_snippet_bn TEXT;
