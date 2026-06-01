// supabase/functions/sort-lessons/index.ts
// Reorders lessons within a unit in optimal pedagogical sequence.
// Deploy: supabase functions deploy sort-lessons --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { unit_id } = await req.json();
    if (!unit_id) {
      return new Response(JSON.stringify({ error: 'unit_id is required' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Fetch lessons — titles + level only, no extra DB calls (avoids timeout)
    const { data: lessons, error: lessonErr } = await supabase
      .from('lessons')
      .select('id, title_bn, level')
      .eq('unit_id', unit_id)
      .order('sort_order');

    if (lessonErr) throw lessonErr;
    if (!lessons || lessons.length < 2) {
      return new Response(JSON.stringify({ sorted_ids: lessons?.map((l) => l.id) ?? [] }), {
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const prompt = `You are a curriculum designer for Arabic learning for Bengali speakers.

Arrange these lessons in the optimal pedagogical sequence — foundational first, advanced last.

Principles (teach earlier = lower number):
1. Alphabet / pronunciation
2. Basic vocabulary
3. Common words and phrases
4. Simple sentences
5. Grammar concepts
6. Advanced grammar

Lessons:
${lessons.map((l, i) => `${i + 1}. ID:${l.id}  Title:${l.title_bn}  Level:${l.level}`).join('\n')}

Reply with ONLY a JSON array of IDs in order. No text, no markdown:`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-3.5-flash' });
    const result = await model.generateContent(prompt);
    const raw = result.response.text().trim()
      .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

    const sortedIds: string[] = JSON.parse(raw);
    const knownIds = new Set(lessons.map((l) => l.id));
    if (!sortedIds.every((id) => knownIds.has(id))) {
      throw new Error('Response contained unknown lesson IDs');
    }

    // Batch upsert instead of N individual updates
    const updates = sortedIds.map((id, i) => ({ id, sort_order: i }));
    const { error: updateErr } = await supabase.from('lessons').upsert(updates, {
      onConflict: 'id',
    });
    if (updateErr) throw updateErr;

    return new Response(JSON.stringify({ sorted_ids: sortedIds }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
