// supabase/functions/generate-exam/index.ts
// Generates fresh exam questions for a unit using Gemini.
// Called each time a learner starts the exam (dynamic content, never repeated).
// Also called by admin to create/register the exam lesson record.
// Deploy: supabase functions deploy generate-exam --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SYSTEM_PROMPT = `You are an expert Gamification Architect and Arabic Linguist creating End-of-Module Exams for a Duolingo-style Arabic learning app targeting Bengali speakers (Classical/Fusha Arabic, Islamic/Salafi context).

Your exam must be a cumulative review of ALL vocabulary and grammar introduced in the provided module.

### EXAM DESIGN RULES
1. Generate exactly 10-12 questions covering all exercise types the app supports.
2. Mix types: at least 2 multiple_choice, 2 drag_drop, 2 true_false, 2 fill_in_blank, 1 tap_to_build, 1 word_scramble.
3. Higher difficulty than regular lessons: use slightly longer or combined sentences.
4. Always include full harakat on every Arabic word.
5. Distractors must be plausible — other vocabulary from THIS MODULE.
6. Islamic/Salafi context maintained throughout.
7. The exam should feel like a proper final test, not a repeat of any single lesson.

### OUTPUT FORMAT (STRICT JSON — NO MARKDOWN)
Return ONLY this JSON object:
{
  "title_bn": "মডিউল পরীক্ষা",
  "xp_reward": 50,
  "gem_reward": 10,
  "exercises": [
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
      const { unit_id, admin_mode } = await req.json();
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

      // Fetch exercises from all lessons (sample up to 5 per lesson for context)
      const examContext: string[] = [];
      for (const lesson of lessons.slice(0, 8)) {
        const { data: exs } = await supabase
          .from('exercises')
          .select('type, prompt_bn, prompt_ar, correct_answer')
          .eq('lesson_id', lesson.id)
          .limit(3);

        const { data: vocab } = await supabase
          .from('vocabulary')
          .select('arabic, meaning_bn, word_type')
          .eq('lesson_id', lesson.id)
          .limit(6);

        let lessonCtx = `LESSON: ${lesson.title_bn} (${lesson.level})\n`;
        if (vocab && vocab.length > 0) {
          lessonCtx += `Vocabulary: ${vocab.map((v: any) => `${v.arabic} = ${v.meaning_bn}`).join(', ')}\n`;
        }
        if (exs && exs.length > 0) {
          lessonCtx += `Sample exercises: ${exs.map((e: any) => e.prompt_bn ?? e.prompt_ar ?? '').filter(Boolean).join(' | ')}\n`;
        }
        examContext.push(lessonCtx);
      }

      const userMessage =
        `Generate an End-of-Module Exam for: "${unit?.title_bn ?? ''}" (${unit?.title_ar ?? ''})\n\n` +
        `MODULE CONTENT TO REVIEW:\n${examContext.join('\n')}\n\n` +
        `Return the strict JSON object as specified. No markdown. Exactly 10-12 exercises.`;

      const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
      const model = genAI.getGenerativeModel({ model: 'gemini-3.5-flash', systemInstruction: SYSTEM_PROMPT });
      const result = await model.generateContent(userMessage);
      const rawText = result.response.text().trim()
        .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

      const examData = JSON.parse(rawText);
      const exercises: any[] = examData.exercises ?? [];
      const xpReward: number = examData.xp_reward ?? 50;
      const gemReward: number = examData.gem_reward ?? 10;

      if (exercises.length === 0) {
        await respond({ error: 'Gemini returned no exercises' });
        return;
      }

      // In admin_mode: create/update the exam lesson record in DB
      if (admin_mode) {
        // Check if exam lesson already exists
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
          exercises,
          xp_reward: xpReward,
          gem_reward: gemReward,
          message: 'Exam lesson created/updated successfully',
        });
        return;
      }

      // Learner mode: just return fresh exercises (don't write to DB)
      await respond({ exercises, xp_reward: xpReward, gem_reward: gemReward });

    } catch (e: any) {
      const msg = e instanceof Error ? e.message : String(e);
      try { await respond({ error: msg }); } catch (_) {}
    }
  })();

  return new Response(readable, {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
});
