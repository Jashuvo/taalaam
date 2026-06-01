// supabase/functions/sort-lessons/index.ts
// Analyses lessons in a unit and rewrites their sort_order in pedagogical sequence.
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

    // Fetch all lessons for this unit
    const { data: lessons, error: lessonErr } = await supabase
      .from('lessons')
      .select('id, title_bn, level, sort_order')
      .eq('unit_id', unit_id)
      .order('sort_order');

    if (lessonErr) throw lessonErr;
    if (!lessons || lessons.length === 0) {
      return new Response(JSON.stringify({ error: 'No lessons found for unit' }), {
        status: 400,
        headers: { ...cors, 'Content-Type': 'application/json' },
      });
    }

    // Enrich each lesson with vocab sample + exercise types
    const enriched = await Promise.all(
      lessons.map(async (lesson) => {
        const [{ data: vocab }, { data: exercises }] = await Promise.all([
          supabase
            .from('vocabulary')
            .select('arabic, meaning_bn')
            .eq('lesson_id', lesson.id)
            .limit(5),
          supabase
            .from('exercises')
            .select('type')
            .eq('lesson_id', lesson.id),
        ]);

        const vocabStr = vocab?.map((v) => `${v.arabic} (${v.meaning_bn})`).join(', ') || '—';
        const types = [...new Set(exercises?.map((e) => e.type) ?? [])].join(', ') || '—';

        return { id: lesson.id, title: lesson.title_bn, level: lesson.level, vocab: vocabStr, types };
      }),
    );

    const lessonList = enriched
      .map(
        (l, i) =>
          `${i + 1}. ID: ${l.id}\n   শিরোনাম: ${l.title}\n   স্তর: ${l.level}\n   শব্দভাণ্ডার: ${l.vocab}\n   ধরন: ${l.types}`,
      )
      .join('\n\n');

    const prompt = `You are a curriculum designer for Arabic language learning for Bengali speakers.

Arrange the lessons below in the optimal pedagogical sequence — foundational first, advanced last.

Ordering principles (earlier number = teach first):
1. Alphabet and individual letter recognition
2. Harakat / short vowels (fatha, kasra, damma, sukoon)
3. Letter joining and basic syllables
4. Common words, greetings, everyday vocabulary
5. Basic sentence structures and simple phrases
6. Numbers, colours, family terms
7. Grammar concepts (gender, plural, verb forms)
8. Quranic / religious vocabulary and phrases
9. Advanced grammar and complex sentences

Lessons to sort:
${lessonList}

Return ONLY a JSON array of lesson IDs in the correct learning order.
No explanation. No markdown. Just the raw array, for example: ["id1","id2","id3"]`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    const result = await model.generateContent(prompt);
    const raw = result.response.text().trim();

    // Strip markdown fences if Gemini adds them
    const jsonStr = raw.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
    const sortedIds: string[] = JSON.parse(jsonStr);

    // Validate — every returned ID must belong to this unit
    const knownIds = new Set(lessons.map((l) => l.id));
    if (!sortedIds.every((id) => knownIds.has(id))) {
      throw new Error('Response contained unknown lesson IDs');
    }

    // Write new sort_order values back
    await Promise.all(
      sortedIds.map((id, i) =>
        supabase.from('lessons').update({ sort_order: i }).eq('id', id),
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
