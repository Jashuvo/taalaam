-- Add 5 Quranic-specific exercise types to the constraint
ALTER TABLE exercises DROP CONSTRAINT IF EXISTS exercises_type_check;
ALTER TABLE exercises ADD CONSTRAINT exercises_type_check CHECK (
  type IN (
    'tap_to_build',
    'fill_in_blank',
    'multiple_choice',
    'drag_drop',
    'word_scramble',
    'true_false',
    'chat_complete',
    'translate_build',
    'listen_select',
    'speak_arabic',
    'ayah_read',
    'tafsir_read',
    'ayah_context',
    'surah_theme',
    'reflection_card'
  )
);
