// curate-quran-lesson/index.ts
// Generates a Quranic lesson from any surah using quran_words + Gemini.
// Admin-only. Body: { surah_number: number }
// Deploy: supabase functions deploy curate-quran-lesson --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ADMIN_EMAIL = 'jubayedsr@gmail.com';

async function checkAdmin(req: Request): Promise<Response | null> {
  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  const email = (() => {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return null;
      const pad = (s: string) => s + '='.repeat((4 - s.length % 4) % 4);
      const p = JSON.parse(atob(pad(parts[1].replace(/-/g, '+').replace(/_/g, '/'))));
      return typeof p.sub === 'string' && p.exp > Date.now() / 1000 ? (p.email as string ?? null) : null;
    } catch { return null; }
  })();
  if (email !== ADMIN_EMAIL) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  return null;
}

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'];

async function geminiGenerate(apiKey: string, prompt: string): Promise<string> {
  const genAI = new GoogleGenerativeAI(apiKey);
  let lastErr: unknown;
  for (const modelName of GEMINI_MODELS) {
    try {
      const m = genAI.getGenerativeModel({ model: modelName });
      const result = await m.generateContent(prompt);
      return result.response.text();
    } catch (err) { lastErr = err; }
  }
  throw new Error(`All Gemini models failed: ${lastErr instanceof Error ? lastErr.message : String(lastErr)}`);
}

