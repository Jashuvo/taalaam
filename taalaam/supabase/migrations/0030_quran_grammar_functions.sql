-- 0030: Grammar micro-units — particle (harf) + pronoun (damir) frequency RPCs

-- Strip Arabic diacritics/tatweel so whitelist forms match quran_words.arabic
-- regardless of harakat variation.
CREATE OR REPLACE FUNCTION normalize_arabic_form(input TEXT)
RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
  SELECT regexp_replace(input, '[ً-ْٰـ]', '', 'g');
$$;

-- Top particle (harf) forms by frequency, restricted to a known particle whitelist
-- (for Unit: হারফ মাস্টারি)
CREATE OR REPLACE FUNCTION get_quran_particles(limit_count INT, offset_count INT)
RETURNS TABLE(arabic TEXT, meaning_bn TEXT, frequency BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  WITH particle_whitelist(form) AS (
    VALUES
      ('وَ'), ('فَ'), ('فِي'), ('مِنْ'), ('عَلَى'), ('إِلَى'), ('عَنْ'),
      ('إِنَّ'), ('أَنَّ'), ('لَا'), ('مَا'), ('إِنْ'), ('لَمْ'), ('لَنْ'),
      ('قَدْ'), ('ثُمَّ'), ('أَوْ'), ('بَلْ'), ('حَتَّى'), ('إِلَّا'), ('لَوْ'),
      ('كَيْ'), ('لِ'), ('بِ'), ('كَ'), ('يَا'), ('هَلْ'), ('أَمْ'), ('إِذَا'), ('إِذْ')
  )
  SELECT qw.arabic, MAX(qw.meaning_bn) AS meaning_bn, COUNT(*) AS frequency
  FROM quran_words qw
  JOIN particle_whitelist pw
    ON normalize_arabic_form(qw.arabic) = normalize_arabic_form(pw.form)
  WHERE qw.meaning_bn IS NOT NULL AND qw.meaning_bn <> ''
  GROUP BY qw.arabic
  ORDER BY frequency DESC
  LIMIT limit_count OFFSET offset_count;
$$;

-- Top pronoun (damir) forms by frequency: detached pronouns plus the most
-- frequent forms carrying attached pronoun suffixes (for Unit: সর্বনাম ও যুক্ত সর্বনাম)
CREATE OR REPLACE FUNCTION get_quran_pronoun_words(limit_count INT, offset_count INT)
RETURNS TABLE(arabic TEXT, meaning_bn TEXT, frequency BIGINT)
LANGUAGE sql SECURITY DEFINER AS $$
  WITH pronoun_whitelist(form) AS (
    VALUES
      ('هُوَ'), ('هِيَ'), ('هُمْ'), ('أَنْتَ'), ('أَنْتُمْ'), ('أَنَا'), ('نَحْنُ'),
      ('رَبُّكُمْ'), ('رَبَّنَا'), ('لَهُ'), ('لَهُمْ'), ('عَلَيْهِمْ'), ('مِنْكُمْ'), ('إِلَيْكَ')
  )
  SELECT qw.arabic, MAX(qw.meaning_bn) AS meaning_bn, COUNT(*) AS frequency
  FROM quran_words qw
  JOIN pronoun_whitelist pw
    ON normalize_arabic_form(qw.arabic) = normalize_arabic_form(pw.form)
  WHERE qw.meaning_bn IS NOT NULL AND qw.meaning_bn <> ''
  GROUP BY qw.arabic
  ORDER BY frequency DESC
  LIMIT limit_count OFFSET offset_count;
$$;
