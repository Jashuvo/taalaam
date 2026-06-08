// curate-quran-lesson/index.ts
// Generates Quranic lessons for all 5 curriculum units.
// Admin-only. Body: { unit_type, surah_number?, lesson_index? }
//
// unit_type:
//   'salah'      — Language of Salah (surahs 1,112,108,103) — requires surah_number
//   'juz_amma'   — Juz Amma surahs (78–114)                 — requires surah_number
//   'frequent'   — Top-100 most frequent words (5 lessons)   — requires lesson_index 0–4
//   'attributes' — Names of Allah from 4 Quranic passages    — requires lesson_index 0–3
//   'verbs'      — Verb roots (5 lessons, needs root data)    — requires lesson_index 0–4
//
// Deploy: supabase functions deploy curate-quran-lesson --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient }        from 'npm:@supabase/supabase-js';

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ADMIN_EMAIL  = 'jubayedsr@gmail.com';
const GEMINI_MODELS = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite', 'gemini-2.5-flash'];

// ── Types ────────────────────────────────────────────────────────────────────

type UnitType = 'salah' | 'juz_amma' | 'frequent' | 'attributes' | 'verbs';

interface WordRow { arabic: string; meaning_bn: string; ayah?: number; position?: number; surah?: number; }

// ── Unit config ──────────────────────────────────────────────────────────────

const UNIT_CONFIG: Record<UnitType, { slug: string; title_bn: string; title_ar: string; sort_order: number }> = {
  salah:      { slug: 'salah-vocabulary', title_bn: 'সালাতের ভাষা',           title_ar: 'لُغَةُ الصَّلَاة',               sort_order: 1 },
  frequent:   { slug: 'frequent-words',  title_bn: 'সবচেয়ে বেশি ব্যবহৃত শব্দ', title_ar: 'الكَلِمَاتُ الأَكْثَرُ تَكْرَارًا', sort_order: 2 },
  attributes: { slug: 'asma-sifat',      title_bn: 'আল্লাহর গুণাবলী',          title_ar: 'أَسْمَاءُ اللهِ الحُسْنَى',       sort_order: 3 },
  juz_amma:   { slug: 'juz-amma',        title_bn: 'জুয আম্মার সূরা',          title_ar: 'سُوَرُ جُزْءِ عَمَّ',             sort_order: 4 },
  verbs:      { slug: 'quranic-verbs',   title_bn: 'কুরআনের ক্রিয়াপদ',        title_ar: 'الأَفْعَالُ القُرْآنِيَّة',       sort_order: 5 },
};

// 8 Quranic passages with the densest clusters of Allah's Names.
// Ordered by pedagogical priority per Ibn Uthaymin's al-Qawa'id al-Muthla.
// Lessons 0–3: the four richest passages (every learner should complete these)
// Lessons 4–7: extending coverage to ~30 of the most important Names
const ATTRIBUTE_PASSAGES = [
  { titleBn: 'আল-ফাতিহার নামসমূহ',           surah: 1,   ayahFrom: 1,   ayahTo: 7   }, // الله، الرحمن، الرحيم، رب، مالك
  { titleBn: 'আয়াতুল কুরসির নামসমূহ',        surah: 2,   ayahFrom: 255, ayahTo: 255 }, // الحي، القيوم، العلي، العظيم
  { titleBn: 'আল-ইখলাসের নামসমূহ',            surah: 112, ayahFrom: 1,   ayahTo: 4   }, // الأحد، الصمد
  { titleBn: 'আল-হাশর ২২–২৪ এর নামসমূহ',     surah: 59,  ayahFrom: 22,  ayahTo: 24  }, // 14 Names in 3 consecutive ayahs
  { titleBn: 'আল-হাদিদ ১–৬ এর নামসমূহ',      surah: 57,  ayahFrom: 1,   ayahTo: 6   }, // الأول، الآخر، الظاهر، الباطن، القدير
  { titleBn: 'আল-আনআম ১০২–১০৩ এর নামসমূহ',  surah: 6,   ayahFrom: 102, ayahTo: 103 }, // اللطيف، الخبير، الوكيل
  { titleBn: 'আশ-শূরা ১১–১৩ এর নামসমূহ',     surah: 42,  ayahFrom: 11,  ayahTo: 13  }, // السميع، البصير
  { titleBn: 'আল-বাকারা ২৮৪–২৮৬ এর নামসমূহ', surah: 2,   ayahFrom: 284, ayahTo: 286 }, // القدير، الغفور، الرحيم in du'a context
];

