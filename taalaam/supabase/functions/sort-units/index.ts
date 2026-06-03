// supabase/functions/sort-units/index.ts
// Sorts units AND merges near-identical duplicate units by moving lessons.
// Deploy: supabase functions deploy sort-units --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAIL = 'jubayedsr@gmail.com';
async function checkAdmin(req: Request): Promise<Response | null> {
  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json', ...cors } });
  const { data: { user }, error } = await createClient(
    Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!
  ).auth.getUser(token);
  if (error || user?.email !== ADMIN_EMAIL) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: { 'Content-Type': 'application/json', ...cors } });
  return null;
}

const GEMINI_MODELS = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite', 'gemini-2.5-flash'];

async function geminiGenerate(apiKey: string, systemInstruction: string, prompt: string): Promise<string> {
  const genAI = new GoogleGenerativeAI(apiKey);
  let lastErr: unknown;
  for (const modelName of GEMINI_MODELS) {
    try {
      const m = genAI.getGenerativeModel({ model: modelName, systemInstruction });
      const result = await m.generateContent(prompt);
      return result.response.text();
    } catch (err) {
      lastErr = err;
    }
  }
  const msg = lastErr instanceof Error ? lastErr.message : JSON.stringify(lastErr);
  throw new Error(`All Gemini models failed: ${msg}`);
}

