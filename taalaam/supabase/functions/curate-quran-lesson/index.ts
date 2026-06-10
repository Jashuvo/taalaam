// curate-quran-lesson/index.ts
// Generates Quranic lessons for all 5 curriculum units.
// Admin-only. Body: { unit_type, surah_number?, lesson_index? }
//
// unit_type:
//   'salah'      — Language of Salah (surahs 1,112,108,103) — requires surah_number
//   'juz_amma'   — Juz Amma surahs (78–114)                 — requires surah_number
//   'frequent'   — Top-300 most frequent words (15 lessons)  — requires lesson_index 0–14
//   'attributes' — Names of Allah from 8 Quranic passages    — requires lesson_index 0–7
//   'verbs'      — Verb roots (5 lessons, needs root data)    — requires lesson_index 0–4
//   'particles'  — Top harf/particles (4 lessons)             — requires lesson_index 0–3
//   'pronouns'   — Pronouns + attached suffixes (3 lessons)   — requires lesson_index 0–2
//
// Exercise types generated:
//   Standard:      multiple_choice, drag_drop, true_false, fill_in_blank, tap_to_build, speak_arabic
//   Quranic-only:  ayah_read, tafsir_read, ayah_context, surah_theme, reflection_card,
//                  ayah_complete (real-ayah fill-in-blank), ayah_order (real-ayah word order)
//
// Deploy: supabase functions deploy curate-quran-lesson --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient }        from 'npm:@supabase/supabase-js';
import { AZKAAR_LESSONS }      from './salah_azkaar_data.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ADMIN_EMAIL  = 'jubayedsr@gmail.com';
const GEMINI_MODELS = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite', 'gemini-2.5-flash'];

// ── Types ────────────────────────────────────────────────────────────────────

type UnitType = 'salah' | 'azkaar' | 'juz_amma' | 'frequent' | 'attributes' | 'verbs' | 'particles' | 'pronouns';

interface WordRow { arabic: string; meaning_bn: string; ayah?: number; position?: number; surah?: number; }

// ── Unit config ──────────────────────────────────────────────────────────────

