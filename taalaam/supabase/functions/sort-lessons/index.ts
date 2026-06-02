// supabase/functions/sort-lessons/index.ts
// Reorders lessons within a unit in optimal pedagogical sequence.
// Deploy: supabase functions deploy sort-lessons --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SYSTEM_PROMPT = `You are an expert Curriculum Architect and Arabic Linguist specializing in designing gamified, step-by-step language courses (Duolingo-style micro-learning). Your task is to logically sort and optimize a raw list of sub-lessons within a single learning unit.

The target audience consists of Bengali speakers learning Classical/Fusha Arabic, with a special emphasis on Islamic/Salafi vocabulary contexts (combining essential everyday nouns with Quranic, Hadith, and scholarly terminology).

### PEDAGOGICAL ORDERING RULES
Arrange lessons strictly following these language-acquisition principles:
1. Vocabulary Before Syntax: Independent nouns/vocabulary must be introduced before learners use them in structures.
2. Pointers Before Sentences: Demonstrative Pronouns (هذا / هذه) and Personal Pronouns must come right after basic nouns, but BEFORE full sentence building.
3. Gradual Cognitive Load:
   Isolated Nouns -> Pointers + Nouns -> Short Nominal Sentences -> Verbal Sentences -> Advanced Expressions.
4. Difficulty Levels: 'beginner' lessons must come before 'intermediate', which come before 'advanced'.
5. Eliminate Redundancy: If two lessons cover the same mechanic, order them so simpler vocabulary context comes first.

### CRITICAL CONSTRAINT — DUPLICATE DETECTION
Do NOT allow sequential lessons with near-identical target structures (e.g., repeating "Bab Nasara" multiple times). If multiple lessons target the same Arabic verb pattern (باب), the same grammatical construction, or the same vocabulary theme, they MUST be flagged as duplicates that should be combined into a single lesson as sub-exercises rather than sitting as separate top-level lessons.

### OUTPUT FORMAT (CRITICAL)
Return a single JSON object — no markdown, no extra text:
{
  "sorted_ids": ["id-1","id-2","id-3"],
  "duplicates": [
    { "ids": ["id-2","id-5"], "reason": "Both lessons teach باب نصر with overlapping vocabulary" }
  ]
}
If no duplicates are detected, return "duplicates": [].`;

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

      const { data: lessons, error: lessonErr } = await supabase
        .from('lessons')
        .select('id, title_bn, title_ar, level')
        .eq('unit_id', unit_id)
        .order('sort_order');

      if (lessonErr) { await respond({ error: lessonErr.message }); return; }
      if (!lessons || lessons.length < 2) {
        await respond({ sorted_ids: lessons?.map((l: any) => l.id) ?? [] });
        return;
      }

      const userMessage =
        'Sort these Arabic lessons into the optimal pedagogical sequence.\n' +
        'Also flag any duplicates per the CRITICAL CONSTRAINT in your instructions.\n\n' +
        'Lessons to sort:\n' +
        lessons.map((l: any, i: number) =>
          `${i + 1}. ID: ${l.id}\n   Bengali Title: ${l.title_bn}\n   Arabic Title: ${l.title_ar ?? '—'}\n   Level: ${l.level}`
        ).join('\n\n') +
        '\n\nReturn the JSON object as specified in OUTPUT FORMAT. Nothing else.';

      const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
      const model = genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
        systemInstruction: SYSTEM_PROMPT,
      });

      const result = await model.generateContent(userMessage);
      const rawText = result.response.text().trim()
        .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

      const parsed = JSON.parse(rawText);
      const sortedIds: string[] = parsed.sorted_ids ?? parsed;
      const duplicates: any[] = parsed.duplicates ?? [];

      const knownIds = new Set(lessons.map((l: any) => l.id as string));
      if (!Array.isArray(sortedIds) || !sortedIds.every((id) => knownIds.has(id))) {
        await respond({ error: `Invalid IDs from Gemini: ${rawText.slice(0, 200)}` });
        return;
      }

      await Promise.all(
        sortedIds.map((id, i) =>
          supabase.from('lessons').update({ sort_order: i }).eq('id', id),
        ),
      );

      await respond({ sorted_ids: sortedIds, duplicates });
    } catch (e: any) {
      const msg = e instanceof Error ? e.message : String(e);
      try { await respond({ error: msg }); } catch (_) { /* writer already closed */ }
    }
  })();

  return new Response(readable, {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
});
