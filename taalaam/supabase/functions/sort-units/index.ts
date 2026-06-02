// supabase/functions/sort-units/index.ts
// Reorders units within a track in optimal pedagogical sequence.
// Deploy: supabase functions deploy sort-units --no-verify-jwt

import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function callGemini(apiKey: string, prompt: string): Promise<string> {
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
      signal: AbortSignal.timeout(25_000),
    },
  );
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini ${res.status}: ${err}`);
  }
  const data = await res.json();
  return data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
}

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

    const prompt =
      'Arrange these Arabic learning units for Bengali speakers in optimal pedagogical order ' +
      '(foundational first, advanced last). ' +
      'Reply with ONLY a JSON array of IDs. No text. No markdown.\n\n' +
      units.map((u: any, i: number) => `${i + 1}. ID:${u.id} Title:${u.title_bn}`).join('\n');

    const raw = (await callGemini(Deno.env.get('GEMINI_API_KEY')!, prompt))
      .trim()
      .replace(/^```(?:json)?\n?/, '')
      .replace(/\n?```$/, '')
      .trim();

    const sortedIds: string[] = JSON.parse(raw);
    const knownIds = new Set(units.map((u: any) => u.id as string));
    if (!Array.isArray(sortedIds) || !sortedIds.every((id) => knownIds.has(id))) {
      throw new Error('Gemini returned invalid or unknown unit IDs');
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
    const msg = e instanceof Error ? e.message : 'Unknown error';
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