// ── Auth + Gemini helpers ────────────────────────────────────────────────────

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
  const start = stripped.indexOf('[');
  const end   = stripped.lastIndexOf(']');
  if (start === -1 || end <= start) throw new Error(`No JSON array in response: ${stripped.slice(0, 300)}`);
  return stripped.slice(start, end + 1);
}

// ── Word fetching per unit type ──────────────────────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseClient = ReturnType<typeof createClient>;

function dedupeWords(rows: WordRow[]): WordRow[] {
  const seen = new Set<string>();
  return rows.filter(w => { if (seen.has(w.arabic)) return false; seen.add(w.arabic); return true; });
}

async function fetchSurahWords(sb: SupabaseClient, surahNumber: number): Promise<WordRow[]> {
  const { data } = await sb
    .from('quran_words')
    .select('arabic, meaning_bn, surah, ayah, position')
    .eq('surah', surahNumber)
    .not('meaning_bn', 'is', null)
    .order('ayah').order('position');
  return dedupeWords((data ?? []) as WordRow[]);
}

async function fetchFrequentWords(sb: SupabaseClient, lessonIndex: number): Promise<WordRow[]> {
  const { data, error } = await sb.rpc('get_top_quran_words', {
    limit_count: 20,
    offset_count: lessonIndex * 20,
  });
  if (error) throw new Error(`get_top_quran_words: ${error.message}`);
  return (data ?? []) as WordRow[];
}

async function fetchAttributeWords(
  sb: SupabaseClient,
  geminiKey: string,
  passage: { surah: number; ayahFrom: number; ayahTo: number },
): Promise<WordRow[]> {
  const { data } = await sb
    .from('quran_words')
    .select('arabic, meaning_bn')
    .eq('surah', passage.surah)
    .gte('ayah', passage.ayahFrom)
    .lte('ayah', passage.ayahTo)
    .not('meaning_bn', 'is', null);
  if (!data?.length) return [];

  const uniqueWords = dedupeWords(data as WordRow[]);
  const wordList = uniqueWords.map((w, i) => `${i + 1}. ${w.arabic} = ${w.meaning_bn}`).join('\n');

  // Ask Gemini to filter to only divine Names/Attributes — not particles, pronouns, or common verbs
  const prompt = `From this list of Arabic words taken from the Quran, identify ONLY the Names and Attributes of Allah (أسماء الله الحسنى وصفاته).

Include: divine Names (الرحمن، العليم، القدير…) and Attributes (الحي، القيوم، الملك…)
Exclude: particles (إنَّ، عَلَى، الَّذِي…), pronouns (هُوَ، لَهُ…), common verbs, and non-divine nouns.

Return ONLY a JSON array of 1-based item numbers: [1, 3, 7, ...]
No other text.

Words:
${wordList}`;

  const raw = await geminiGenerate(geminiKey, prompt);
  const indices = JSON.parse(extractJsonArray(raw)) as number[];
  return indices
    .filter(i => i >= 1 && i <= uniqueWords.length)
    .map(i => uniqueWords[i - 1]);
}

async function fetchVerbRoots(sb: SupabaseClient, lessonIndex: number): Promise<{ root: string; forms: string[] }[]> {
  const { data, error } = await sb.rpc('get_quran_verb_roots', {
    limit_count: 5,
    offset_count: lessonIndex * 5,
  });
  if (error) throw new Error(`get_quran_verb_roots: ${error.message}`);
  if (!data?.length) throw new Error('No verb roots found — run enrich_quran_roots.ts first.');
  return data as { root: string; forms: string[] }[];
}