const SYSTEM_PROMPT = `You are an expert Curriculum Architect and Arabic Linguist specializing in designing gamified, step-by-step language courses (Duolingo-style micro-learning).

The target audience consists of Bengali speakers learning Classical/Fusha Arabic, with emphasis on Islamic/Salafi vocabulary contexts.

### PEDAGOGICAL ORDERING RULES
1. Vocabulary Before Syntax: Nouns/vocabulary before structures.
2. Demonstratives Before Sentences: هذا / هذه right after basic nouns, BEFORE full sentence building.
3. Gradual Cognitive Load: Isolated Nouns → Pointers + Nouns → Nominal Sentences → Verbal Sentences → Advanced.
4. Difficulty Levels: beginner → intermediate → advanced.
5. No Cognitive Interruption: Never insert a stray vocabulary module in the middle of a focused grammar sequence.

### CRITICAL CONSTRAINT — MANDATORY MERGING
Do NOT allow sequential modules with near-identical target structures. If multiple modules target the same Arabic verb pattern (باب), the same grammatical construction, or the same vocabulary theme, they MUST be merged.

Example of what must be merged into ONE module:
- "ক্রিয়ার রূপান্তর: সাহায্য করা"
- "ক্রিয়ার রূপান্তর: বাব নাসারা"
- "ক্রিয়ার রূপান্তর ও ব্যবহার (باب نَصَرَ يَنْصُرُ)"
→ All three should become ONE module: "ক্রিয়ার রূপান্তর (বাব নাসারা)" and their lessons merged inside it.

For merged modules: pick the most descriptive title. The "keep" module gets all lessons from the others.

### OUTPUT FORMAT (STRICT JSON — NO MARKDOWN, NO EXTRA TEXT)
{
  "sorted_ids": ["id-1", "id-2", "id-3"],
  "merge_groups": [
    {
      "keep_id": "id-2",
      "keep_title_bn": "ক্রিয়ার রূপান্তর (বাব নাসারা)",
      "keep_title_ar": "تَصْرِيفُ الأَفْعَالِ: بَابُ نَصَرَ",
      "merge_ids": ["id-5", "id-8"],
      "reason": "Three modules all teach the same بَاب نَصَرَ verb conjugation pattern"
    }
  ]
}

RULES:
- sorted_ids must contain ONLY the final module IDs after merging (merge_ids are deleted, do NOT include them in sorted_ids).
- If no merges needed, return "merge_groups": [].
- Titles in keep_title_bn/ar are optional but recommended when the existing title is unclear.`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  const denied = await checkAdmin(req); if (denied) return denied;

  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const enc = new TextEncoder();

  const respond = async (body: unknown) => {
    await writer.write(enc.encode(JSON.stringify(body)));
    await writer.close();
  };

  (async () => {
    try {
      const { track_id } = await req.json();
      if (!track_id) { await respond({ error: 'track_id is required' }); return; }

      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      );

      const { data: units, error: unitErr } = await supabase
        .from('units')
        .select('id, title_bn, title_ar, sort_order')
        .eq('track_id', track_id)
        .order('sort_order');

      if (unitErr) { await respond({ error: unitErr.message }); return; }
      if (!units || units.length < 2) {
        await respond({ sorted_ids: units?.map((u: any) => u.id) ?? [], merged: [] });
        return;
      }

      const userMessage =
        'Analyse these modules. Sort them pedagogically AND identify any that must be merged.\n\n' +
        'Modules:\n' +
        units.map((u: any, i: number) =>
          `${i + 1}. ID: ${u.id}\n   Bengali: ${u.title_bn}\n   Arabic: ${u.title_ar ?? '—'}`
        ).join('\n\n') +
        '\n\nReturn the strict JSON object as specified. No markdown.';

      const rawText = (await geminiGenerate(Deno.env.get('GEMINI_API_KEY')!, SYSTEM_PROMPT, userMessage)).trim()
        .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

      const parsed = JSON.parse(rawText);
      const sortedIds: string[] = parsed.sorted_ids ?? [];
      const mergeGroups: any[] = parsed.merge_groups ?? [];

      const allKnownIds = new Set(units.map((u: any) => u.id as string));

      // ── Execute merges ────────────────────────────────────────────────────
      const mergedSummary: string[] = [];
      for (const group of mergeGroups) {
        const { keep_id, merge_ids, keep_title_bn, keep_title_ar, reason } = group;
        if (!keep_id || !Array.isArray(merge_ids)) continue;
        if (!allKnownIds.has(keep_id)) continue;

        // Optionally rename the kept unit if a better title was suggested
        if (keep_title_bn || keep_title_ar) {
          const titleUpdate: any = {};
          if (keep_title_bn) titleUpdate.title_bn = keep_title_bn;
          if (keep_title_ar) titleUpdate.title_ar = keep_title_ar;
          await supabase.from('units').update(titleUpdate).eq('id', keep_id);
        }

        // Get current max sort_order in keep unit
        const { data: keepLessons } = await supabase
          .from('lessons').select('sort_order').eq('unit_id', keep_id)
          .order('sort_order', { ascending: false }).limit(1);
        let offset = (keepLessons?.[0]?.sort_order ?? -1) as number;

        for (const mergeId of merge_ids) {
          if (!allKnownIds.has(mergeId)) continue;

          // Fetch lessons to move
          const { data: moveLessons } = await supabase
            .from('lessons').select('id')
            .eq('unit_id', mergeId).order('sort_order');

          if (moveLessons && moveLessons.length > 0) {
            for (const lesson of moveLessons) {
              offset += 1;
              await supabase.from('lessons')
                .update({ unit_id: keep_id, sort_order: offset })
                .eq('id', lesson.id);
            }
          }

          // Delete the now-empty unit
          await supabase.from('units').delete().eq('id', mergeId);
        }

        mergedSummary.push(reason ?? `Merged ${merge_ids.length} duplicate unit(s) into ${keep_id}`);
      }

      // ── Apply sort order (skip deleted IDs) ───────────────────────────────
      const deletedIds = new Set(
        mergeGroups.flatMap((g: any) => (g.merge_ids as string[] | undefined) ?? [])
      );
      const validSorted = sortedIds.filter((id) => allKnownIds.has(id) && !deletedIds.has(id));

      await Promise.all(
        validSorted.map((id, i) =>
          supabase.from('units').update({ sort_order: i }).eq('id', id),
        ),
      );

      await respond({ sorted_ids: validSorted, merged: mergedSummary });
    } catch (e: any) {
      const msg = e instanceof Error ? e.message : String(e);
      try { await respond({ error: msg }); } catch (_) {}
    }
  })();

  return new Response(readable, {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
});
