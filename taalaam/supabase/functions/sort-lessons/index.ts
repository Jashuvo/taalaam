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

### OUTPUT RULE (CRITICAL)
You must return ONLY a raw JSON array of IDs in the correct pedagogical order.
No markdown. No explanation. No extra text. Just the array.
Example: ["id-1","id-2","id-3"]`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { unit_id } = await req.json();
    if (!unit_id) throw new Error('unit_id is required');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: lessons, error: lessonErr } = await supabase
      .from('lessons')
      .select('id, title_bn, title_ar, level')
      .eq('unit_id', unit_id)
      .order('sort_order');

    if (lessonErr) throw new Error(lessonErr.message);
    if (!lessons || lessons.length < 2) {
      return new Response(
        JSON.stringify({ sorted_ids: lessons?.map((l: any) => l.id) ?? [] }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const userMessage =
      'Sort these Arabic lessons into the optimal pedagogical sequence for Bengali-speaking learners. ' +
      'Apply the curriculum architecture rules from your system instructions.\n\n' +
      'Lessons to sort:\n' +
      lessons.map((l: any, i: number) =>
        `${i + 1}. ID: ${l.id}\n   Bengali Title: ${l.title_bn}\n   Arabic Title: ${l.title_ar ?? '—'}\n   Level: ${l.level}`
      ).join('\n\n') +
      '\n\nReturn ONLY the JSON array of IDs in optimal order. Nothing else.';

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      systemInstruction: SYSTEM_PROMPT,
    });

    const result = await model.generateContent(userMessage);
    const rawText = result.response.text().trim()
      .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

    const sortedIds: string[] = JSON.parse(rawText);
    const knownIds = new Set(lessons.map((l: any) => l.id as string));
    if (!Array.isArray(sortedIds) || !sortedIds.every((id) => knownIds.has(id))) {
      throw new Error(`Invalid IDs from Gemini: ${rawText.slice(0, 200)}`);
    }

    await Promise.all(
      sortedIds.map((id, i) =>
        supabase.from('lessons').update({ sort_order: i }).eq('id', id),
      ),
    );

    return new Response(JSON.stringify({ sorted_ids: sortedIds }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (e: any) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
