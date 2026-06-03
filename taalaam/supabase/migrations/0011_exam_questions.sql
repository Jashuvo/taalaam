-- Exam question pool: AI-generated once per unit, sampled randomly each attempt.
-- Each unit has ~30 questions; the Flutter app picks 10-12 per exam session.

CREATE TABLE IF NOT EXISTS exam_questions (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id      UUID        NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  type         TEXT        NOT NULL,
  sort_order   INT         NOT NULL DEFAULT 0,
  prompt_bn    TEXT,
  prompt_ar    TEXT,
  correct_answer JSONB     NOT NULL DEFAULT '{}'::jsonb,
  distractors  JSONB,
  grammar_note_bn TEXT,
  difficulty   INT         NOT NULL DEFAULT 1,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_exam_questions_unit_id ON exam_questions(unit_id);

ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;

-- Learners can read all exam questions (needed to fetch the pool)
CREATE POLICY "exam_questions_read" ON exam_questions
  FOR SELECT USING (true);
