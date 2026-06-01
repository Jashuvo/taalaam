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
    if (!unit_id) throw new Error('unit_id is required');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Fetch lessons — titles + level only
    const { data: lessons, error: lessonErr } = await supabase
      .from('lessons')
      .select('id, title_bn, level')
      .eq('unit_id', unit_id)
      .order('sort_order');

    if (lessonErr) throw new Error(lessonErr.message);
    if (!lessons || lessons.length < 2) {
      return new Response(
        JSON.stringify({ sorted_ids: lessons?.map((l: any) => l.id) ?? [] }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const prompt = `You are a curriculum designer for Arabic learning for Bengali speakers.
Arrange these lessons in the optimal pedagogical sequence — foundational first, advanced last.
Principles: alphabet/pronunciation → basic vocabulary → common phrases → simple sentences → grammar → advanced.

Lessons:
${lessons.map((l: any, i: number) => `${i + 1}. ID:${l.id}  Title:${l.title_bn}  Level:${l.level}`).join('\n')}

Reply with ONLY a JSON array of IDs in order. No text, no markdown. Example: ["id1","id2"]`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-3.5-flash' });
    const result = await model.generateContent(prompt);
    const raw = result.response.text().trim()
      .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

    const sortedIds: string[] = JSON.parse(raw);
    const knownIds = new Set(lessons.map((l: any) => l.id));
    if (!sortedIds.every((id: string) => knownIds.has(id))) {
      throw new Error('Gemini returned unknown lesson IDs');
    }

    // Individual updates — do NOT upsert (avoids NOT NULL violations on other columns)
    const updateErrors: string[] = [];
    await Promise.all(
      sortedIds.map(async (id: string, i: number) => {
        const { error } = await supabase
          .from('lessons')
          .update({ sort_order: i })
          .eq('id', id);
        if (error) updateErrors.push(error.message);
      }),
    );
    if (updateErrors.length > 0) throw new Error(updateErrors.join('; '));

    return new Response(JSON.stringify({ sorted_ids: sortedIds }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
