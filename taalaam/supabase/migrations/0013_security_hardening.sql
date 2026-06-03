-- Security hardening: close RLS gaps identified in audit.

-- 1. exam_questions: add admin write policies (only SELECT existed before)
CREATE POLICY "admin_manage_exam_questions" ON exam_questions
  FOR ALL TO authenticated
  USING  ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

-- 2. vocabulary: learners can read published-lesson vocab; admin can do all
ALTER TABLE vocabulary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "vocab_read_published" ON vocabulary
  FOR SELECT
  USING (
    lesson_id IN (
      SELECT id FROM lessons WHERE status = 'published'
    )
  );

CREATE POLICY "admin_manage_vocab" ON vocabulary
  FOR ALL TO authenticated
  USING  ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');

-- 3. exercises: same pattern (read published, admin all)
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "exercises_read_published" ON exercises
  FOR SELECT
  USING (
    lesson_id IN (
      SELECT id FROM lessons WHERE status = 'published'
    )
  );

CREATE POLICY "admin_manage_exercises" ON exercises
  FOR ALL TO authenticated
  USING  ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com')
  WITH CHECK ((auth.jwt() ->> 'email') = 'jubayedsr@gmail.com');
