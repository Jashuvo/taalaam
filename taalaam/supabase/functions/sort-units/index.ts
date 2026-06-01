// supabase/functions/sort-units/index.ts
// Reorders units within a track in optimal pedagogical sequence.
// Deploy: supabase functions deploy sort-units --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const { track_id } = await req.json();
    if (!track_id) throw new Error('track_id is required');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Fetch units — titles only, no extra DB calls
    const { data: units, error: unitErr } = await supabase
      .from('units')
      .select('id, title_bn')
      .eq('track_id', track_id)
      .order('sort_order');

    if (unitErr) throw new Error(unitErr.message);
    if (!units || units.length < 2) {
      return new Response(
        JSON.stringify({ sorted_ids: units?.map((u: any) => u.id) ?? [] }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const prompt = `You are a curriculum designer for Arabic learning for Bengali speakers.
Arrange these units in the optimal pedagogical sequence — foundational first, advanced last.
Principles: alphabet/pronunciation → basic vocabulary → everyday phrases → sentence structure → grammar → advanced topics → Quranic content.

Units:
${units.map((u: any, i: number) => `${i + 1}. ID:${u.id}  Title:${u.title_bn}`).join('\n')}

Reply with ONLY a JSON array of IDs in order. No text, no markdown. Example: ["id1","id2"]`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-3.5-flash' });
    const result = await model.generateContent(prompt);
    const raw = result.response.text().trim()
      .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

    const sortedIds: string[] = JSON.parse(raw);
    const knownIds = new Set(units.map((u: any) => u.id));
    if (!sortedIds.every((id: string) => knownIds.has(id))) {
      throw new Error('Gemini returned unknown unit IDs');
    }

    // Individual updates — do NOT upsert (avoids NOT NULL violations on other columns)
    const updateErrors: string[] = [];
    await Promise.all(
      sortedIds.map(async (id: string, i: number) => {
        const { error } = await supabase
          .from('units')
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