// Flatten verb root families into word rows (for enrichment + exercises)
async function verbRootsToWords(sb: SupabaseClient, roots: { root: string; forms: string[] }[]): Promise<WordRow[]> {
  const words: WordRow[] = [];
  for (const r of roots) {
    for (const form of r.forms.slice(0, 4)) {
      const { data } = await sb.from('quran_words')
        .select('arabic, meaning_bn')
        .eq('arabic', form)
        .not('meaning_bn', 'is', null)
        .limit(1);
      if (data?.[0]) words.push({ arabic: form, meaning_bn: (data[0] as WordRow).meaning_bn });
    }
  }
  return words;
}

// ── Lesson title helpers ─────────────────────────────────────────────────────

function getLessonTitle(unitType: UnitType, surahNameBn: string, lessonIndex: number): string {
  switch (unitType) {
    case 'salah':
    case 'juz_amma':   return `সূরা ${surahNameBn}`;
    case 'frequent':   return `শীর্ষ শব্দ — পাঠ ${lessonIndex + 1} (${lessonIndex * 20 + 1}–${lessonIndex * 20 + 20})`;
    case 'attributes': return ATTRIBUTE_PASSAGES[lessonIndex]?.titleBn ?? `গুণাবলী পাঠ ${lessonIndex + 1}`;
    case 'verbs':      return `ক্রিয়াপদ পাঠ ${lessonIndex + 1}`;
  }
}

// ── Exercise prompts ─────────────────────────────────────────────────────────

const EXERCISE_SYSTEM_PROMPT = `You are a Quranic Arabic curriculum designer for Bengali-speaking Muslims.

EXERCISE TYPE SCHEMAS (use exact field names and snake_case type values):

[multiple_choice] — Arabic word shown, learner picks Bengali meaning
  {"type":"multiple_choice","sort_order":N,"prompt_bn":"«WORD» শব্দের অর্থ কী?","prompt_ar":"WORD","correct_answer":{"options":["correct","wrong1","wrong2","wrong3"],"correct_index":0},"grammar_note_bn":"...","difficulty":1}
  Rules: exactly 4 options, correct_index 0–3, distractors from lesson words only.

[drag_drop] — match 3–4 Arabic words to Bengali meanings
  {"type":"drag_drop","sort_order":N,"prompt_bn":"আরবি শব্দের সাথে বাংলা অর্থ মেলাও:","correct_answer":{"pairs":[{"ar":"WORD","bn":"meaning"},{"ar":"WORD2","bn":"meaning2"},{"ar":"WORD3","bn":"meaning3"}]},"grammar_note_bn":"...","difficulty":2}
  Rules: 3–4 pairs only.

[true_false] — is this translation correct?
  {"type":"true_false","sort_order":N,"prompt_bn":"অনুবাদটি কি সঠিক?","correct_answer":{"statement_ar":"ARABIC","statement_bn":"Bengali translation","is_true":true},"grammar_note_bn":"...","difficulty":2}
  Rules: false = swap one word with a wrong word from the lesson.

[fill_in_blank] — one missing word in short Arabic phrase
  {"type":"fill_in_blank","sort_order":N,"prompt_bn":"শূন্যস্থানে সঠিক শব্দ বসাও (অর্থ: HINT):","correct_answer":{"sentence":"ARABIC ___ REST","blank_index":N,"answer":"WORD"},"distractors":{"options":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":3}
  Rules: blank_index is 0-based position, distractors from lesson words.

[tap_to_build] — tap tiles to assemble an Arabic phrase
  {"type":"tap_to_build","sort_order":N,"prompt_bn":"সঠিক ক্রমে সাজাও: «Bengali meaning»","correct_answer":{"words":["WORD1","WORD2","WORD3"],"order_matters":true,"distractor_words":["WRONG1","WRONG2"]},"distractors":null,"grammar_note_bn":"...","difficulty":4}
  Rules: 2–4 words, distractor_words from lesson only.

[speak_arabic] — learner pronounces a word aloud
  {"type":"speak_arabic","sort_order":N,"prompt_bn":"এই আরবি শব্দটি বলুন:","correct_answer":{"expected_ar":"WORD_WITH_HARAKAT","transliteration":"latin","meaning_bn":"Bengali"},"grammar_note_bn":"...","difficulty":2}
  Rules: one per lesson, most important word.

ABSOLUTE RULES:
- ALL Arabic must have full harakat (تشكيل) — never bare Arabic
- ONLY use words from the lesson word list
- grammar_note_bn: one line of Arabic grammar explanation (not just the meaning)
- sort_order: sequential integers starting at 1
- Return ONLY a valid JSON array — no markdown, no explanation, no code fences`;

