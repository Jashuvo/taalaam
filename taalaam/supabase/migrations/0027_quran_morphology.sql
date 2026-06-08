-- 0027: Quranic morphology — root + POS columns, frequency/verb RPCs

ALTER TABLE quran_words ADD COLUMN IF NOT EXISTS root TEXT;
ALTER TABLE quran_words ADD COLUMN IF NOT EXISTS pos  TEXT;

CREATE INDEX IF NOT EXISTS idx_quran_words_root ON quran_words(root);
CREATE INDEX IF NOT EXISTS idx_quran_words_pos  ON quran_words(pos);

-- Top-N most frequent unique words (for Unit 2)
CREATE OR REPLACE FUNCTION get_top_quran_words(limit_count INT, offset_count INT)
RETURNS TABLE(arabic TEXT, meaning_bn TEXT, frequency BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT arabic, MAX(meaning_bn) AS meaning_bn, COUNT(*) AS frequency
  FROM quran_words
  WHERE meaning_bn IS NOT NULL AND meaning_bn <> ''
  GROUP BY arabic
  ORDER BY frequency DESC
  LIMIT limit_count OFFSET offset_count;
$$;

-- Top-N verb root families (for Unit 5) — requires root + pos populated
CREATE OR REPLACE FUNCTION get_quran_verb_roots(limit_count INT, offset_count INT)
RETURNS TABLE(root TEXT, forms TEXT[], frequency BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT root, ARRAY_AGG(DISTINCT arabic) AS forms, COUNT(*) AS frequency
  FROM quran_words
  WHERE pos = 'verb' AND root IS NOT NULL AND root <> ''
  GROUP BY root
  ORDER BY frequency DESC
  LIMIT limit_count OFFSET offset_count;
$$;
