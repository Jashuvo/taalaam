// supabase/functions/generate-exam/index.ts
// Admin: generates a 30-question pool for a unit and stores it in exam_questions.
//        Also creates/updates the exam lesson record for completion tracking.
// Deploy: supabase functions deploy generate-exam --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SYSTEM_PROMPT = `You are an expert Gamification Architect and Arabic Linguist creating an Exam Question Pool for a Duolingo-style Arabic learning app targeting Bengali speakers (Classical/Fusha Arabic, Islamic/Salafi context).

Your pool must be a cumulative review of ALL vocabulary and grammar introduced in the provided module.

### POOL COMPOSITION (exactly 30 questions)
- 10 x tap_to_build  (sentence building — Arabic word tiles put in correct order)
- 8  x multiple_choice (definition/meaning matching with 4 options)
- 6  x fill_in_blank  (complete Arabic sentence — one blank)
- 6  x true_false     (is the translation correct? true/false)

### DESIGN RULES
1. Every question must be distinct — no two questions test the same word or concept.
2. Higher difficulty than regular lessons: use slightly longer or combined sentences.
3. Always include full harakat (short vowel marks) on every Arabic word.
4. Distractors must be plausible — other vocabulary from THIS MODULE only.
5. Islamic/Salafi context maintained throughout.
6. tap_to_build: provide the Arabic sentence as individual word tiles in correct_answer.words_ar[], and the Bengali translation in correct_answer.translation_bn.
7. fill_in_blank: correct_answer.answer is the missing Arabic word (with harakat). prompt_ar contains the full sentence with «___» marking the blank.
8. true_false: prompt_ar is the Arabic phrase, prompt_bn is a Bengali translation (some wrong). correct_answer.is_true is boolean.
9. multiple_choice: correct_answer.options[] has 4 Bengali options, correct_answer.correct_index is 0-based index of correct option.

### OUTPUT FORMAT (STRICT JSON — NO MARKDOWN)
Return ONLY this JSON object:
{
  "xp_reward": 50,
  "gem_reward": 10,
  "questions": [
    {
      "type": "multiple_choice",
      "sort_order": 1,
      "prompt_bn": "«مَسْجِدٌ» শব্দের অর্থ কী?",
      "prompt_ar": "مَسْجِدٌ",
      "correct_answer": {"options": ["মসজিদ", "বাড়ি", "স্কুল", "দোকান"], "correct_index": 0},
      "distractors": null,
      "grammar_note_bn": "মসজিদ = مَسْجِدٌ (পুংলিঙ্গ বিশেষ্য)।",
      "difficulty": 2
    }
  ]
}`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const enc = new TextEncoder();
  const respond = async (body: unknown) => {
    await writer.write(enc.encode(JSON.stringify(body)));
    await writer.close();
  };

  (async () => {
    try {
      const { unit_id } = await req.json();
      if (!unit_id) { await respond({ error: 'unit_id is required' }); return; }

      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      );

      // Fetch unit metadata
      const { data: unit } = await supabase
        .from('units').select('id, title_bn, title_ar').eq('id', unit_id).single();

      // Fetch all non-exam lessons in this unit
      const { data: lessons } = await supabase
        .from('lessons')
        .select('id, title_bn, level')
        .eq('unit_id', unit_id)
        .eq('is_exam', false)
        .order('sort_order');

      if (!lessons || lessons.length === 0) {
        await respond({ error: 'No lessons found in this unit' });
        return;
      }

      // Build context from lessons (exercises + vocab)
      const examContext: string[] = [];
      for (const lesson of lessons.slice(0, 10)) {
        const { data: exs } = await supabase
          .from('exercises')
          .select('type, prompt_bn, prompt_ar, correct_answer')
          .eq('lesson_id', lesson.id)
          .limit(3);

        const { data: vocab } = await supabase
          .from('vocabulary')
          .select('arabic, meaning_bn, word_type')
          .eq('lesson_id', lesson.id)
          .limit(8);

        let ctx = `LESSON: ${lesson.title_bn} (${lesson.level})\n`;
        if (vocab && vocab.length > 0) {
          ctx += `Vocabulary: ${vocab.map((v: any) => `${v.arabic} = ${v.meaning_bn}`).join(', ')}\n`;
        }
        if (exs && exs.length > 0) {
          ctx += `Sample exercises: ${exs.map((e: any) => e.prompt_bn ?? e.prompt_ar ?? '').filter(Boolean).join(' | ')}\n`;
        }
        examContext.push(ctx);
      }

      const userMessage =
        `Generate a 30-question Exam Pool for module: "${unit?.title_bn ?? ''}" (${unit?.title_ar ?? ''})\n\n` +
        `MODULE CONTENT:\n${examContext.join('\n')}\n\n` +
        `Return the strict JSON object as specified. Exactly 30 questions. No markdown.`;

      const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
      const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash', systemInstruction: SYSTEM_PROMPT });
      const result = await model.generateContent(userMessage);
      const rawText = result.response.text().trim()
        .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

      const poolData = JSON.parse(rawText);
      const questions: any[] = poolData.questions ?? [];
      const xpReward: number = poolData.xp_reward ?? 50;
      const gemReward: number = poolData.gem_reward ?? 10;

      if (questions.length === 0) {
        await respond({ error: 'Gemini returned no questions' });
        return;
      }

      // Replace existing question pool for this unit
      await supabase.from('exam_questions').delete().eq('unit_id', unit_id);

      const rows = questions.map((q: any, i: number) => ({
        unit_id,
        type: q.type,
        sort_order: i + 1,
        prompt_bn: q.prompt_bn ?? null,
        prompt_ar: q.prompt_ar ?? null,
        correct_answer: q.correct_answer ?? {},
        distractors: q.distractors ?? null,
        grammar_note_bn: q.grammar_note_bn ?? null,
        difficulty: q.difficulty ?? 1,
      }));

      const { error: insertErr } = await supabase.from('exam_questions').insert(rows);
      if (insertErr) {
        await respond({ error: `Failed to store questions: ${insertErr.message}` });
        return;
      }

      // Create or update the exam lesson record (for progress tracking)
      const { data: existing } = await supabase
        .from('lessons')
        .select('id')
        .eq('unit_id', unit_id)
        .eq('is_exam', true)
        .maybeSingle();

      const examLessonId = existing?.id ?? crypto.randomUUID();
      await supabase.from('lessons').upsert({
        id: examLessonId,
        unit_id,
        title_bn: `${unit?.title_bn ?? 'মডিউল'} — পরীক্ষা`,
        title_ar: unit?.title_ar ?? null,
        sort_order: 9999,
        xp_reward: xpReward,
        gem_reward: gemReward,
        is_exam: true,
        status: 'published',
        level: 'advanced',
      }, { onConflict: 'id' });

      await respond({
        exam_lesson_id: examLessonId,
        question_count: questions.length,
        xp_reward: xpReward,
        gem_reward: gemReward,
        message: `Exam pool created: ${questions.length} questions stored.`,
      });

    } catch (e: any) {
      const msg = e instanceof Error ? e.message : String(e);
      try { await respond({ error: msg }); } catch (_) {}
    }
  })();

  return new Response(readable, {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
});