const VERB_EXERCISE_SYSTEM_PROMPT = `You are a Quranic Arabic curriculum designer for Bengali-speaking Muslims.
This lesson teaches verb ROOT FAMILIES — multiple forms of the same Arabic root.

EXERCISE TYPES FOR VERB LESSONS (use exact field names):

[multiple_choice] — identify the root of a verb
  {"type":"multiple_choice","sort_order":N,"prompt_bn":"«VERB» কোন ধাতু (root) থেকে এসেছে?","prompt_ar":"VERB","correct_answer":{"options":["correct_root","wrong1","wrong2","wrong3"],"correct_index":0},"grammar_note_bn":"...","difficulty":2}

[drag_drop] — match verb forms from same root to their meanings
  {"type":"drag_drop","sort_order":N,"prompt_bn":"ধাতু «ROOT» — শব্দের সাথে অর্থ মেলাও:","correct_answer":{"pairs":[{"ar":"VERB_FORM","bn":"meaning"},...],"grammar_note_bn":"...","difficulty":2}

[true_false] — do these two words share the same root?
  {"type":"true_false","sort_order":N,"prompt_bn":"এই দুটি শব্দ কি একই ধাতু থেকে এসেছে?","correct_answer":{"statement_ar":"WORD1 ← WORD2","statement_bn":"Bengali statement","is_true":true},"grammar_note_bn":"...","difficulty":3}

[fill_in_blank] — fill missing verb form
  {"type":"fill_in_blank","sort_order":N,"prompt_bn":"শূন্যস্থানে সঠিক ক্রিয়া বসাও (অর্থ: HINT):","correct_answer":{"sentence":"ARABIC ___ REST","blank_index":N,"answer":"VERB"},"distractors":{"options":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":3}

[speak_arabic] — pronounce the verb
  {"type":"speak_arabic","sort_order":N,"prompt_bn":"এই ক্রিয়াটি বলুন:","correct_answer":{"expected_ar":"VERB_WITH_HARAKAT","transliteration":"latin","meaning_bn":"Bengali"},"grammar_note_bn":"...","difficulty":2}

ABSOLUTE RULES:
- ALL Arabic must have full harakat (تشكيل)
- grammar_note_bn: explain verb form, tense, or root pattern (not just meaning)
- Return ONLY a valid JSON array — no markdown, no explanation`;

