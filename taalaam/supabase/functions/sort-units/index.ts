// supabase/functions/sort-units/index.ts
// Reorders units within a track in optimal pedagogical sequence.
// Deploy: supabase functions deploy sort-units --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const SYSTEM_PROMPT = `You are an expert Curriculum Architect and Arabic Linguist specializing in designing gamified, step-by-step language courses (Duolingo-style micro-learning). Your task is to logically sort and optimize a raw list of learning modules.

The target audience consists of Bengali speakers learning Classical/Fusha Arabic, with a special emphasis on Islamic/Salafi vocabulary contexts (combining essential everyday nouns with Quranic, Hadith, and scholarly terminology).

### PEDAGOGICAL ORDERING RULES
Arrange content strictly following these language-acquisition principles:
1. Vocabulary Before Syntax: Independent nouns/vocabulary must be introduced before learners are asked to use them in structures.
2. Pointers Before Sentences: Demonstrative Pronouns/Pointers (أسماء الإشارة like هذا / هذه) and Personal Pronouns must be taught right after basic nouns, but BEFORE full sentence building.
3. Gradual Cognitive Load: Progression must go from:
   Isolated Nouns -> Pointers + Nouns -> Short Nominal Sentences -> Verbal Sentences -> Advanced/Complex Expressions.
4. Eliminate Redundancy: If two modules teach the same grammar mechanic, they should be ordered so Part 1 (simpler vocabulary) comes before Part 2 (complex vocabulary).
5. Scannable Progression: Order must feel natural — a learner completing module N should be ready for module N+1 without gaps.

### OUTPUT RULE (CRITICAL)
You must return ONLY a raw JSON array of IDs in the correct pedagogical order.
No markdown. No explanation. No extra text. Just the array.
Example: ["id-1","id-2","id-3"]`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { track_id } = await req.json();
    if (!track_id) throw new Error('track_id is required');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: units, error: unitErr } = await supabase
      .from('units')
      .select('id, title_bn, title_ar')
      .eq('track_id', track_id)
      .order('sort_order');

    if (unitErr) throw new Error(unitErr.message);
    if (!units || units.length < 2) {
      return new Response(
        JSON.stringify({ sorted_ids: units?.map((u: any) => u.id) ?? [] }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const userMessage =
      'Sort these Arabic learning units into the optimal pedagogical sequence for Bengali-speaking learners. ' +
      'Apply the curriculum architecture rules from your system instructions.\n\n' +
      'Units to sort:\n' +
      units.map((u: any, i: number) =>
        `${i + 1}. ID: ${u.id}\n   Bengali Title: ${u.title_bn}\n   Arabic Title: ${u.title_ar ?? '—'}`
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
    const knownIds = new Set(units.map((u: any) => u.id as string));
    if (!Array.isArray(sortedIds) || !sortedIds.every((id) => knownIds.has(id))) {
      throw new Error(`Invalid IDs from Gemini: ${rawText.slice(0, 200)}`);
    }

    await Promise.all(
      sortedIds.map((id, i) =>
        supabase.from('units').update({ sort_order: i }).eq('id', id),
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
