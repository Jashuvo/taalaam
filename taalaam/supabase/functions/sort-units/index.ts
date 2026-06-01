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
    if (!track_id) {
      return new Response(JSON.stringify({ error: 'track_id is required' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Fetch units — titles only, no per-unit DB calls (avoids timeout)
    const { data: units, error: unitErr } = await supabase
      .from('units')
      .select('id, title_bn, title_ar')
      .eq('track_id', track_id)
      .order('sort_order');

    if (unitErr) throw unitErr;
    if (!units || units.length < 2) {
      // Nothing to sort
      return new Response(JSON.stringify({ sorted_ids: units?.map((u) => u.id) ?? [] }), {
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    const prompt = `You are a curriculum designer for Arabic learning for Bengali speakers.

Arrange these units in the optimal pedagogical sequence — foundational first, advanced last.

Principles (teach earlier = lower number):
1. Alphabet / letters / pronunciation
2. Basic vocabulary (greetings, numbers, family)
3. Everyday words and simple phrases
4. Sentence structure basics
5. Grammar concepts
6. Topic vocabulary (weather, jobs, places)
7. Quranic / religious phrases
8. Advanced grammar

Units:
${units.map((u, i) => `${i + 1}. ID:${u.id}  Title:${u.title_bn}`).join('\n')}

Reply with ONLY a JSON array of IDs in order. No text, no markdown:`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-3.5-flash' });
    const result = await model.generateContent(prompt);
    const raw = result.response.text().trim()
      .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

    const sortedIds: string[] = JSON.parse(raw);
    const knownIds = new Set(units.map((u) => u.id));
    if (!sortedIds.every((id) => knownIds.has(id))) {
      throw new Error('Response contained unknown unit IDs');
    }

    // Update all sort_orders in one batch using upsert
    const updates = sortedIds.map((id, i) => ({ id, sort_order: i }));
    const { error: updateErr } = await supabase.from('units').upsert(updates, {
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
