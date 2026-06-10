-- 0032: find a short authentic ayah containing a given word — used to ground
-- ayah_complete / ayah_order exercises in the 'frequent' unit type, where the
-- source words don't carry surah/ayah location info.
CREATE OR REPLACE FUNCTION find_short_ayah_for_word(word_arabic TEXT, max_words INT)
RETURNS TABLE(surah INT, ayah INT, word_count BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  WITH ayah_lengths AS (
    SELECT qw.surah, qw.ayah, COUNT(*) AS word_count
    FROM quran_words qw
    GROUP BY qw.surah, qw.ayah
  )
  SELECT al.surah, al.ayah, al.word_count
  FROM quran_words qw
  JOIN ayah_lengths al ON al.surah = qw.surah AND al.ayah = qw.ayah
  WHERE qw.arabic = word_arabic AND al.word_count <= max_words
  ORDER BY al.word_count ASC
  LIMIT 1;
$$;
