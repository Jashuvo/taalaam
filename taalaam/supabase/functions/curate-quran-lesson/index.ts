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

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-2.0-flash-lite'];

async function geminiGenerate(apiKey: string, prompt: string): Promise<string> {
  const genAI = new GoogleGenerativeAI(apiKey);
  let lastErr: unknown;
  for (const modelName of GEMINI_MODELS) {
    for (let attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) await new Promise(r => setTimeout(r, 4000));
      try {
        const m = genAI.getGenerativeModel({ model: modelName });
        const result = await m.generateContent(prompt);
        return result.response.text();
      } catch (err) { lastErr = err; }
    }
  }
  throw new Error(`All Gemini models failed: ${lastErr instanceof Error ? lastErr.message : String(lastErr)}`);
}

function stripFences(s: string): string {
  return s.trim().replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
}

function extractJsonArray(s: string): string {
  const stripped = stripFences(s);
  // Gemini sometimes adds preamble text before the JSON — find the first [ to last ]
  const start = stripped.indexOf('[');
  const end = stripped.lastIndexOf(']');
  if (start === -1 || end === -1 || end < start) {
    throw new Error(`No JSON array found in Gemini response. Got: ${stripped.slice(0, 300)}`);
  }
  return stripped.slice(start, end + 1);
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

    // 10. Gemini: generate exercises — brief pause so enrichment quota clears
    await new Promise(r => setTimeout(r, 6000));
    let exerciseCount = 0;
    let exerciseError: string | null = null;
    const exWords = enrichedWords.slice(0, 15);
    if (exWords.length >= 2) {
      try {
        const wordList = exWords.map((w, i) =>
          `${i + 1}. ${w.arabic} (${w.transliteration ?? '?'}) = ${w.meaning_bn}`
        ).join('\n');

        const exSystemPrompt = `You are a Quranic Arabic curriculum designer for Bengali-speaking Muslims.
Create gamified micro-exercises teaching words from সূরা ${surahRow.name_bn}.

EXERCISE TYPE SCHEMAS (use exact field names):

[multiple_choice] — Arabic word shown, learner picks Bengali meaning
  {"type":"multiple_choice","sort_order":N,"prompt_bn":"«WORD» শব্দের অর্থ কী?","prompt_ar":"WORD","correct_answer":{"options":["correct","wrong1","wrong2","wrong3"],"correct_index":0},"grammar_note_bn":"...","difficulty":1}
  Rules: exactly 4 options, correct_index 0–3, distractors from lesson words only.

[drag_drop] — match 3–4 Arabic words to Bengali meanings
  {"type":"drag_drop","sort_order":N,"prompt_bn":"আরবি শব্দের সাথে বাংলা অর্থ মেলাও:","correct_answer":{"pairs":[{"ar":"WORD","bn":"meaning"},{"ar":"WORD2","bn":"meaning2"},{"ar":"WORD3","bn":"meaning3"}]},"grammar_note_bn":"...","difficulty":2}
  Rules: 3–4 pairs only, use words from lesson word list.

[true_false] — is this translation correct?
  {"type":"true_false","sort_order":N,"prompt_bn":"অনুবাদটি কি সঠিক?","correct_answer":{"statement_ar":"ARABIC","statement_bn":"Bengali translation","is_true":true},"grammar_note_bn":"...","difficulty":2}
  Rules: half true half false, false = swap one word with a wrong word from lesson.

[fill_in_blank] — one missing word in short Arabic phrase
  {"type":"fill_in_blank","sort_order":N,"prompt_bn":"শূন্যস্থানে সঠিক শব্দ বসাও (অর্থ: HINT):","correct_answer":{"sentence":"ARABIC ___ REST","blank_index":N,"answer":"WORD"},"distractors":{"options":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":3}
  Rules: sentence uses 2–4 words from lesson, blank_index is 0-based position, distractors from lesson words.

[tap_to_build] — tap tiles to assemble an Arabic phrase
  {"type":"tap_to_build","sort_order":N,"prompt_bn":"সঠিক ক্রমে সাজাও: «Bengali meaning»","correct_answer":{"words":["WORD1","WORD2","WORD3"],"order_matters":true,"distractor_words":["WRONG1","WRONG2"]},"distractors":null,"grammar_note_bn":"...","difficulty":4}
  Rules: words = individual Arabic words (one per element), 2–4 words, distractor_words from lesson only.

[speak_arabic] — learner pronounces a word aloud
  {"type":"speak_arabic","sort_order":N,"prompt_bn":"এই আরবি শব্দটি বলুন:","correct_answer":{"expected_ar":"WORD_WITH_HARAKAT","transliteration":"latin","meaning_bn":"Bengali"},"grammar_note_bn":"...","difficulty":2}
  Rules: one per lesson, most important word.

ABSOLUTE RULES:
- ALL Arabic must have full harakat (تشكيل) — never bare Arabic
- ONLY use words from the provided lesson word list for answers, distractors, and pairs
- grammar_note_bn: one line explaining the Arabic grammar point (not just the meaning)
- sort_order: sequential integers starting at 1
- Return ONLY a valid JSON array — no markdown, no explanation, no code fences`;

        const exUserPrompt = `Lesson word list (arabic · transliteration = Bengali):
${wordList}

Generate: 3×multiple_choice, 2×drag_drop, 1×true_false, 1×fill_in_blank, 1×tap_to_build, 1×speak_arabic
= 9 exercises total (sort_order 1–9).
Return valid JSON array only.`;

        const rawEx = extractJsonArray(await geminiGenerate(geminiKey, `${exSystemPrompt}\n\n${exUserPrompt}`));
        const exercises = JSON.parse(rawEx) as Array<Record<string, unknown>>;

        if (!Array.isArray(exercises) || exercises.length === 0) {
          throw new Error('Gemini returned empty or non-array exercise response');
        }

        const { data: inserted, error: exErr } = await supabase.from('exercises').insert(
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
        if (exErr) throw new Error(`Exercise insert failed: ${exErr.message}`);
        exerciseCount = inserted?.length ?? 0;
      } catch (e) {
        exerciseError = (e as Error).message;
        console.error('Exercise generation failed:', exerciseError);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        lesson_id: lessonId,
        surah: surahRow.name_bn,
        vocab_count: vocabRows.length,
        exercise_count: exerciseCount,
        ...(exerciseError ? { exercise_error: exerciseError } : {}),
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