const UNIT_CONFIG: Record<UnitType, { slug: string; title_bn: string; title_ar: string; sort_order: number }> = {
  salah:      { slug: 'salah-vocabulary', title_bn: 'সালাতের ভাষা',           title_ar: 'لُغَةُ الصَّلَاة',               sort_order: 1 },
  azkaar:     { slug: 'salah-azkaar',     title_bn: 'সালাতের আযকার',           title_ar: 'أَذْكَارُ الصَّلَاةِ',            sort_order: 2 },
  frequent:   { slug: 'frequent-words',  title_bn: 'সবচেয়ে বেশি ব্যবহৃত শব্দ', title_ar: 'الكَلِمَاتُ الأَكْثَرُ تَكْرَارًا', sort_order: 3 },
  attributes: { slug: 'asma-sifat',      title_bn: 'আল্লাহর গুণাবলী',          title_ar: 'أَسْمَاءُ اللهِ الحُسْنَى',       sort_order: 4 },
  juz_amma:   { slug: 'juz-amma',        title_bn: 'জুয আম্মার সূরা',          title_ar: 'سُوَرُ جُزْءِ عَمَّ',             sort_order: 5 },
  verbs:      { slug: 'quranic-verbs',   title_bn: 'কুরআনের ক্রিয়াপদ',        title_ar: 'الأَفْعَالُ القُرْآنِيَّة',       sort_order: 6 },
  particles:  { slug: 'harf-mastery',    title_bn: 'হারফ মাস্টারি',            title_ar: 'إِتْقَانُ الحُرُوفِ',            sort_order: 7 },
  pronouns:   { slug: 'pronouns',        title_bn: 'সর্বনাম ও যুক্ত সর্বনাম',   title_ar: 'الضَّمَائِرُ',                   sort_order: 8 },
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

async function fetchParticleWords(sb: SupabaseClient, lessonIndex: number): Promise<WordRow[]> {
  const { data, error } = await sb.rpc('get_quran_particles', {
    limit_count: 8,
    offset_count: lessonIndex * 8,
  });
  if (error) throw new Error(`get_quran_particles: ${error.message}`);
  return (data ?? []) as WordRow[];
}

async function fetchPronounWords(sb: SupabaseClient, lessonIndex: number): Promise<WordRow[]> {
  const { data, error } = await sb.rpc('get_quran_pronoun_words', {
    limit_count: 8,
    offset_count: lessonIndex * 8,
  });
  if (error) throw new Error(`get_quran_pronoun_words: ${error.message}`);
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

// ── Authentic-ayah grounding for ayah_complete / ayah_order ─────────────────

interface GroundedAyah { ar: string; answer?: string; surahName: string; ayahNumber: number; }

// Pick a lesson word whose ayah (already fetched into ayahTexts) is short enough
// for ayah_complete (<=12 words) or ayah_order (<=7 words). Used for salah/juz_amma
// where words carry surah/ayah location.
function findGroundedAyah(
  words: WordRow[],
  ayahTexts: Map<string, string>,
  surahNumber: number | undefined,
  surahNameBn: string,
  maxWords: number,
  excludeAyahNumber?: number,
): GroundedAyah | null {
  if (surahNumber == null) return null;
  for (const w of words) {
    if (w.ayah == null || w.ayah === excludeAyahNumber) continue;
    const ar = ayahTexts.get(`${surahNumber}:${w.ayah}`);
    if (!ar) continue;
    const wordCount = ar.split(/\s+/).filter(Boolean).length;
    if (wordCount >= 2 && wordCount <= maxWords) {
      return { ar, answer: w.arabic, surahName: surahNameBn, ayahNumber: w.ayah };
    }
  }
  return null;
}

// Find a short authentic ayah containing the given word — used for 'frequent'
// where words have no surah/ayah location of their own.
async function fetchShortAyahForWord(
  sb: SupabaseClient,
  wordArabic: string,
  maxWords: number,
): Promise<GroundedAyah | null> {
  const { data, error } = await sb.rpc('find_short_ayah_for_word', { word_arabic: wordArabic, max_words: maxWords });
  if (error || !data?.length) return null;
  const row = data[0] as { surah: number; ayah: number };
  const { data: ayahWords } = await sb.from('quran_words')
    .select('arabic').eq('surah', row.surah).eq('ayah', row.ayah).order('position');
  if (!ayahWords?.length) return null;
  const { data: surahRow } = await sb.from('quran_surahs')
    .select('name_bn').eq('number', row.surah).single();
  return {
    ar: (ayahWords as { arabic: string }[]).map(w => w.arabic).join(' '),
    answer: wordArabic,
    surahName: (surahRow as { name_bn: string } | null)?.name_bn ?? '',
    ayahNumber: row.ayah,
  };
}

// ── Lesson title helpers ─────────────────────────────────────────────────────

function getLessonTitle(unitType: UnitType, surahNameBn: string, lessonIndex: number): string {
  switch (unitType) {
    case 'salah':
    case 'juz_amma':   return `সূরা ${surahNameBn}`;
    case 'azkaar':     return AZKAAR_LESSONS[lessonIndex]?.title_bn ?? `আযকার পাঠ ${lessonIndex + 1}`;
    case 'frequent':   return `শীর্ষ শব্দ — পাঠ ${lessonIndex + 1} (${lessonIndex * 20 + 1}–${lessonIndex * 20 + 20})`;
    case 'attributes': return ATTRIBUTE_PASSAGES[lessonIndex]?.titleBn ?? `গুণাবলী পাঠ ${lessonIndex + 1}`;
    case 'verbs':      return `ক্রিয়াপদ পাঠ ${lessonIndex + 1}`;
    case 'particles':  return `হারফ মাস্টারি — পাঠ ${lessonIndex + 1}`;
    case 'pronouns':   return `সর্বনাম পাঠ ${lessonIndex + 1}`;
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
{"type":"ayah_complete","sort_order":N,"prompt_bn":"আয়াতের শূন্যস্থান পূরণ করুন:","correct_answer":{"sentence":"AYAH_TEXT_WITH_ONE_WORD_REPLACED_BY____","answer":"W","surah_name":"X","ayah_number":N},"distractors":{"options":["w1","w2","w3"]},"difficulty":2}
{"type":"ayah_order","sort_order":N,"prompt_bn":"আয়াতের শব্দগুলো সঠিক ক্রমে সাজান:","correct_answer":{"words":["w1","w2","w3","..."],"correct":"w1 w2 w3 ...","surah_name":"X","ayah_number":N},"difficulty":2}
{"type":"pattern_match","sort_order":N,"prompt_bn":"কোন ছাঁচে (وزن) এই শব্দটি?","prompt_ar":"WORD","correct_answer":{"word_ar":"WORD","root":"غ-ف-ر","pattern":"فَعِيلٌ","pattern_meaning_bn":"অতিশয়ার্থক বিশেষণ — যে গুণ স্থায়ী ও পূর্ণ","siblings":["قَدِيرٌ","شَكُورٌ"]},"distractors":{"options":["فَاعِلٌ","مَفْعُولٌ","فَعَّالٌ"]},"grammar_note_bn":"...","difficulty":2}

RULES: Arabic always with full harakat (تشكيل). ayah_ar/highlighted_word/blank_word EXACT from provided texts. root_family: 3 words from stated root + 1 odd. aqeedah_true: test ta'wil or tashbih errors (is_correct usually false). grammar_spot: exactly 1 correct pos match among 4 words. ayah_complete/ayah_order: sentence/words/correct MUST be copied EXACTLY (verbatim, full harakat) from the আয়াত block given in the prompt — NEVER reconstruct ayah text from memory. surah_name is the Bangla surah name WITHOUT the word "সূরা" prefix (the app adds it). pattern_match: root MUST be hyphen-separated root letters (e.g. "غ-ف-ر"); pattern is the wazn of word_ar with full harakat (e.g. "فَعِيلٌ"); the wazn-letters correspondence MUST be linguistically correct — if unsure of a word's wazn, pick a different word from the list; siblings = 2 other real words sharing the same wazn (NOT necessarily the same root); distractors.options = 3 other wazn strings from {فَاعِلٌ، مَفْعُولٌ، فَعَّالٌ، تَفْعِيلٌ} excluding the correct pattern. Return ONLY valid JSON array.`;

const VERB_EXERCISE_SYSTEM_PROMPT = `Quranic Arabic curriculum designer for Bengali-speaking Muslims. This lesson teaches verb ROOT FAMILIES.

SCHEMAS:
{"type":"grammar_spot","sort_order":N,"prompt_bn":"কোনটি ক্রিয়াপদ (فِعْلٌ)?","correct_answer":{"target_pos_ar":"فِعْلٌ","target_pos_bn":"ক্রিয়াপদ","words":[{"arabic":"V","meaning_bn":"M","pos":"verb"},{"arabic":"W2","meaning_bn":"M2","pos":"noun"},{"arabic":"W3","meaning_bn":"M3","pos":"noun"},{"arabic":"W4","meaning_bn":"M4","pos":"particle"}],"correct_index":0},"difficulty":2}
{"type":"root_family","sort_order":N,"prompt_bn":"কোন শব্দটি ধাতু X-এর নয়?","correct_answer":{"root_ar":"X-Y-Z","root_meaning_bn":"BN","words":[{"arabic":"W","meaning_bn":"M"},{"arabic":"W2","meaning_bn":"M2"},{"arabic":"W3","meaning_bn":"M3"},{"arabic":"ODD","meaning_bn":"M4"}],"odd_index":3},"grammar_note_bn":"...","difficulty":2}
{"type":"multiple_choice","sort_order":N,"prompt_bn":"«VERB» কোন ধাতু থেকে?","prompt_ar":"VERB","correct_answer":{"options":["root","w1","w2","w3"],"correct_index":0},"grammar_note_bn":"...","difficulty":2}
{"type":"drag_drop","sort_order":N,"prompt_bn":"ধাতু «ROOT» — মেলাও:","correct_answer":{"pairs":[{"ar":"V1","bn":"M1"},{"ar":"V2","bn":"M2"},{"ar":"V3","bn":"M3"}]},"grammar_note_bn":"...","difficulty":2}
{"type":"fill_in_blank","sort_order":N,"prompt_bn":"সঠিক ক্রিয়া বসাও (অর্থ:HINT):","correct_answer":{"sentence":"AR ___ REST","blank_index":N,"answer":"VERB"},"distractors":{"options":["w1","w2"]},"grammar_note_bn":"...","difficulty":3}
{"type":"speak_arabic","sort_order":N,"prompt_bn":"বলুন:","correct_answer":{"expected_ar":"VERB","transliteration":"latin","meaning_bn":"BN"},"grammar_note_bn":"...","difficulty":2}
{"type":"pattern_match","sort_order":N,"prompt_bn":"কোন ছাঁচে (وزن) এই শব্দটি?","prompt_ar":"WORD","correct_answer":{"word_ar":"WORD","root":"غ-ف-ر","pattern":"فَعِيلٌ","pattern_meaning_bn":"অতিশয়ার্থক বিশেষণ — যে গুণ স্থায়ী ও পূর্ণ","siblings":["قَدِيرٌ","شَكُورٌ"]},"distractors":{"options":["فَاعِلٌ","مَفْعُولٌ","فَعَّالٌ"]},"grammar_note_bn":"...","difficulty":2}

RULES: All Arabic with full harakat. grammar_note_bn explains verb form/tense/root pattern. pattern_match: root MUST be hyphen-separated root letters (e.g. "غ-ف-ر"); pattern is the wazn of word_ar with full harakat (e.g. "فَعِيلٌ"); the wazn-letters correspondence MUST be linguistically correct — if unsure of a word's wazn, pick a different word from the list; siblings = 2 other real words sharing the same wazn; distractors.options = 3 other wazn strings from {فَاعِلٌ، مَفْعُولٌ، فَعَّالٌ، تَفْعِيلٌ} excluding the correct pattern. Return ONLY valid JSON array.`;

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
  groundedAyahComplete: GroundedAyah | null;
  groundedAyahOrder: GroundedAyah | null;
}): string {
  const { unitType, surahRow, surahNumber, lessonIndex, verbRoots, exWords, ayahTexts, tafsirSnippets, passageTitleBn, groundedAyahComplete, groundedAyahOrder } = opts;
  const wordList = exWords.map((w, i) => `${i + 1}. ${w.arabic} (${w.transliteration ?? '?'}) = ${w.meaning_bn}`).join('\n');
  const ayahsBlock = formatAyahsForPrompt(ayahTexts, tafsirSnippets);

  // Authentic-ayah grounding blocks/instructions for ayah_complete + ayah_order
  const completeBlock = groundedAyahComplete
    ? `\nআয়াত (ayah_complete-এর জন্য, EXACT কপি করুন):\n"${groundedAyahComplete.ar}" — সূরা ${groundedAyahComplete.surahName}, আয়াত ${groundedAyahComplete.ayahNumber}\n(এই আয়াতে শব্দ "${groundedAyahComplete.answer}" আছে)`
    : '';
  const orderBlock = groundedAyahOrder
    ? `\nআয়াত (ayah_order-এর জন্য, EXACT কপি করুন):\n"${groundedAyahOrder.ar}" — সূরা ${groundedAyahOrder.surahName}, আয়াত ${groundedAyahOrder.ayahNumber}`
    : '';
  const completeInstruction = (idx: string) => groundedAyahComplete
    ? `${idx}: ayah_complete — উপরের ayah_complete আয়াত থেকে EXACT কপি করুন; sentence-এ শব্দ "${groundedAyahComplete.answer}"-কে ___ দিয়ে প্রতিস্থাপন করুন (বাকি আয়াত অপরিবর্তিত); answer="${groundedAyahComplete.answer}"; surah_name="${groundedAyahComplete.surahName}"; ayah_number=${groundedAyahComplete.ayahNumber}; distractors.options = শব্দ তালিকা থেকে ৩টি ভিন্ন আরবি শব্দ`
    : '';
  const orderInstruction = (idx: string) => groundedAyahOrder
    ? `${idx}: ayah_order — উপরের ayah_order আয়াত থেকে EXACT কপি করুন; words array-তে প্রতিটি শব্দ আলাদা element হিসেবে আয়াতের ক্রমানুসারে রাখুন; correct = সম্পূর্ণ আয়াত স্পেস দিয়ে যুক্ত (EXACT); surah_name="${groundedAyahOrder.surahName}"; ayah_number=${groundedAyahOrder.ayahNumber}`
    : '';
  const groundingRule = (groundedAyahComplete || groundedAyahOrder)
    ? '\n\nSTRICT RULE: ayah_complete এর sentence ও ayah_order এর words/correct অবশ্যই উপরে দেওয়া আয়াত থেকে EXACT (verbatim, harakat সহ) কপি করুন — কখনো স্মৃতি থেকে আয়াত পুনর্গঠন করবেন না।'
    : '';

  switch (unitType) {

    case 'azkaar': {
      const lesson = AZKAAR_LESSONS[lessonIndex];
      return `পাঠ: ${lesson.title_bn}
যিকর: ${lesson.full_text_ar}
বাংলা অর্থ: ${lesson.full_text_bn}
কখন পড়া হয়: ${lesson.recite_when}
সূত্র: ${lesson.source_bn}

শব্দ তালিকা (শুধু এই শব্দগুলো ব্যবহার করুন, নতুন কিছু বানাবেন না):
${wordList}

IMPORTANT: Output exercises in EXACTLY this order (৯টি):
1st: ayah_read — ayah_ar=EXACTLY "${lesson.full_text_ar}", ayah_bn="${lesson.full_text_bn}", surah_name="${lesson.title_bn}", ayah_number=${lessonIndex + 1}, context_bn="${lesson.recite_when}"
2nd: tafsir_read — surah_name="${lesson.title_bn}", revelation="মাক্কী", theme_bn="এই যিকরে বান্দা আল্লাহকে কী বলছে", aqeedah_bn="সালাফী আকিদা অনুযায়ী এই যিকরের তাৎপর্য", tafsir_bn="ইবনু সা'দী বা ইবনু উসাইমীন পদ্ধতিতে ২–৩ বাক্যে এই যিকরের ব্যাখ্যা"
3rd: reflection_card — reflection_prompt="পরের সালাতে ${lesson.title_bn} পড়ার সময় এই অর্থ মনে রাখুন: কোন শব্দটি আজ আপনার হৃদয় স্পর্শ করল?", scholarly_note_bn="ইবনু উসাইমীন বা ইবনুল কাইয়্যিম — খুশু সম্পর্কে একটি উক্তি"
4th: multiple_choice — শব্দ তালিকা থেকে একটি শব্দের অর্থ জিজ্ঞেস করুন
5th: multiple_choice — শব্দ তালিকা থেকে আরেকটি শব্দের অর্থ জিজ্ঞেস করুন
6th: drag_drop — শব্দ তালিকা থেকে ৩ জোড়া আরবি-বাংলা মেলানো
7th: fill_in_blank — যিকরের ভেতর একটি শব্দ বাদ দিয়ে শূন্যস্থান তৈরি করুন; sentence-এ EXACT Arabic, blank_word শব্দ তালিকা থেকে
8th: tap_to_build — যিকরের একটি ছোট অংশ সাজানো; words: প্রতিটি আরবি শব্দ আলাদা element, distractor_words: ১–২টি ভুল শব্দ যা তালিকায় আছে; correct_answer.words=["w1","w2","w3",...]
9th: speak_arabic — expected_ar=যিকরের একটি সম্পূর্ণ বাক্য বা ছোট অংশ; meaning_bn=এর অর্থ

STRICT RULES:
- ONLY use Arabic words that appear in the provided word list or in the full_text_ar above.
- Do NOT invent Arabic words not in the list.
- tap_to_build words array: each element is ONE Arabic word (no multi-word elements).
- All Arabic with full harakat.
Return valid JSON array only.`;
    }

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
${orderBlock}

IMPORTANT: Output exercises in EXACTLY this order in the JSON array (first item = first exercise shown to learner):
1st: ayah_read — ayah_ar=EXACTLY "${firstAyahAr}", ayah_bn=বাংলা অনুবাদ, surah_name="সূরা ${surahRow?.name_bn}", ayah_number=${firstAyahNum}, context_bn="${salahCtx}"
2nd: tafsir_read — revelation+theme_bn+aqeedah_bn+tafsir_bn (ইবনু সা'দী, ২ বাক্য)
3rd: ayah_cloze — blank one lesson word from the first ayah above, 4 Arabic options (correct_index:0 first)
4th: ayah_context — highlight one lesson word inside the same ayah, 4 Bengali meaning options
5th: reflection_card — tadabbur prompt: what does this ayah mean when you recite it in Salah? Include a scholarly note (Ibn Sa'di or Ibn Uthaymin)
${orderInstruction('6th')}
${groundedAyahOrder ? '7th' : '6th'}: speak_arabic — a lesson word to pronounce
${groundingRule}
Return JSON array only.`;
    }

    case 'juz_amma': {
      const ayahCount = ayahTexts.size;
      // Scale ayah_read count to surah length
      const numAyahReads = ayahCount <= 5 ? 1 : ayahCount <= 19 ? 2 : 3;
      const totalEx = 4 + numAyahReads; // tafsirRead + ayahReads + surahTheme + ayahCloze + ayahContext + speakArabic
      const ayahEntries = [...ayahTexts.entries()];
      const ayahReadLines = ayahEntries.slice(0, numAyahReads).map(([key, ar], i) => {
        const ayahNum = parseInt(key.split(':')[1]);
        return `${i + 2}th: ayah_read — ayah_ar=EXACTLY "${ar}", ayah_bn=বাংলা অনুবাদ, surah_name="সূরা ${surahRow?.name_bn ?? ''}", ayah_number=${ayahNum}, context_bn=এই আয়াতের প্রেক্ষাপট`;
      }).join('\n');
      const clozeAyahKey = ayahEntries[0]?.[0] ?? `${surahNumber}:1`;
      const clozeAyahNum = parseInt(clozeAyahKey.split(':')[1]);
      const clozeAyahAr = ayahTexts.get(clozeAyahKey) ?? '';
      const themeSlot = numAyahReads + 2;
      const clozeSlot = numAyahReads + 3;
      const contextSlot = numAyahReads + 4;
      const orderSlot = numAyahReads + 5;
      const speakSlot = numAyahReads + (groundedAyahOrder ? 6 : 5);
      return `সূরা: ${surahRow?.name_bn} (${surahRow?.name_ar}) #${surahNumber} | আয়াত সংখ্যা: ${ayahCount}
নাযিল: ${surahRow?.revelation ?? 'মাক্কী'}

আয়াত (EXACT for ayah_read/ayah_context/ayah_cloze):
${ayahsBlock}

শব্দ (${exWords.length}):
${wordList}
${orderBlock}

IMPORTANT: Output exercises in EXACTLY this order (${totalEx + (groundedAyahOrder ? 1 : 0)}টি):
1st: tafsir_read — revelation+theme_bn+aqeedah_bn+tafsir_bn (ইবনু সা'দী, ২ বাক্য)
${ayahReadLines}
${themeSlot}th: surah_theme — প্রধান বিষয় ৪ অপশন
${clozeSlot}th: ayah_cloze — ayah_ar=EXACTLY "${clozeAyahAr}", ayah_number=${clozeAyahNum}, blank one lesson word, 4 Arabic options (correct_index:0 first)
${contextSlot}th: ayah_context — প্রথম আয়াত থেকে ১ শব্দ হাইলাইট — ৪ অপশন
${orderInstruction(`${orderSlot}th`)}
${speakSlot}th: speak_arabic — a lesson word to pronounce
${groundingRule}
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

IMPORTANT: Output exercises in EXACTLY this order (৯টি):
1st: ayah_read — ayah_ar=EXACTLY "${firstAyahAr}", ayah_bn=অনুবাদ, surah_name=উপযুক্ত_সূরা, ayah_number=${firstAyahNum}, context_bn="এই আয়াতে আল্লাহর নাম ও গুণাবলী"
2nd: reflection_card — এই নামগুলোর athar (মুমিনের হৃদয়ে প্রভাব) — ইবনু উসাইমীন পদ্ধতিতে ব্যক্তিগত প্রশ্ন
3rd: aqeedah_true — সঠিক বক্তব্য (is_correct:true) — এই পাঠের নামগুলো সম্পর্কে
4th: aqeedah_true — ta'wil বা tashbih ভুল বক্তব্য (is_correct:false)
5th: multiple_choice — নাম → অর্থ
6th: multiple_choice — নাম → অর্থ
7th: pattern_match — এই পাঠের একটি নাম (اسم) এর وزن (ছাঁচ) চিনুন
8th: drag_drop — 3 নাম-অর্থ জোড়া
9th: speak_arabic — একটি নাম উচ্চারণ

Return JSON array only.`;
    }

    case 'frequent': {
      const start = lessonIndex * 20 + 1;
      return `পাঠ ${lessonIndex + 1} — কুরআনের শীর্ষ ব্যবহৃত শব্দ #${start}–${start + 19}

শব্দ তালিকা:
${wordList}
${completeBlock}${orderBlock}

IMPORTANT: Output exercises in EXACTLY this order (${groundedAyahOrder ? '১০' : '৯'}টি):
1st: root_family — শব্দ তালিকা থেকে একটি ধাতু বেছে — ৩টি সেই ধাতু থেকে + ১টি ভিন্ন ধাতুর (odd_index=3)
2nd: grammar_spot — ৪টি শব্দ — একটি فعل, একটি حرف, দুটি اسم
3rd: multiple_choice — শব্দ → অর্থ
4th: multiple_choice — শব্দ → অর্থ
5th: ayah_context — শব্দ তালিকার একটি শব্দ Quranic ayah থেকে highlight করুন
6th: tafsir_read — এই পাঠের শব্দগুলো যে সূরায় বেশি পাওয়া যায় সেই সূরার সংক্ষিপ্ত পরিচিতি — revelation+theme_bn+aqeedah_bn+tafsir_bn (ইবনু সা'দী পদ্ধতিতে, ২ বাক্য)
7th: drag_drop — 3 শব্দ-অর্থ জোড়া
${groundedAyahComplete ? completeInstruction('8th') : '8th: fill_in_blank — বাক্যে শূন্যস্থান পূরণ'}
${orderInstruction('9th')}
${groundedAyahOrder ? '10th' : '9th'}: speak_arabic — একটি শব্দ উচ্চারণ
${groundingRule}
Return valid JSON array only.`;
    }

    case 'verbs': {
      return `ক্রিয়া ধাতু: ${verbRoots.map(r => r.root).join(', ')}
ধাতু পরিবার:
${verbRoots.map(r => `• ${r.root}: ${r.forms.slice(0, 4).join(', ')}`).join('\n')}

শব্দ তালিকা:
${wordList}

IMPORTANT: Output exercises in EXACTLY this order (৮টি):
1st: grammar_spot — ৪টি শব্দ — কোনটি فعل? (ক্রিয়াপদ)
2nd: root_family — একটি ধাতু থেকে ৩টি ক্রিয়ারূপ + ১টি ভিন্ন ধাতুর শব্দ (odd_index=3)
3rd: pattern_match — এই পাঠের একটি ক্রিয়া বা শব্দের وزن (ছাঁচ) চিনুন
4th: multiple_choice — ক্রিয়া → ধাতু চিনুন
5th: multiple_choice — ক্রিয়া → ধাতু চিনুন
6th: drag_drop — ধাতু পরিবার মেলানো (3 pairs)
7th: drag_drop — ধাতু পরিবার মেলানো (3 pairs)
8th: speak_arabic — একটি ক্রিয়াপদ উচ্চারণ

Return valid JSON array only.`;
    }

    case 'particles': {
      return `হারফ (অব্যয়) তালিকা — এই পাঠে শুধু এই হরফগুলো নিয়ে কাজ করুন:
${wordList}

IMPORTANT: Output exercises in EXACTLY this order (৮টি):
1st: grammar_spot — target_pos_ar="حَرْفٌ", target_pos_bn="হরফ (অব্যয়)" — words: ৪টি শব্দ যার মধ্যে ১টি শব্দ তালিকা থেকে حَرْفٌ (pos:"particle"), বাকি ৩টি ভিন্ন اسم/فعل শব্দ (pos:"noun"/"verb"); correct_index = حرف এর অবস্থান
2nd: ayah_context — শব্দ তালিকার একটি হরফ একটি প্রকৃত কুরআনের আয়াতে হাইলাইট করুন — ayah_ar=EXACT প্রকৃত আয়াত যেখানে এই হরফ আছে, highlighted_word=সেই হরফ, ৪টি বাংলা অর্থ অপশন
3rd: multiple_choice — শব্দ তালিকা থেকে একটি হরফের অর্থ জিজ্ঞেস করুন
4th: multiple_choice — শব্দ তালিকা থেকে আরেকটি হরফের অর্থ জিজ্ঞেস করুন
5th: drag_drop — শব্দ তালিকা থেকে ৩টি হরফ-অর্থ জোড়া মেলানো
6th: fill_in_blank — একটি প্রকৃত কুরআনের আয়াতাংশ থেকে এই হরফটি বাদ দিয়ে শূন্যস্থান তৈরি করুন; sentence-এ EXACT আয়াতাংশ (___ সহ), answer=হরফ, distractors.options=অন্য ১-২টি হরফ
7th: tap_to_build — শব্দ তালিকার ২-৩টি হরফ সহ একটি ছোট প্রকৃত আয়াতাংশ সাজানো; correct_answer.words=প্রতিটি আরবি শব্দ আলাদা element
8th: speak_arabic — শব্দ তালিকা থেকে একটি হরফ উচ্চারণ

STRICT RULES:
- ayah_ar এবং sentence-এর আয়াতাংশ অবশ্যই কুরআনের প্রকৃত (authentic) আয়াত হতে হবে, বানানো নয়।
- Arabic always with full harakat (تشكيل).
Return valid JSON array only.`;
    }

    case 'pronouns': {
      return `সর্বনাম ও যুক্ত সর্বনাম তালিকা — এই পাঠে শুধু এই শব্দগুলো নিয়ে কাজ করুন:
${wordList}

IMPORTANT: Output exercises in EXACTLY this order (৮টি):
1st: grammar_spot — target_pos_ar="ضَمِيرٌ", target_pos_bn="সর্বনাম" — words: ৪টি শব্দ যার মধ্যে ১টি শব্দ তালিকা থেকে ضَمِيرٌ (pos:"pronoun"), বাকি ৩টি ভিন্ন اسم/فعل/حرف শব্দ; correct_index = সর্বনামের অবস্থান
2nd: ayah_context — শব্দ তালিকার একটি সর্বনাম একটি প্রকৃত কুরআনের আয়াতে হাইলাইট করুন — ayah_ar=EXACT প্রকৃত আয়াত, highlighted_word=সেই সর্বনাম, ৪টি বাংলা অর্থ অপশন
3rd: multiple_choice — শব্দ তালিকা থেকে একটি সর্বনামের অর্থ জিজ্ঞেস করুন
4th: multiple_choice — শব্দ তালিকা থেকে আরেকটি সর্বনামের অর্থ জিজ্ঞেস করুন
5th: drag_drop — শব্দ তালিকা থেকে ৩টি সর্বনাম-অর্থ জোড়া মেলানো
6th: fill_in_blank — একটি প্রকৃত কুরআনের আয়াতাংশ থেকে একটি যুক্ত সর্বনাম-সহ শব্দ বাদ দিয়ে শূন্যস্থান তৈরি করুন; sentence-এ EXACT আয়াতাংশ (___ সহ), answer=শব্দটি, distractors.options=অন্য ১-২টি শব্দ
7th: tap_to_build — যুক্ত সর্বনামযুক্ত একটি শব্দকে ভেঙে অংশ সাজানো (যেমন رَبُّ + كُمْ); correct_answer.words=প্রতিটি অংশ আলাদা element
8th: speak_arabic — শব্দ তালিকা থেকে একটি সর্বনাম উচ্চারণ

STRICT RULES:
- যুক্ত সর্বনামযুক্ত প্রতিটি শব্দের grammar_note_bn অবশ্যই শব্দটি ভেঙে দেখাবে এই ফরম্যাটে: "رَبُّكُمْ = رَبُّ (রব) + كُمْ (তোমাদের)"
- এছাড়া এমন একটি শব্দের grammar_note_bn-এ এই বাংলা ব্যাখ্যাও যোগ করুন: "যুক্ত সর্বনাম (Attached Pronoun) বাংলার বিভক্তির মতো শব্দের শেষে যুক্ত হয় — যেমন বাংলায় 'তোমাদের' শব্দে '-দের' যুক্ত হয়, তেমনি আরবিতে 'كُمْ' যুক্ত হয়ে 'তোমাদের' অর্থ তৈরি করে।"
- ayah_ar এবং sentence-এর আয়াতাংশ অবশ্যই কুরআনের প্রকৃত (authentic) আয়াত হতে হবে, বানানো নয়।
- Arabic always with full harakat (تشكيل).
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
    if (unitType === 'azkaar' && (lessonIndex < 0 || lessonIndex >= AZKAAR_LESSONS.length)) {
      return new Response(JSON.stringify({ error: `lesson_index must be 0–${AZKAAR_LESSONS.length - 1} for azkaar` }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
    if (unitType === 'particles' && (lessonIndex < 0 || lessonIndex > 3)) {
      return new Response(JSON.stringify({ error: 'lesson_index must be 0–3 for particles' }), {
        status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
    if (unitType === 'pronouns' && (lessonIndex < 0 || lessonIndex > 2)) {
      return new Response(JSON.stringify({ error: 'lesson_index must be 0–2 for pronouns' }), {
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

    } else if (unitType === 'azkaar') {
      // Words come from the static data file — no DB query needed.
      const lesson = AZKAAR_LESSONS[lessonIndex];
      words = lesson.words.map(w => ({ arabic: w.arabic, meaning_bn: w.meaning_bn }));

    } else if (unitType === 'verbs') {
      verbRoots = await fetchVerbRoots(sb, lessonIndex);
      words     = await verbRootsToWords(sb, verbRoots);
      if (words.length < 2) return new Response(JSON.stringify({ error: 'Too few verb forms — run enrich_quran_roots.ts first' }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });

    } else if (unitType === 'particles') {
      words = await fetchParticleWords(sb, lessonIndex);
      if (words.length === 0) return new Response(JSON.stringify({ error: 'No particle words found — check get_quran_particles' }), {
        status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });

    } else if (unitType === 'pronouns') {
      words = await fetchPronounWords(sb, lessonIndex);
      if (words.length === 0) return new Response(JSON.stringify({ error: 'No pronoun words found — check get_quran_pronoun_words' }), {
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
    // For azkaar, seed grammar_note_bn from the hand-curated context_bn field.
    let enrichedWords: EnrichedWord[] = unitType === 'azkaar'
      ? AZKAAR_LESSONS[lessonIndex].words.map(w => ({
          arabic: w.arabic, meaning_bn: w.meaning_bn,
          transliteration: null, meaning_en: null, grammar_note_bn: w.context_bn,
        }))
      : words.map(w => ({ ...w, transliteration: null, meaning_en: null, grammar_note_bn: null }));

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
        word_type:          unitType === 'verbs' ? 'verb' : unitType === 'particles' ? 'particle' : 'noun',
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

    // ── 10b. Ground ayah_complete / ayah_order in a real, short ayah ────────
    let groundedAyahComplete: GroundedAyah | null = null;
    let groundedAyahOrder: GroundedAyah | null = null;
    if (unitType === 'salah' || unitType === 'juz_amma') {
      const surahWords = words as (WordRow & { ayah?: number })[];
      groundedAyahComplete = findGroundedAyah(surahWords, ayahTexts, surahNumber, surahRow?.name_bn ?? '', 12);
      groundedAyahOrder = findGroundedAyah(
        surahWords, ayahTexts, surahNumber, surahRow?.name_bn ?? '', 7,
        groundedAyahComplete?.ayahNumber,
      );
    } else if (unitType === 'frequent') {
      for (const w of exWords) {
        if (!groundedAyahComplete) groundedAyahComplete = await fetchShortAyahForWord(sb, w.arabic, 12);
        if (groundedAyahComplete && !groundedAyahOrder) {
          const candidate = await fetchShortAyahForWord(sb, w.arabic, 7);
          if (candidate && candidate.ar !== groundedAyahComplete.ar) groundedAyahOrder = candidate;
        }
        if (groundedAyahComplete && groundedAyahOrder) break;
      }
    }

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
          groundedAyahComplete,
          groundedAyahOrder,
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
          'ayah_complete','ayah_order','pattern_match',
        ]);
        const toSnake = (s: string) => s.replace(/([A-Z])/g, m => `_${m.toLowerCase()}`);

        // Normalise type names, drop unknown types.
        const normalised = exercises
          .map(ex => ({ ...ex, type: toSnake(ex.type as string) }))
          .filter(ex => VALID_TYPES.has(ex.type as string));

        if (normalised.length === 0) {
          throw new Error(`No valid exercise types — Gemini returned: ${exercises.map(e => e.type).join(', ')}`);
        }

        // Enforce the pedagogical sequence regardless of what order Gemini outputs.
        // Gemini consistently reverses the array, so we re-sort by a hardcoded type priority.
        // Types appearing multiple times (e.g. 2×multiple_choice) keep stable relative order.
        const TYPE_PRIORITY: Record<string, number> = {
          salah: {
            ayah_read: 0, tafsir_read: 1, ayah_cloze: 2,
            ayah_context: 3, reflection_card: 4, ayah_order: 5, speak_arabic: 6,
          },
          azkaar: {
            ayah_read: 0, tafsir_read: 1, reflection_card: 2,
            multiple_choice: 3, drag_drop: 5, fill_in_blank: 6,
            tap_to_build: 7, speak_arabic: 8,
          },
          juz_amma: {
            tafsir_read: 0, ayah_read: 1, surah_theme: 3,
            ayah_cloze: 4, ayah_context: 5, ayah_order: 6, speak_arabic: 7,
          },
          attributes: {
            ayah_read: 0, reflection_card: 1, aqeedah_true: 2,
            multiple_choice: 4, pattern_match: 5, drag_drop: 6, speak_arabic: 7,
          },
          frequent: {
            root_family: 0, grammar_spot: 1, multiple_choice: 2,
            ayah_context: 4, tafsir_read: 5, drag_drop: 6,
            fill_in_blank: 7, ayah_complete: 7, ayah_order: 8, speak_arabic: 9,
          },
          verbs: {
            grammar_spot: 0, root_family: 1, pattern_match: 2, multiple_choice: 3,
            drag_drop: 5, speak_arabic: 7,
          },
          particles: {
            grammar_spot: 0, ayah_context: 1, multiple_choice: 2,
            drag_drop: 4, fill_in_blank: 5, tap_to_build: 6, speak_arabic: 7,
          },
          pronouns: {
            grammar_spot: 0, ayah_context: 1, multiple_choice: 2,
            drag_drop: 4, fill_in_blank: 5, tap_to_build: 6, speak_arabic: 7,
          },
        }[unitType] ?? {};

        // Stable sort: unknown types fall to end, ties keep original relative order.
        const validExercises = normalised
          .map((ex, i) => ({ ex, origIdx: i }))
          .sort((a, b) => {
            const pa = TYPE_PRIORITY[a.ex.type as string] ?? 99;
            const pb = TYPE_PRIORITY[b.ex.type as string] ?? 99;
            return pa !== pb ? pa - pb : a.origIdx - b.origIdx;
          })
          .map(({ ex }) => ex);

        // Insert one-by-one so a single bad exercise never kills the whole batch.
        const insertErrors: string[] = [];
        for (let idx = 0; idx < validExercises.length; idx++) {
          const ex = validExercises[idx];
          const rawDiff = ex.difficulty as number | undefined | null;
          const clampedDiff = Math.max(1, Math.min(5, (rawDiff != null && rawDiff > 0) ? rawDiff : 1));
          const { error: exErr } = await sb.from('exercises').insert({
            lesson_id:       lessonId,
            type:            ex.type,
            sort_order:      idx + 1,   // always use insertion index; ignore Gemini's sort_order
            prompt_bn:       ex.prompt_bn ?? null,
            prompt_ar:       (ex.prompt_ar as string | undefined) ?? null,
            correct_answer:  ex.correct_answer ?? {},
            distractors:     (ex.distractors as unknown) ?? null,
            grammar_note_bn: (ex.grammar_note_bn as string | undefined) ?? null,
            difficulty:      clampedDiff,
          });
          if (exErr) {
            insertErrors.push(`[${ex.type}] ${exErr.message}`);
            console.error(`Exercise insert failed for type=${ex.type}:`, exErr.message);
          } else {
            exerciseCount++;
          }
        }
        if (insertErrors.length > 0 && exerciseCount === 0) {
          throw new Error(`All exercises failed: ${insertErrors.join(' | ')}`);
        }
        if (insertErrors.length > 0) {
          exerciseError = `Partial insert — ${exerciseCount}/${validExercises.length} ok. Errors: ${insertErrors.join(' | ')}`;
        }
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
