// supabase/functions/sort-units/index.ts
// Analyses units in a track and rewrites their sort_order in pedagogical sequence.
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

    // Fetch units for this track
    const { data: units, error: unitErr } = await supabase
      .from('units')
      .select('id, title_bn, title_ar, sort_order')
      .eq('track_id', track_id)
      .order('sort_order');

    if (unitErr) throw unitErr;
    if (!units || units.length === 0) {
      return new Response(JSON.stringify({ error: 'No units found for track' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    // Enrich each unit with lesson count + first few lesson titles
    const enriched = await Promise.all(
      units.map(async (unit) => {
        const { data: lessons } = await supabase
          .from('lessons')
          .select('title_bn, level')
          .eq('unit_id', unit.id)
          .order('sort_order')
          .limit(4);

        return {
          id: unit.id,
          title: unit.title_bn,
          titleAr: unit.title_ar ?? '',
          lessons: lessons?.map((l) => `${l.title_bn} (${l.level})`).join(', ') || '—',
        };
      }),
    );

    const prompt = `You are a curriculum designer for Arabic language learning for Bengali speakers.

Arrange these learning units in the optimal pedagogical sequence — foundational first, advanced last.

Ordering principles:
1. Alphabet, letters, pronunciation
2. Basic vocabulary (greetings, numbers, colours, family)
3. Common everyday words and phrases
4. Simple sentence structures
5. Grammar concepts
6. Topic-based vocabulary (weather, professions, places)
7. Quranic / religious content
8. Advanced grammar and complex sentences

Units to sort:
${enriched.map((u, i) => `${i + 1}. ID: ${u.id}\n   Title: ${u.title}\n   Sample lessons: ${u.lessons}`).join('\n\n')}

Return ONLY a JSON array of unit IDs in the correct learning order. No explanation, no markdown:`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    const result = await model.generateContent(prompt);
    const raw = result.response.text().trim();
    const jsonStr = raw.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
    const sortedIds: string[] = JSON.parse(jsonStr);

    const knownIds = new Set(units.map((u) => u.id));
    if (!sortedIds.every((id) => knownIds.has(id))) {
      throw new Error('Response contained unknown unit IDs');
    }

    await Promise.all(
      sortedIds.map((id, i) =>
        supabase.from('units').update({ sort_order: i }).eq('id', id),
      ),
    );

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
