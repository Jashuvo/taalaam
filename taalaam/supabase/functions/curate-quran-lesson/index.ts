// curate-quran-lesson/index.ts
// Generates Quranic lessons for all 5 curriculum units.
// Admin-only. Body: { unit_type, surah_number?, lesson_index? }
//
// unit_type:
//   'salah'      — Language of Salah (surahs 1,112,108,103) — requires surah_number
//   'juz_amma'   — Juz Amma surahs (78–114)                 — requires surah_number
//   'frequent'   — Top-100 most frequent words (5 lessons)   — requires lesson_index 0–4
//   'attributes' — Names of Allah from 8 Quranic passages    — requires lesson_index 0–7
//   'verbs'      — Verb roots (5 lessons, needs root data)    — requires lesson_index 0–4
//
// Exercise types generated:
//   Standard:      multiple_choice, drag_drop, true_false, fill_in_blank, tap_to_build, speak_arabic
//   Quranic-only:  ayah_read, tafsir_read, ayah_context, surah_theme, reflection_card
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

// Salah context per surah — shown in ayah_read cards so the learner knows WHEN they recite this
const SALAH_POSITIONS: Record<number, string> = {
  1:   'প্রতি রাকআতে ফরজ — ফাতিহা ছাড়া সালাত শুদ্ধ হয় না (সহীহ বুখারী ৭৫৬)',
  112: 'প্রতিদিনের সালাতে পঠিত — কুরআনের এক-তৃতীয়াংশের সমতুল্য (সহীহ বুখারী ৫০১৫)',
  108: 'সালাতে পঠিত ছোট সূরা — মক্কায় অবতীর্ণ, ৩টি আয়াত',
  103: 'সালাতে পঠিত — সাহাবীরা একে অপরের সাথে সাক্ষাতে এটি তিলাওয়াত করতেন',
};

// 8 Quranic passages with the densest clusters of Allah's Names.
// Ordered by pedagogical priority per Ibn Uthaymin's al-Qawa'id al-Muthla.
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

  // Ask Gemini to filter to only divine Names/Attributes
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

// ── Ayah text helpers ────────────────────────────────────────────────────────

// Fetch full ayah texts + tafsir snippets — sequential to stay within free-tier memory limits
async function fetchAyahTexts(
  sb: SupabaseClient,
  ayahKeys: string[],
): Promise<{ ayahTexts: Map<string, string>; tafsirSnippets: Map<string, string> }> {
  const ayahTexts     = new Map<string, string>();
  const tafsirSnippets = new Map<string, string>();
  for (const key of ayahKeys.slice(0, 4)) { // max 4 ayahs to stay within memory budget
    const [s, a] = key.split(':').map(Number);
    const { data: ayahWords } = await sb
      .from('quran_words').select('arabic').eq('surah', s).eq('ayah', a).order('position');
    if (ayahWords) ayahTexts.set(key, (ayahWords as { arabic: string }[]).map(w => w.arabic).join(' '));
    const { data: tafsir } = await sb
      .from('quran_tafsir').select('tafsir_text').eq('surah', s).eq('ayah', a).single();
    if (tafsir?.tafsir_text) tafsirSnippets.set(key, (tafsir.tafsir_text as string).slice(0, 100) + '…');
  }
  return { ayahTexts, tafsirSnippets };
}