function stripFences(s: string): string {
  return s.trim().replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const denied = await checkAdmin(req);
  if (denied) return denied;

  try {
    const body = await req.json();
    const surahNumber = body?.surah_number;
    if (!surahNumber || typeof surahNumber !== 'number') {
      return new Response(JSON.stringify({ error: 'surah_number (integer) is required' }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;

    // 1. Fetch surah metadata
    const { data: surahRow, error: surahErr } = await supabase
      .from('quran_surahs')
      .select('number, name_bn, name_ar, name_en, ayah_count')
      .eq('number', surahNumber)
      .single();
    if (surahErr || !surahRow) {
      return new Response(JSON.stringify({ error: `Surah ${surahNumber} not found in quran_surahs` }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 2. Fetch all words for this surah that have meanings
    const { data: wordRows } = await supabase
      .from('quran_words')
      .select('arabic, meaning_bn, surah, ayah, position')
      .eq('surah', surahNumber)
      .not('meaning_bn', 'is', null)
      .order('ayah')
      .order('position');

    if (!wordRows || wordRows.length === 0) {
      return new Response(JSON.stringify({ error: `No word meanings found for surah ${surahNumber}` }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 3. Deduplicate by arabic — keep first occurrence
    const seen = new Set<string>();
    const uniqueWords: { arabic: string; meaning_bn: string; ayah: number; position: number }[] = [];
    for (const w of wordRows) {
      if (!seen.has(w.arabic)) {
        seen.add(w.arabic);
        uniqueWords.push({ arabic: w.arabic, meaning_bn: w.meaning_bn, ayah: w.ayah, position: w.position });
      }
    }

    // 4. Build context: full ayah text + tafsir snippet for each word's first ayah
    const ayahKeys = [...new Set(uniqueWords.map(w => `${surahNumber}:${w.ayah}`))];
    const ayahTexts = new Map<string, string>();
    const tafsirSnippets = new Map<string, string>();

    await Promise.all(ayahKeys.slice(0, 8).map(async (key) => {
      const [s, a] = key.split(':').map(Number);
      const [{ data: ayahWords }, { data: tafsir }] = await Promise.all([
        supabase.from('quran_words').select('arabic').eq('surah', s).eq('ayah', a).order('position'),
        supabase.from('quran_tafsir').select('tafsir_text').eq('surah', s).eq('ayah', a).single(),
      ]);
      if (ayahWords) ayahTexts.set(key, (ayahWords as { arabic: string }[]).map(w => w.arabic).join(' '));
      if (tafsir?.tafsir_text) tafsirSnippets.set(key, (tafsir.tafsir_text as string).slice(0, 120) + '…');
    }));

    // 5. Ensure quranic track exists
    const { data: trackRow } = await supabase
      .from('tracks').select('id').eq('slug', 'quranic').single();
    if (!trackRow) {
      return new Response(JSON.stringify({ error: "Quranic track not found. Run seed_quran_track.ts first to create it." }), {
        status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // 6. Find or create 'juz-amma' unit in quranic track
    let { data: unitRow } = await supabase
      .from('units').select('id').eq('slug', 'juz-amma').eq('track_id', trackRow.id).single();
    if (!unitRow) {
      const { data: newUnit, error: uErr } = await supabase.from('units').insert({
        track_id: trackRow.id,
        slug: 'juz-amma',
        title_bn: 'জুয আম্মার সূরা',
        title_ar: 'سُوَرُ جُزْءِ عَمَّ',
        sort_order: 10,
        tier_level: 1,
        status: 'draft',
      }).select('id').single();
      if (uErr) throw uErr;
      unitRow = newUnit;
    }

    // 7. Upsert lesson for this surah
    const lessonTitleBn = `সূরা ${surahRow.name_bn}`;
    let lessonId: string;
    const { data: existingLesson } = await supabase
      .from('lessons').select('id').eq('unit_id', unitRow!.id).eq('title_bn', lessonTitleBn).single();

    if (existingLesson) {
      lessonId = existingLesson.id;
      await Promise.all([
        supabase.from('exercises').delete().eq('lesson_id', lessonId),
        supabase.from('vocabulary').delete().eq('lesson_id', lessonId),
      ]);
    } else {
      const { data: newLesson, error: lErr } = await supabase.from('lessons').insert({
        unit_id: unitRow!.id,
        title_bn: lessonTitleBn,
        sort_order: surahNumber,
        level: 'beginner',
        status: 'draft',
      }).select('id').single();
      if (lErr) throw lErr;
      lessonId = newLesson!.id;
    }

    // 8. Gemini: enrich words with transliteration, English meaning, grammar note
    type EnrichedWord = typeof uniqueWords[0] & {
      transliteration: string | null;
      meaning_en: string | null;
      grammar_note_bn: string | null;
    };
    let enrichedWords: EnrichedWord[] = uniqueWords.map(w => ({
      ...w, transliteration: null, meaning_en: null, grammar_note_bn: null,
    }));
    try {
      const wordList = uniqueWords.map((w, i) => `${i + 1}. ${w.arabic} = ${w.meaning_bn}`).join('\n');
      const enrichPrompt = `For each Arabic Quranic word below, provide:
- transliteration: phonetic Latin transcription
- meaning_en: English meaning (1–3 words)
- grammar_note_bn: one-line Bangla grammar note (word type, form, root)

Return a JSON array where each item has: {"arabic":"...","transliteration":"...","meaning_en":"...","grammar_note_bn":"..."}.
Only return valid JSON. No markdown.

Words:
${wordList}`;
      const enriched = JSON.parse(stripFences(await geminiGenerate(geminiKey, enrichPrompt))) as Array<{
        arabic: string; transliteration: string; meaning_en: string; grammar_note_bn: string;
      }>;
      const enrichMap = new Map(enriched.map(e => [e.arabic, e]));
      enrichedWords = uniqueWords.map(w => {
        const e = enrichMap.get(w.arabic);
        return { ...w, transliteration: e?.transliteration ?? null, meaning_en: e?.meaning_en ?? null, grammar_note_bn: e?.grammar_note_bn ?? null };
      });
    } catch (e) {
      console.warn('Enrichment failed, proceeding without:', (e as Error).message);
    }

    // 9. Insert vocabulary
    const vocabRows = enrichedWords.map((w) => {
      const key = `${surahNumber}:${w.ayah}`;
      return {
        lesson_id: lessonId,
        arabic: w.arabic,
        meaning_bn: w.meaning_bn,
        meaning_en: w.meaning_en,
        transliteration: w.transliteration,
        grammar_note_bn: w.grammar_note_bn,
        word_type: 'noun',
        context_snippet_ar: ayahTexts.get(key) ?? null,
        context_snippet_bn: tafsirSnippets.get(key) ?? null,
      };
    });
    if (vocabRows.length > 0) {
      const { error: vErr } = await supabase.from('vocabulary').insert(vocabRows);
      if (vErr) throw new Error(`Vocabulary insert failed: ${vErr.message}`);
    }

    // 10. Gemini: generate 8 exercises
    let exerciseCount = 0;
    try {
      const wordPairs = enrichedWords.slice(0, 20).map(w => `${w.arabic}=${w.meaning_bn}`).join(', ');
      const exPrompt = `You are making Quranic Arabic exercises for Bengali-speaking Muslims learning সূরা ${surahRow.name_bn} (Surah ${surahNumber}).

Available words (arabic=Bengali meaning): ${wordPairs}

Generate exactly 8 exercises as a JSON array. Include these types:
- 3 multipleChoice: {"type":"multipleChoice","sort_order":N,"prompt_bn":"«WORD» শব্দের অর্থ কী?","prompt_ar":"WORD","correct_answer":{"options":["correct","wrong1","wrong2","wrong3"],"correct_index":0},"grammar_note_bn":"...","difficulty":1}
- 2 dragDrop: {"type":"dragDrop","sort_order":N,"prompt_bn":"আরবি শব্দের সাথে বাংলা অর্থ মেলাও:","correct_answer":{"pairs":[{"ar":"word","bn":"meaning"},{"ar":"word2","bn":"meaning2"}]},"grammar_note_bn":"...","difficulty":2}
- 1 tapToBuild: {"type":"tapToBuild","sort_order":N,"prompt_bn":"এই আয়াতের শব্দগুলো সাজাও:","correct_answer":{"words":["word1","word2","word3"],"order_matters":true,"distractor_words":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":4}
- 1 fillInBlank: {"type":"fillInBlank","sort_order":N,"prompt_bn":"শূন্যস্থান পূরণ করো:","correct_answer":{"sentence":"Arabic sentence with ___","blank_index":0,"answer":"word"},"distractors":{"options":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":3}
- 1 speakArabic: {"type":"speakArabic","sort_order":N,"prompt_bn":"এই আরবি শব্দটি বলুন:","correct_answer":{"expected_ar":"word with harakat","transliteration":"...","meaning_bn":"..."},"grammar_note_bn":"...","difficulty":2}

RULES: ONLY use words from the provided list. Full harakat (تشكيل) on all Arabic text. Return JSON array only, no markdown.`;

      const exercises = JSON.parse(stripFences(await geminiGenerate(geminiKey, exPrompt))) as Array<Record<string, unknown>>;
      const { data: inserted } = await supabase.from('exercises').insert(
        exercises.map((ex, idx) => ({
          lesson_id: lessonId,
          type: ex.type,
          sort_order: (ex.sort_order as number) ?? (idx + 1),
          prompt_bn: ex.prompt_bn,
          prompt_ar: (ex.prompt_ar as string | undefined) ?? null,
          correct_answer: ex.correct_answer,
          distractors: (ex.distractors as unknown) ?? null,
          grammar_note_bn: (ex.grammar_note_bn as string | undefined) ?? null,
          difficulty: (ex.difficulty as number) ?? 1,
        }))
      ).select('id');
      exerciseCount = inserted?.length ?? 0;
    } catch (e) {
      console.warn('Exercise generation failed:', (e as Error).message);
    }

    return new Response(
      JSON.stringify({
        success: true,
        lesson_id: lessonId,
        surah: surahRow.name_bn,
        vocab_count: vocabRows.length,
        exercise_count: exerciseCount,
      }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('curate-quran-lesson error:', message);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  }
});