// ── Main handler ─────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  const denied = await checkAdmin(req);
  if (denied) return denied;

  try {
    const body = await req.json();
    const unitType   = (body?.unit_type   as UnitType) ?? 'juz_amma';
    const surahNumber = body?.surah_number as number | undefined;
    const lessonIndex = (body?.lesson_index as number) ?? 0;

    if (!Object.keys(UNIT_CONFIG).includes(unitType)) {
      return new Response(JSON.stringify({ error: `Invalid unit_type. Choose: ${Object.keys(UNIT_CONFIG).join(', ')}` }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
    if ((unitType === 'salah' || unitType === 'juz_amma') && !surahNumber) {
      return new Response(JSON.stringify({ error: 'surah_number is required for salah and juz_amma unit types' }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    const sb = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
    const geminiKey = Deno.env.get('GEMINI_API_KEY')!;
    const unitCfg   = UNIT_CONFIG[unitType];

    // ── 1. Fetch surah metadata (for salah/juz_amma only) ─────────────────
    let surahRow: { number: number; name_bn: string; name_ar: string } | null = null;
    if (surahNumber) {
      const { data, error } = await sb.from('quran_surahs')
        .select('number, name_bn, name_ar').eq('number', surahNumber).single();
      if (error || !data) return new Response(JSON.stringify({ error: `Surah ${surahNumber} not found` }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
      surahRow = data as { number: number; name_bn: string; name_ar: string };
    }

    // ── 2. Ensure quranic track ───────────────────────────────────────────
    const { data: trackRow } = await sb.from('tracks').select('id').eq('slug', 'quranic').single();
    if (!trackRow) return new Response(JSON.stringify({ error: 'Quranic track not found — run seed_quran_track.ts first' }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });

    // ── 3. Find or create unit ────────────────────────────────────────────
    let { data: unitRow } = await sb.from('units').select('id').eq('slug', unitCfg.slug).eq('track_id', trackRow.id).single();
    if (!unitRow) {
      const { data: newUnit, error: uErr } = await sb.from('units').insert({
        track_id:   trackRow.id,
        slug:       unitCfg.slug,
        title_bn:   unitCfg.title_bn,
        title_ar:   unitCfg.title_ar,
        sort_order: unitCfg.sort_order,
        tier_level: 1,
        status:     'draft',
      }).select('id').single();
      if (uErr) throw uErr;
      unitRow = newUnit;
    }

    // ── 4. Fetch words based on unit type ─────────────────────────────────
    let words: WordRow[] = [];
    let verbRoots: { root: string; forms: string[] }[] = [];

    if (unitType === 'salah' || unitType === 'juz_amma') {
      words = await fetchSurahWords(sb, surahNumber!);
      if (words.length === 0) return new Response(JSON.stringify({ error: `No words with meanings found for surah ${surahNumber}` }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });

    } else if (unitType === 'frequent') {
      words = await fetchFrequentWords(sb, lessonIndex);
      if (words.length === 0) return new Response(JSON.stringify({ error: 'No frequent words found — check quran_words table' }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });

    } else if (unitType === 'attributes') {
      const passage = ATTRIBUTE_PASSAGES[lessonIndex];
      if (!passage) return new Response(JSON.stringify({ error: `lesson_index must be 0–${ATTRIBUTE_PASSAGES.length - 1} for attributes` }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
      words = await fetchAttributeWords(sb, geminiKey, passage);
      if (words.length < 4) return new Response(JSON.stringify({ error: 'Too few Names found in this passage — check quran_words table' }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });

    } else if (unitType === 'verbs') {
      verbRoots = await fetchVerbRoots(sb, lessonIndex);
      words     = await verbRootsToWords(sb, verbRoots);
      if (words.length < 2) return new Response(JSON.stringify({ error: 'Too few verb forms — run enrich_quran_roots.ts first' }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    // ── 5. Build lesson title + sort_order ────────────────────────────────
    const lessonTitleBn = getLessonTitle(unitType, surahRow?.name_bn ?? '', lessonIndex);
    const lessonSortOrder = (unitType === 'salah' || unitType === 'juz_amma')
      ? (surahNumber ?? lessonIndex + 1)
      : (lessonIndex + 1);

    // ── 6. Upsert lesson ──────────────────────────────────────────────────
    let lessonId: string;
    const { data: existingLesson } = await sb.from('lessons')
      .select('id').eq('unit_id', unitRow!.id).eq('title_bn', lessonTitleBn).single();

    if (existingLesson) {
      lessonId = existingLesson.id;
      await Promise.all([
        sb.from('exercises').delete().eq('lesson_id', lessonId),
        sb.from('vocabulary').delete().eq('lesson_id', lessonId),
      ]);
    } else {
      const { data: newLesson, error: lErr } = await sb.from('lessons').insert({
        unit_id:    unitRow!.id,
        title_bn:   lessonTitleBn,
        sort_order: lessonSortOrder,
        level:      'beginner',
        status:     'draft',
      }).select('id').single();
      if (lErr) throw lErr;
      lessonId = newLesson!.id;
    }

    // ── 7. Gemini enrichment (transliteration, meaning_en, grammar_note) ──
    type EnrichedWord = WordRow & { transliteration: string | null; meaning_en: string | null; grammar_note_bn: string | null };
    let enrichedWords: EnrichedWord[] = words.map(w => ({ ...w, transliteration: null, meaning_en: null, grammar_note_bn: null }));

    try {
      const wordList = words.map((w, i) => `${i + 1}. ${w.arabic} = ${w.meaning_bn}`).join('\n');
      const enrichPrompt = `For each Quranic Arabic word below, provide transliteration (phonetic Latin), meaning_en (1–3 English words), and grammar_note_bn (one-line Bangla grammar note — word type, form, root).
Return a JSON array: [{"arabic":"...","transliteration":"...","meaning_en":"...","grammar_note_bn":"..."}]
Only return valid JSON. No markdown.

Words:
${wordList}`;
      const enriched = JSON.parse(stripFences(await geminiGenerate(geminiKey, enrichPrompt))) as Array<{ arabic: string; transliteration: string; meaning_en: string; grammar_note_bn: string }>;
      const enrichMap = new Map(enriched.map(e => [e.arabic, e]));
      enrichedWords = words.map(w => {
        const e = enrichMap.get(w.arabic);
        return { ...w, transliteration: e?.transliteration ?? null, meaning_en: e?.meaning_en ?? null, grammar_note_bn: e?.grammar_note_bn ?? null };
      });
    } catch (e) {
      console.warn('Enrichment failed, continuing without:', (e as Error).message);
    }

    // ── 8. Build ayah context (salah/juz_amma only) ───────────────────────
    const ayahTexts     = new Map<string, string>();
    const tafsirSnippets = new Map<string, string>();
    if (surahNumber && (unitType === 'salah' || unitType === 'juz_amma')) {
      const ayahKeys = [...new Set((words as (WordRow & { ayah?: number })[]).map(w => `${surahNumber}:${w.ayah}`))];
      await Promise.all(ayahKeys.slice(0, 8).map(async (key) => {
        const [s, a] = key.split(':').map(Number);
        const [{ data: ayahWords }, { data: tafsir }] = await Promise.all([
          sb.from('quran_words').select('arabic').eq('surah', s).eq('ayah', a).order('position'),
          sb.from('quran_tafsir').select('tafsir_text').eq('surah', s).eq('ayah', a).single(),
        ]);
        if (ayahWords) ayahTexts.set(key, (ayahWords as { arabic: string }[]).map(w => w.arabic).join(' '));
        if (tafsir?.tafsir_text) tafsirSnippets.set(key, (tafsir.tafsir_text as string).slice(0, 120) + '…');
      }));
    }

    // ── 9. Insert vocabulary ──────────────────────────────────────────────
    const vocabRows = enrichedWords.map((w) => {
      const key = surahNumber ? `${surahNumber}:${(w as WordRow & { ayah?: number }).ayah}` : '';
      return {
        lesson_id:          lessonId,
        arabic:             w.arabic,
        meaning_bn:         w.meaning_bn,
        meaning_en:         w.meaning_en,
        transliteration:    w.transliteration,
        grammar_note_bn:    w.grammar_note_bn,
        word_type:          unitType === 'verbs' ? 'verb' : 'noun',
        context_snippet_ar: ayahTexts.get(key) ?? null,
        context_snippet_bn: tafsirSnippets.get(key) ?? null,
      };
    });
    if (vocabRows.length > 0) {
      const { error: vErr } = await sb.from('vocabulary').insert(vocabRows);
      if (vErr) throw new Error(`Vocabulary insert failed: ${vErr.message}`);
    }

    // ── 10. 6s pause then generate exercises ─────────────────────────────
    await new Promise(r => setTimeout(r, 6000));

    let exerciseCount = 0;
    let exerciseError: string | null = null;
    const exWords = enrichedWords.slice(0, 15);

    if (exWords.length >= 2) {
      try {
        const isVerbLesson  = unitType === 'verbs';
        const systemPrompt  = isVerbLesson ? VERB_EXERCISE_SYSTEM_PROMPT : EXERCISE_SYSTEM_PROMPT;

        let contextLabel: string;
        if (unitType === 'salah' || unitType === 'juz_amma') contextLabel = `সূরা ${surahRow?.name_bn}`;
        else if (unitType === 'attributes') contextLabel = ATTRIBUTE_THEMES[lessonIndex]?.titleBn ?? 'আল্লাহর গুণাবলী';
        else if (unitType === 'verbs') {
          contextLabel = `ক্রিয়া ধাতু: ${verbRoots.map(r => r.root).join(', ')}`;
        }
        else contextLabel = `শীর্ষ শব্দ পাঠ ${lessonIndex + 1}`;

        const wordList = exWords.map((w, i) =>
          `${i + 1}. ${w.arabic} (${w.transliteration ?? '?'}) = ${w.meaning_bn}`
        ).join('\n');

        const userPrompt = isVerbLesson
          ? `Context: ${contextLabel}
Verb root families:
${verbRoots.map(r => `• ${r.root}: ${r.forms.slice(0, 4).join(', ')}`).join('\n')}

Lesson word list:
${wordList}

Generate: 3×multiple_choice, 2×drag_drop, 1×true_false, 1×fill_in_blank, 1×speak_arabic
= 8 exercises total (sort_order 1–8). Return valid JSON array only.`
          : `Context: ${contextLabel}

Lesson word list (arabic · transliteration = Bengali):
${wordList}

Generate: 3×multiple_choice, 2×drag_drop, 1×true_false, 1×fill_in_blank, 1×tap_to_build, 1×speak_arabic
= 9 exercises total (sort_order 1–9). Return valid JSON array only.`;

        const rawEx   = extractJsonArray(await geminiGenerate(geminiKey, `${systemPrompt}\n\n${userPrompt}`));
        const exercises = JSON.parse(rawEx) as Array<Record<string, unknown>>;

        if (!Array.isArray(exercises) || exercises.length === 0) {
          throw new Error('Gemini returned empty exercise array');
        }

        const { data: inserted, error: exErr } = await sb.from('exercises').insert(
          exercises.map((ex, idx) => ({
            lesson_id:      lessonId,
            type:           ex.type,
            sort_order:     (ex.sort_order as number) ?? (idx + 1),
            prompt_bn:      ex.prompt_bn,
            prompt_ar:      (ex.prompt_ar as string | undefined) ?? null,
            correct_answer: ex.correct_answer,
            distractors:    (ex.distractors as unknown) ?? null,
            grammar_note_bn: (ex.grammar_note_bn as string | undefined) ?? null,
            difficulty:     (ex.difficulty as number) ?? 1,
          }))
        ).select('id');
        if (exErr) throw new Error(`Exercise insert: ${exErr.message}`);
        exerciseCount = inserted?.length ?? 0;
      } catch (e) {
        exerciseError = (e as Error).message;
        console.error('Exercise generation failed:', exerciseError);
      }
    }

    return new Response(
      JSON.stringify({
        success:        true,
        lesson_id:      lessonId,
        unit_type:      unitType,
        lesson_title:   lessonTitleBn,
        vocab_count:    vocabRows.length,
        exercise_count: exerciseCount,
        ...(exerciseError ? { exercise_error: exerciseError } : {}),
      }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } },
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error('curate-quran-lesson error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });
  }
});
