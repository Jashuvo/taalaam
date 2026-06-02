// supabase/functions/sort-lessons/index.ts
// Reorders lessons within a unit in optimal pedagogical sequence.
// Deploy: supabase functions deploy sort-lessons --no-verify-jwt

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

    const { data: lessons, error: lessonErr } = await supabase
      .from('lessons')
      .select('id, title_bn, level')
      .eq('unit_id', unit_id)
      .order('sort_order');

    if (lessonErr) throw new Error(lessonErr.message);
    if (!lessons || lessons.length < 2) {
      return new Response(
        JSON.stringify({ sorted_ids: lessons?.map((l: any) => l.id) ?? [], note: 'nothing to sort' }),
        { headers: { ...cors, 'Content-Type': 'application/json' } },
      );
    }

    const apiKey = Deno.env.get('GEMINI_API_KEY');
    if (!apiKey) throw new Error('GEMINI_API_KEY secret not set');

    const prompt =
      'Arrange these Arabic learning lessons for Bengali speakers in optimal pedagogical order ' +
      '(foundational first). Reply with ONLY a JSON array of IDs. No text. No markdown.\n\n' +
      lessons.map((l: any, i: number) =>
        `${i + 1}. ID:${l.id} Title:${l.title_bn} Level:${l.level}`
      ).join('\n');

    let geminiRes: Response;
    try {
      const fetchPromise = fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }),
        },
      );
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('Gemini API timed out after 20s')), 20_000),
      );
      geminiRes = await Promise.race([fetchPromise, timeoutPromise]) as Response;
    } catch (geminiErr: any) {
      throw new Error(`Gemini fetch failed: ${geminiErr?.message ?? String(geminiErr)}`);
    }

    if (!geminiRes.ok) {
      const errText = await geminiRes.text().catch(() => 'unknown');
      throw new Error(`Gemini HTTP ${geminiRes.status}: ${errText}`);
    }

    const geminiData = await geminiRes.json().catch(() => null);
    const rawText: string = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    const jsonStr = rawText.trim()
      .replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

    if (!jsonStr) throw new Error('Gemini returned empty response');

    const sortedIds: string[] = JSON.parse(jsonStr);
    const knownIds = new Set(lessons.map((l: any) => l.id as string));
    if (!Array.isArray(sortedIds) || !sortedIds.every((id) => knownIds.has(id))) {
      throw new Error(`Gemini returned invalid IDs: ${jsonStr.slice(0, 200)}`);
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
    console.error('[sort-lessons error]', msg);
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  }
});
