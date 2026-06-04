-- Add speak_arabic exercise type
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
    'speak_arabic'
  )
);