// Format ayah map into a readable string for the Gemini prompt
function formatAyahsForPrompt(ayahTexts: Map<string, string>, tafsirSnippets: Map<string, string>): string {
  return [...ayahTexts.entries()]
    .map(([key, ar]) => {
      const tafsir = tafsirSnippets.get(key);
      return `${key} → ${ar}${tafsir ? `\n  (তাফসীর: ${tafsir})` : ''}`;
    })
    .join('\n');
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

// ── Exercise system prompt ───────────────────────────────────────────────────

const EXERCISE_SYSTEM_PROMPT = `Quranic Arabic curriculum designer for Bengali-speaking Muslims (Salafi: Ibn Sa'di, Ibn Uthaymin — no philosophical interpretation).

SCHEMAS (exact snake_case type strings, sequential sort_order):
{"type":"multiple_choice","sort_order":N,"prompt_bn":"«W» অর্থ কী?","prompt_ar":"W","correct_answer":{"options":["ok","w1","w2","w3"],"correct_index":0},"grammar_note_bn":"...","difficulty":1}
{"type":"drag_drop","sort_order":N,"prompt_bn":"মিলাও:","correct_answer":{"pairs":[{"ar":"W","bn":"M"},{"ar":"W2","bn":"M2"},{"ar":"W3","bn":"M3"}]},"grammar_note_bn":"...","difficulty":2}
{"type":"fill_in_blank","sort_order":N,"prompt_bn":"বসাও (অর্থ:HINT):","correct_answer":{"sentence":"AR ___ REST","blank_index":N,"answer":"W"},"distractors":{"options":["w1","w2"]},"grammar_note_bn":"...","difficulty":3}
{"type":"speak_arabic","sort_order":N,"prompt_bn":"বলুন:","correct_answer":{"expected_ar":"W","transliteration":"latin","meaning_bn":"BN"},"grammar_note_bn":"...","difficulty":2}
{"type":"ayah_read","sort_order":N,"prompt_bn":"আয়াতটি পড়ুন:","correct_answer":{"ayah_ar":"EXACT","ayah_bn":"BN","surah_name":"সূরা X","ayah_number":N,"context_bn":"WHY"},"difficulty":0}
{"type":"tafsir_read","sort_order":N,"prompt_bn":"সূরা পরিচিতি:","correct_answer":{"surah_name":"X","revelation":"মাক্কী/মাদানী","theme_bn":"TOPIC","aqeedah_bn":"SALAFI_BELIEF","tafsir_bn":"2_SENTENCES_IBN_SADI"},"difficulty":0}
{"type":"ayah_context","sort_order":N,"prompt_bn":"হাইলাইট শব্দের অর্থ?","prompt_ar":"W","correct_answer":{"ayah_ar":"EXACT","highlighted_word":"W_IN_AYAH","options":["ok","w1","w2","w3"],"correct_index":0},"grammar_note_bn":"...","difficulty":2}
{"type":"surah_theme","sort_order":N,"prompt_bn":"সূরা X-এর মূল বিষয়?","correct_answer":{"options":["ok","w1","w2","w3"],"correct_index":0},"grammar_note_bn":"...","difficulty":2}
{"type":"reflection_card","sort_order":N,"prompt_bn":"চিন্তা করুন:","correct_answer":{"reflection_prompt":"QUESTION","scholarly_note_bn":"IBN_UTHAYMIN_NOTE"},"difficulty":0}
{"type":"root_family","sort_order":N,"prompt_bn":"কোন শব্দটি এই ধাতুর নয়?","correct_answer":{"root_ar":"X-Y-Z","root_meaning_bn":"BN","words":[{"arabic":"W","meaning_bn":"M"},{"arabic":"W2","meaning_bn":"M2"},{"arabic":"W3","meaning_bn":"M3"},{"arabic":"ODD","meaning_bn":"M4"}],"odd_index":3},"grammar_note_bn":"...","difficulty":2}
{"type":"aqeedah_true","sort_order":N,"prompt_bn":"এই বক্তব্যটি কি সঠিক?","correct_answer":{"statement_bn":"STMT_ABOUT_NAME","is_correct":false,"explanation_bn":"IBN_UTHAYMIN_CORRECTION_2_SENTENCES"},"difficulty":2}
{"type":"ayah_cloze","sort_order":N,"prompt_bn":"শূন্যস্থানে কোন শব্দটি বসবে?","correct_answer":{"ayah_ar":"FULL_AYAH_EXACT","surah_name":"সূরা X","ayah_number":N,"blank_word":"WORD_IN_AYAH","blank_position":N,"options":["correct","w1","w2","w3"],"correct_index":0},"difficulty":2}
{"type":"grammar_spot","sort_order":N,"prompt_bn":"কোনটি POSBENGALI (POSARABIC)?","correct_answer":{"target_pos_ar":"فِعْلٌ","target_pos_bn":"ক্রিয়াপদ","words":[{"arabic":"W","meaning_bn":"M","pos":"verb"},{"arabic":"W2","meaning_bn":"M2","pos":"noun"},{"arabic":"W3","meaning_bn":"M3","pos":"noun"},{"arabic":"W4","meaning_bn":"M4","pos":"particle"}],"correct_index":0},"difficulty":2}

RULES: Arabic always with full harakat (تشكيل). ayah_ar/highlighted_word/blank_word EXACT from provided texts. root_family: 3 words from stated root + 1 odd. aqeedah_true: test ta'wil or tashbih errors (is_correct usually false). grammar_spot: exactly 1 correct pos match among 4 words. Return ONLY valid JSON array.`;

const VERB_EXERCISE_SYSTEM_PROMPT = `Quranic Arabic curriculum designer for Bengali-speaking Muslims. This lesson teaches verb ROOT FAMILIES.

SCHEMAS:
{"type":"grammar_spot","sort_order":N,"prompt_bn":"কোনটি ক্রিয়াপদ (فِعْلٌ)?","correct_answer":{"target_pos_ar":"فِعْلٌ","target_pos_bn":"ক্রিয়াপদ","words":[{"arabic":"V","meaning_bn":"M","pos":"verb"},{"arabic":"W2","meaning_bn":"M2","pos":"noun"},{"arabic":"W3","meaning_bn":"M3","pos":"noun"},{"arabic":"W4","meaning_bn":"M4","pos":"particle"}],"correct_index":0},"difficulty":2}
{"type":"root_family","sort_order":N,"prompt_bn":"কোন শব্দটি ধাতু X-এর নয়?","correct_answer":{"root_ar":"X-Y-Z","root_meaning_bn":"BN","words":[{"arabic":"W","meaning_bn":"M"},{"arabic":"W2","meaning_bn":"M2"},{"arabic":"W3","meaning_bn":"M3"},{"arabic":"ODD","meaning_bn":"M4"}],"odd_index":3},"grammar_note_bn":"...","difficulty":2}
{"type":"multiple_choice","sort_order":N,"prompt_bn":"«VERB» কোন ধাতু থেকে?","prompt_ar":"VERB","correct_answer":{"options":["root","w1","w2","w3"],"correct_index":0},"grammar_note_bn":"...","difficulty":2}
{"type":"drag_drop","sort_order":N,"prompt_bn":"ধাতু «ROOT» — মেলাও:","correct_answer":{"pairs":[{"ar":"V1","bn":"M1"},{"ar":"V2","bn":"M2"},{"ar":"V3","bn":"M3"}]},"grammar_note_bn":"...","difficulty":2}
{"type":"fill_in_blank","sort_order":N,"prompt_bn":"সঠিক ক্রিয়া বসাও (অর্থ:HINT):","correct_answer":{"sentence":"AR ___ REST","blank_index":N,"answer":"VERB"},"distractors":{"options":["w1","w2"]},"grammar_note_bn":"...","difficulty":3}
{"type":"speak_arabic","sort_order":N,"prompt_bn":"বলুন:","correct_answer":{"expected_ar":"VERB","transliteration":"latin","meaning_bn":"BN"},"grammar_note_bn":"...","difficulty":2}

RULES: All Arabic with full harakat. grammar_note_bn explains verb form/tense/root pattern. Return ONLY valid JSON array.`;

// ── Build per-unit exercise user prompt ──────────────────────────────────────

function buildExerciseUserPrompt(opts: {
  unitType: UnitType;
  surahRow: { name_bn: string; name_ar: string; revelation?: string } | null;
  surahNumber: number | undefined;
  lessonIndex: number;
  verbRoots: { root: string; forms: string[] }[];
  exWords: Array<{ arabic: string; transliteration: string | null; meaning_bn: string }>;
  ayahTexts: Map<string, string>;
  tafsirSnippets: Map<string, string>;
  passageTitleBn: string;
}): string {
  const { unitType, surahRow, surahNumber, lessonIndex, verbRoots, exWords, ayahTexts, tafsirSnippets, passageTitleBn } = opts;
  const wordList = exWords.map((w, i) => `${i + 1}. ${w.arabic} (${w.transliteration ?? '?'}) = ${w.meaning_bn}`).join('\n');
  const ayahsBlock = formatAyahsForPrompt(ayahTexts, tafsirSnippets);

  switch (unitType) {

    case 'salah': {
      const salahCtx = SALAH_POSITIONS[surahNumber!] ?? 'সালাতে পঠিত';
      const firstKey = [...ayahTexts.keys()][0] ?? `${surahNumber}:1`;
      const firstAyahNum = parseInt(firstKey.split(':')[1]);
      const firstAyahAr = ayahTexts.get(firstKey) ?? '';
      return `সূরা: ${surahRow?.name_bn} (${surahRow?.name_ar}) #${surahNumber}
সালাতে: ${salahCtx}

আয়াত (EXACT for ayah_read/ayah_cloze):
${ayahsBlock}

শব্দ (${exWords.length}):
${wordList}

৬টি অনুশীলন (sort_order 1–6):
1. ayah_read: ayah_ar="${firstAyahAr}" ayah_bn=অনুবাদ surah_name="সূরা ${surahRow?.name_bn}" ayah_number=${firstAyahNum} context_bn="${salahCtx}"
2. tafsir_read: revelation+theme_bn+aqeedah_bn+tafsir_bn (ইবনু সা'দী, ২ বাক্য)
3. ayah_cloze: blank one lesson word from the first ayah above — 4 Arabic options
4. multiple_choice
5. drag_drop (3 pairs)
6. speak_arabic

Return JSON array only.`;
    }

    case 'juz_amma': {
      const firstTwo = [...ayahTexts.entries()].slice(0, 2);
      const ayahReadLines = firstTwo.map(([key, ar], idx) => {
        const ayahNum = parseInt(key.split(':')[1]);
        const sn = surahRow?.name_bn ?? '';
        return `${idx + 2}. ayah_read (sort_order ${idx + 2}): ayah_ar=EXACTLY "${ar}" | ayah_bn=সঠিক বাংলা অনুবাদ | surah_name="সূরা ${sn}" | ayah_number=${ayahNum} | context_bn=এই আয়াতের তাৎপর্য`;
      }).join('\n');
      const firstKey = [...ayahTexts.keys()][0] ?? `${surahNumber}:1`;
      const firstAyahNum = parseInt(firstKey.split(':')[1]);
      const firstAyahAr = ayahTexts.get(firstKey) ?? '';
      return `সূরা: ${surahRow?.name_bn} (${surahRow?.name_ar}) #${surahNumber}
নাযিল: ${surahRow?.revelation ?? 'মাক্কী'}

আয়াত (EXACT for ayah_read/ayah_context/ayah_cloze):
${ayahsBlock}

শব্দ (${exWords.length}):
${wordList}

৭টি অনুশীলন (sort_order 1–7):
1. tafsir_read: revelation+theme_bn+aqeedah_bn+tafsir_bn (ইবনু সা'দী, ২ বাক্য)
${ayahReadLines}
4. surah_theme: প্রধান বিষয় ৪ অপশন
5. ayah_cloze: blank one lesson word from ayah_ar="${firstAyahAr}" ayah_number=${firstAyahNum}
6. ayah_context: প্রথম আয়াত থেকে ১ শব্দ হাইলাইট — ৪ অপশন
7. speak_arabic

Return JSON array only.`;
    }

    case 'attributes': {
      const passage = ATTRIBUTE_PASSAGES[lessonIndex];
      const firstKey = [...ayahTexts.keys()][0] ?? `${passage?.surah}:${passage?.ayahFrom}`;
      const firstAyahNum = parseInt(firstKey.split(':')[1]);
      const firstAyahAr = ayahTexts.get(firstKey) ?? '';
      return `পাঠ: ${passageTitleBn} (সূরা ${passage?.surah}:${passage?.ayahFrom}–${passage?.ayahTo})

আয়াত (EXACT Arabic):
${ayahsBlock}

নামসমূহ (${exWords.length}):
${wordList}

৮টি অনুশীলন (sort_order 1–8):
1. ayah_read: ayah_ar="${firstAyahAr}" ayah_bn=অনুবাদ surah_name=উপযুক্ত_সূরা ayah_number=${firstAyahNum} context_bn="এই আয়াতে আল্লাহর নাম ও গুণাবলী"
2. reflection_card: এই নামগুলোর athar (মুমিনের হৃদয়ে প্রভাব) — ইবনু উসাইমীন পদ্ধতিতে ব্যক্তিগত প্রশ্ন
3–4. 2×aqeedah_true: একটি সঠিক বক্তব্য (is_correct:true) + একটি ta'wil বা tashbih ভুল (is_correct:false) — এই পাঠের নামগুলো সম্পর্কে
5–6. 2×multiple_choice: নাম → অর্থ
7. drag_drop (3 pairs)
8. speak_arabic

Return JSON array only.`;
    }

    case 'frequent': {
      const start = lessonIndex * 20 + 1;
      return `পাঠ ${lessonIndex + 1} — কুরআনের শীর্ষ ব্যবহৃত শব্দ #${start}–${start + 19}

শব্দ তালিকা:
${wordList}

৮টি অনুশীলন (sort_order 1–8):
1. root_family: শব্দ তালিকা থেকে একটি ধাতু বেছে — ৩টি সেই ধাতু থেকে + ১টি ভিন্ন ধাতুর (odd_index=3)
2. grammar_spot: ৪টি শব্দ — একটি فعل, একটি حرف, দুটি اسم — কোনটি فعل বা اسم বা حرف?
3–4. 2×multiple_choice
5. ayah_context: শব্দ তালিকার যেকোনো শব্দ একটি Quranic ayah থেকে (আরবি লিখে ayah_ar বানাও)
6. drag_drop (3 pairs)
7. fill_in_blank
8. speak_arabic

Return valid JSON array only.`;
    }

    case 'verbs': {
      return `ক্রিয়া ধাতু: ${verbRoots.map(r => r.root).join(', ')}
ধাতু পরিবার:
${verbRoots.map(r => `• ${r.root}: ${r.forms.slice(0, 4).join(', ')}`).join('\n')}

শব্দ তালিকা:
${wordList}

৭টি অনুশীলন (sort_order 1–7):
1. grammar_spot: ৪টি শব্দ — কোনটি فعل? (ক্রিয়াপদ)
2. root_family: একটি ধাতু থেকে ৩টি ক্রিয়ারূপ + ১টি ভিন্ন ধাতুর শব্দ (odd_index=3)
3–4. 2×multiple_choice: ক্রিয়া → ধাতু চিনুন
5–6. 2×drag_drop: ধাতু পরিবার মেলানো
7. speak_arabic

Return valid JSON array only.`;
    }
  }
}

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
    let surahRow: { number: number; name_bn: string; name_ar: string; revelation?: string } | null = null;
    if (surahNumber) {
      const { data, error } = await sb.from('quran_surahs')
        .select('number, name_bn, name_ar, revelation').eq('number', surahNumber).single();
      if (error || !data) return new Response(JSON.stringify({ error: `Surah ${surahNumber} not found` }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
      surahRow = data as { number: number; name_bn: string; name_ar: string; revelation?: string };
    }

    // ── 2. Ensure quranic track ───────────────────────────────────────────
    const { data: trackRow } = await sb.from('tracks').select('id').eq('slug', 'quranic').single();
    if (!trackRow) return new Response(JSON.stringify({ error: 'Quranic track not found — run seed_quran_track.ts first' }), {
      status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders },
    });

    // ── 3. Find or create unit ────────────────────────────────────────────
    let { data: unitRow } = await sb.from('units').select('id, status').eq('slug', unitCfg.slug).eq('track_id', trackRow.id).single();
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
      // Pause after Gemini call in fetchAttributeWords before next call
      await new Promise(r => setTimeout(r, 4000));

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

    const newLessonStatus = (unitRow as any)?.status === 'published' ? 'review' : 'draft';

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
        status:     newLessonStatus,
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

    // ── 8. Build ayah context from DB (salah, juz_amma, attributes) ───────
    let ayahTexts     = new Map<string, string>();
    let tafsirSnippets = new Map<string, string>();

    if (unitType === 'salah' || unitType === 'juz_amma') {
      // For surah-based units: get ayah texts for the words we have
      const ayahKeys = [...new Set((words as (WordRow & { ayah?: number })[])
        .filter(w => w.ayah != null)
        .map(w => `${surahNumber}:${w.ayah}`))];
      const result = await fetchAyahTexts(sb, ayahKeys);
      ayahTexts     = result.ayahTexts;
      tafsirSnippets = result.tafsirSnippets;

    } else if (unitType === 'attributes') {
      // For attributes: get ayah texts for the passage range
      const passage = ATTRIBUTE_PASSAGES[lessonIndex];
      if (passage) {
        const ayahKeys: string[] = [];
        for (let a = passage.ayahFrom; a <= Math.min(passage.ayahTo, passage.ayahFrom + 3); a++) {
          ayahKeys.push(`${passage.surah}:${a}`);
        }
        const result = await fetchAyahTexts(sb, ayahKeys);
        ayahTexts     = result.ayahTexts;
        tafsirSnippets = result.tafsirSnippets;
      }
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
        const isVerbLesson = unitType === 'verbs';
        const systemPrompt = isVerbLesson ? VERB_EXERCISE_SYSTEM_PROMPT : EXERCISE_SYSTEM_PROMPT;

        const userPrompt = buildExerciseUserPrompt({
          unitType,
          surahRow,
          surahNumber,
          lessonIndex,
          verbRoots,
          exWords,
          ayahTexts,
          tafsirSnippets,
          passageTitleBn: ATTRIBUTE_PASSAGES[lessonIndex]?.titleBn ?? `গুণাবলী পাঠ ${lessonIndex + 1}`,
        });

        const rawEx   = extractJsonArray(await geminiGenerate(geminiKey, `${systemPrompt}\n\n${userPrompt}`));
        const exercises = JSON.parse(rawEx) as Array<Record<string, unknown>>;

        if (!Array.isArray(exercises) || exercises.length === 0) {
          throw new Error('Gemini returned empty exercise array');
        }

        // Gemini sometimes outputs camelCase types (e.g. "ayahRead") even when told snake_case.
        // Normalise to snake_case then drop any type not in the DB constraint so one bad
        // exercise never poisons the entire batch.
        const VALID_TYPES = new Set([
          'tap_to_build','fill_in_blank','multiple_choice','drag_drop','word_scramble',
          'true_false','chat_complete','translate_build','listen_select','speak_arabic',
          'ayah_read','tafsir_read','ayah_context','surah_theme','reflection_card',
          'root_family','aqeedah_true','ayah_cloze','grammar_spot',
        ]);
        const toSnake = (s: string) => s.replace(/([A-Z])/g, m => `_${m.toLowerCase()}`);

        const validExercises = exercises
          .map(ex => ({ ...ex, type: toSnake(ex.type as string) }))
          .filter(ex => VALID_TYPES.has(ex.type as string));

        if (validExercises.length === 0) {
          throw new Error(`No valid exercise types — Gemini returned: ${exercises.map(e => e.type).join(', ')}`);
        }

        const { data: inserted, error: exErr } = await sb.from('exercises').insert(
          validExercises.map((ex, idx) => ({
            lesson_id:       lessonId,
            type:            ex.type,
            sort_order:      (ex.sort_order as number) ?? (idx + 1),
            prompt_bn:       ex.prompt_bn,
            prompt_ar:       (ex.prompt_ar as string | undefined) ?? null,
            correct_answer:  ex.correct_answer,
            distractors:     (ex.distractors as unknown) ?? null,
            grammar_note_bn: (ex.grammar_note_bn as string | undefined) ?? null,
            difficulty:      (ex.difficulty as number) ?? 1,
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
