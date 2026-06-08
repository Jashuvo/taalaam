// seed_quran_track.ts — Seeds 3 curriculum units in the quranic track.
// Usage:
//   SUPABASE_URL=https://xxx.supabase.co \
//   SUPABASE_SERVICE_ROLE_KEY=eyJ... \
//   GEMINI_API_KEY=AIza... \
//   deno run --allow-net --allow-env tools/seed_quran_track.ts

const SUPA_URL = Deno.env.get('SUPABASE_URL');
const SUPA_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
const GEMINI_KEY = Deno.env.get('GEMINI_API_KEY');

if (!SUPA_URL || !SUPA_KEY) {
  console.error('❌  Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars.');
  Deno.exit(1);
}
if (!GEMINI_KEY) {
  console.warn('⚠  GEMINI_API_KEY not set — will skip transliteration and exercises.');
}

// ── REST helpers ──────────────────────────────────────────────────────────────

const authHeaders = {
  Authorization: `Bearer ${SUPA_KEY}`,
  apikey: SUPA_KEY!,
};

async function dbGet<T>(path: string): Promise<T[]> {
  const res = await fetch(`${SUPA_URL}/rest/v1/${path}`, { headers: authHeaders });
  if (!res.ok) throw new Error(`GET ${path}: ${res.status} ${await res.text()}`);
  return res.json() as Promise<T[]>;
}

async function dbPost<T>(path: string, body: unknown, prefer = 'resolution=merge-duplicates,return=representation'): Promise<T[]> {
  const res = await fetch(`${SUPA_URL}/rest/v1/${path}`, {
    method: 'POST',
    headers: { ...authHeaders, 'Content-Type': 'application/json', Prefer: prefer },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`POST ${path}: ${res.status} ${text}`);
  return text ? JSON.parse(text) : [];
}

async function dbDelete(path: string): Promise<void> {
  await fetch(`${SUPA_URL}/rest/v1/${path}`, { method: 'DELETE', headers: authHeaders });
}

// ── Gemini ────────────────────────────────────────────────────────────────────

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'];

async function gemini(prompt: string): Promise<string> {
  if (!GEMINI_KEY) throw new Error('GEMINI_API_KEY not set');
  let lastErr = '';
  for (const model of GEMINI_MODELS) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_KEY}`,
        { method: 'POST', headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] }) },
      );
      if (!res.ok) { lastErr = await res.text(); continue; }
      const d = await res.json();
      return d?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
    } catch (e) { lastErr = (e as Error).message; }
  }
  throw new Error(`All Gemini models failed: ${lastErr}`);
}

function stripFences(s: string): string {
  return s.trim().replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
}

// ── DB helpers ────────────────────────────────────────────────────────────────

async function ensureTrack(): Promise<string> {
  const rows = await dbPost<{ id: string }>('tracks', {
    slug: 'quranic',
    name_ar: 'الْعَرَبِيَّةُ الْقُرْآنِيَّةُ',
    name_bn: 'কুরআনিক আরবি',
    name_en: 'Quranic Arabic',
    description_bn: 'কুরআনের শব্দ দিয়ে আরবি শিখুন — সালাত থেকে জুয আম্মা পর্যন্ত',
    sort_order: 2,
  });
  return rows[0].id;
}

async function ensureUnit(
  trackId: string, slug: string, titleBn: string, titleAr: string, sortOrder: number,
): Promise<string> {
  const rows = await dbPost<{ id: string }>('units', {
    track_id: trackId, slug, title_bn: titleBn, title_ar: titleAr,
    sort_order: sortOrder, tier_level: 1, status: 'draft',
  });
  return rows[0].id;
}

async function upsertLesson(
  unitId: string, titleBn: string, sortOrder: number, level: string,
): Promise<string> {
  const existing = await dbGet<{ id: string }>(
    `lessons?unit_id=eq.${unitId}&title_bn=eq.${encodeURIComponent(titleBn)}&select=id`,
  );
  if (existing.length > 0) {
    const lid = existing[0].id;
    await Promise.all([
      dbDelete(`exercises?lesson_id=eq.${lid}`),
      dbDelete(`vocabulary?lesson_id=eq.${lid}`),
    ]);
    return lid;
  }
  const rows = await dbPost<{ id: string }>('lessons', {
    unit_id: unitId, title_bn: titleBn, sort_order: sortOrder, level, status: 'draft',
  }, 'return=representation');
  return rows[0].id;
}

// ── Enrichment ────────────────────────────────────────────────────────────────

type WordRow = { arabic: string; meaning_bn: string; surah: number; ayah: number; position?: number };
type Enriched = { transliteration: string | null; meaning_en: string | null; grammar_note_bn: string | null };

async function enrichWords(words: Pick<WordRow, 'arabic' | 'meaning_bn'>[]): Promise<Map<string, Enriched>> {
  const map = new Map<string, Enriched>();
  if (!GEMINI_KEY || words.length === 0) return map;
  try {
    const list = words.map((w, i) => `${i + 1}. ${w.arabic} = ${w.meaning_bn}`).join('\n');
    const raw = stripFences(await gemini(
      `For each Arabic Quranic word below provide transliteration (Latin phonetic), English meaning (1-3 words), and a one-line Bangla grammar note (type, form, root).
Return JSON array: [{"arabic":"...","transliteration":"...","meaning_en":"...","grammar_note_bn":"..."}].
Only valid JSON, no markdown.

Words:
${list}`,
    ));
    const arr = JSON.parse(raw) as Array<{ arabic: string } & Enriched>;
    for (const e of arr) map.set(e.arabic, { transliteration: e.transliteration, meaning_en: e.meaning_en, grammar_note_bn: e.grammar_note_bn });
  } catch (e) {
    console.warn('  ⚠ Enrichment failed:', (e as Error).message.slice(0, 80));
  }
  return map;
}

async function generateExercises(
  lessonTitleBn: string, words: Pick<WordRow, 'arabic' | 'meaning_bn'>[],
): Promise<Array<Record<string, unknown>>> {
  if (!GEMINI_KEY || words.length === 0) return [];
  const pairs = words.slice(0, 20).map(w => `${w.arabic}=${w.meaning_bn}`).join(', ');
  try {
    const raw = stripFences(await gemini(
      `Quranic Arabic exercises for Bengali Muslims, lesson: ${lessonTitleBn}.
Words (arabic=Bengali): ${pairs}

Generate 8 exercises as JSON array:
- 3 multipleChoice: {"type":"multipleChoice","sort_order":N,"prompt_bn":"«WORD» শব্দের অর্থ কী?","prompt_ar":"WORD","correct_answer":{"options":["correct","wrong1","wrong2","wrong3"],"correct_index":0},"grammar_note_bn":"...","difficulty":1}
- 2 dragDrop: {"type":"dragDrop","sort_order":N,"prompt_bn":"আরবি শব্দের সাথে বাংলা অর্থ মেলাও:","correct_answer":{"pairs":[{"ar":"word","bn":"meaning"},{"ar":"word2","bn":"meaning2"}]},"grammar_note_bn":"...","difficulty":2}
- 1 tapToBuild: {"type":"tapToBuild","sort_order":N,"prompt_bn":"শব্দগুলো সঠিক ক্রমে সাজাও:","correct_answer":{"words":["word1","word2","word3"],"order_matters":true,"distractor_words":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":4}
- 1 fillInBlank: {"type":"fillInBlank","sort_order":N,"prompt_bn":"শূন্যস্থান পূরণ করো:","correct_answer":{"sentence":"Arabic sentence with ___","blank_index":0,"answer":"word"},"distractors":{"options":["wrong1","wrong2"]},"grammar_note_bn":"...","difficulty":3}
- 1 speakArabic: {"type":"speakArabic","sort_order":N,"prompt_bn":"এই শব্দটি বলুন:","correct_answer":{"expected_ar":"word with harakat","transliteration":"...","meaning_bn":"..."},"grammar_note_bn":"...","difficulty":2}
ONLY use words from the provided list. Full harakat on all Arabic. Return JSON array only.`,
    ));
    return JSON.parse(raw) as Array<Record<string, unknown>>;
  } catch (e) {
    console.warn('  ⚠ Exercise generation failed:', (e as Error).message.slice(0, 80));
    return [];
  }
}

// ── Context data ──────────────────────────────────────────────────────────────

async function fetchContext(pairs: { surah: number; ayah: number }[]): Promise<{
  ayahTexts: Map<string, string>;
  tafsirSnippets: Map<string, string>;
}> {
  const ayahTexts = new Map<string, string>();
  const tafsirSnippets = new Map<string, string>();
  const unique = [...new Set(pairs.map(p => `${p.surah}:${p.ayah}`))].slice(0, 10);

  await Promise.all(unique.map(async (key) => {
    const [s, a] = key.split(':');
    const [words, tafsir] = await Promise.all([
      dbGet<{ arabic: string }>(`quran_words?surah=eq.${s}&ayah=eq.${a}&select=arabic&order=position`),
      dbGet<{ tafsir_text: string }>(`quran_tafsir?surah=eq.${s}&ayah=eq.${a}&select=tafsir_text&limit=1`),
    ]);
    if (words.length) ayahTexts.set(key, words.map(w => w.arabic).join(' '));
    if (tafsir.length) tafsirSnippets.set(key, tafsir[0].tafsir_text.slice(0, 120) + '…');
  }));

  return { ayahTexts, tafsirSnippets };
}

async function insertContent(
  lessonId: string,
  lessonTitleBn: string,
  words: WordRow[],
  enrichMap: Map<string, Enriched>,
  ayahTexts: Map<string, string>,
  tafsirSnippets: Map<string, string>,
): Promise<{ vocab: number; exercises: number }> {
  const vocabRows = words.map((w) => {
    const key = `${w.surah}:${w.ayah}`;
    const e = enrichMap.get(w.arabic);
    return {
      lesson_id: lessonId,
      arabic: w.arabic,
      meaning_bn: w.meaning_bn,
      meaning_en: e?.meaning_en ?? null,
      transliteration: e?.transliteration ?? null,
      grammar_note_bn: e?.grammar_note_bn ?? null,
      word_type: 'noun',
      context_snippet_ar: ayahTexts.get(key) ?? null,
      context_snippet_bn: tafsirSnippets.get(key) ?? null,
    };
  });
  if (vocabRows.length > 0) await dbPost('vocabulary', vocabRows, 'return=minimal');

  const exArr = await generateExercises(lessonTitleBn, words);
  if (exArr.length > 0) {
    await dbPost('exercises', exArr.map((ex, idx) => ({
      lesson_id: lessonId,
      type: ex.type,
      sort_order: (ex.sort_order as number) ?? (idx + 1),
      prompt_bn: ex.prompt_bn,
      prompt_ar: (ex.prompt_ar as string | undefined) ?? null,
      correct_answer: ex.correct_answer,
      distractors: (ex.distractors as unknown) ?? null,
      grammar_note_bn: (ex.grammar_note_bn as string | undefined) ?? null,
      difficulty: (ex.difficulty as number) ?? 1,
    })), 'return=minimal');
  }
  return { vocab: vocabRows.length, exercises: exArr.length };
}

function dedup(rows: WordRow[]): WordRow[] {
  const seen = new Set<string>();
  return rows.filter(r => { if (seen.has(r.arabic)) return false; seen.add(r.arabic); return true; });
}

// ── MAIN ──────────────────────────────────────────────────────────────────────

console.log('\n🌿  Seeding Quranic Track...\n');

const trackId = await ensureTrack();
console.log(`✅  Track: quranic (${trackId})`);

let totalLessons = 0, totalVocab = 0, totalExercises = 0;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UNIT 1 — সালাতের ভাষা (Salah Vocabulary)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const unit1Id = await ensureUnit(trackId, 'salah-vocabulary', 'সালাতের ভাষা', 'مُفْرَدَاتُ الصَّلَاةِ', 1);
console.log('\n📚  Unit 1: সালাতের ভাষা');

const salahLessons = [
  { titleBn: 'সূরা আল-ফাতিহা', surahs: [1], sort: 1, level: 'beginner' },
  { titleBn: 'ইখলাস, কাউসার ও নাসর', surahs: [112, 108, 110], sort: 2, level: 'beginner' },
  { titleBn: 'আল-ফালাক ও আন-নাস', surahs: [113, 114], sort: 3, level: 'beginner' },
  { titleBn: 'আল-আসর ও আল-মাউন', surahs: [103, 107], sort: 4, level: 'beginner' },
];

for (const lesson of salahLessons) {
  const surahList = lesson.surahs.join(',');
  const rows = await dbGet<WordRow>(
    `quran_words?surah=in.(${surahList})&meaning_bn=not.is.null&select=arabic,meaning_bn,surah,ayah,position&order=surah,ayah,position`,
  );
  const words = dedup(rows);
  const lessonId = await upsertLesson(unit1Id, lesson.titleBn, lesson.sort, lesson.level);
  const { ayahTexts, tafsirSnippets } = await fetchContext(words.map(w => ({ surah: w.surah, ayah: w.ayah })));
  const enrichMap = await enrichWords(words);
  const { vocab, exercises } = await insertContent(lessonId, lesson.titleBn, words, enrichMap, ayahTexts, tafsirSnippets);
  console.log(`  ✅  L${lesson.sort}: ${lesson.titleBn} — ${vocab} vocab, ${exercises} exercises`);
  totalLessons++; totalVocab += vocab; totalExercises += exercises;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UNIT 2 — সবচেয়ে বেশি ব্যবহৃত শব্দ (Frequent Words)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const unit2Id = await ensureUnit(trackId, 'frequent-words', 'সবচেয়ে বেশি ব্যবহৃত শব্দ', 'أَكْثَرُ الْكَلِمَاتِ تَكْرَارًا', 2);
console.log('\n📚  Unit 2: সবচেয়ে বেশি ব্যবহৃত শব্দ');

// Count word frequencies from full quran_words table
console.log('  📊  Counting frequencies (fetching all words)…');
const allWords = await dbGet<{ arabic: string; meaning_bn: string }>(
  'quran_words?meaning_bn=not.is.null&select=arabic,meaning_bn',
);
const freqMap = new Map<string, { meaning_bn: string; count: number }>();
for (const w of allWords) {
  const prev = freqMap.get(w.arabic);
  if (!prev) freqMap.set(w.arabic, { meaning_bn: w.meaning_bn, count: 1 });
  else prev.count++;
}
const top100 = [...freqMap.entries()]
  .sort((a, b) => b[1].count - a[1].count)
  .slice(0, 100)
  .map(([arabic, { meaning_bn }]) => ({ arabic, meaning_bn }));

// Fetch first occurrence of each top word for context (surah+ayah)
const allWithPos = await dbGet<{ arabic: string; surah: number; ayah: number }>(
  'quran_words?meaning_bn=not.is.null&select=arabic,surah,ayah&order=surah,ayah',
);
const firstOccurrence = new Map<string, { surah: number; ayah: number }>();
for (const w of allWithPos) {
  if (!firstOccurrence.has(w.arabic)) firstOccurrence.set(w.arabic, { surah: w.surah, ayah: w.ayah });
}

const freqLessons = [
  { titleBn: 'শীর্ষ শব্দ ১–২০', range: [0, 20] as [number, number], sort: 1, level: 'beginner' },
  { titleBn: 'শীর্ষ শব্দ ২১–৪০', range: [20, 40] as [number, number], sort: 2, level: 'beginner' },
  { titleBn: 'শীর্ষ শব্দ ৪১–৬০', range: [40, 60] as [number, number], sort: 3, level: 'intermediate' },
  { titleBn: 'শীর্ষ শব্দ ৬১–৮০', range: [60, 80] as [number, number], sort: 4, level: 'intermediate' },
  { titleBn: 'শীর্ষ শব্দ ৮১–১০০', range: [80, 100] as [number, number], sort: 5, level: 'intermediate' },
];

for (const lesson of freqLessons) {
  const slice = top100.slice(lesson.range[0], lesson.range[1]);
  const words: WordRow[] = slice.map(w => {
    const ctx = firstOccurrence.get(w.arabic) ?? { surah: 1, ayah: 1 };
    return { ...w, surah: ctx.surah, ayah: ctx.ayah };
  });
  const lessonId = await upsertLesson(unit2Id, lesson.titleBn, lesson.sort, lesson.level);
  const { ayahTexts, tafsirSnippets } = await fetchContext(words.map(w => ({ surah: w.surah, ayah: w.ayah })));
  const enrichMap = await enrichWords(words);
  const { vocab, exercises } = await insertContent(lessonId, lesson.titleBn, words, enrichMap, ayahTexts, tafsirSnippets);
  console.log(`  ✅  L${lesson.sort}: ${lesson.titleBn} — ${vocab} vocab, ${exercises} exercises`);
  totalLessons++; totalVocab += vocab; totalExercises += exercises;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// UNIT 3 — আল্লাহর গুণাবলী (Asma wa Sifat)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const unit3Id = await ensureUnit(trackId, 'asma-sifat', 'আল্লাহর গুণাবলী', 'أَسْمَاءُ اللهِ وَصِفَاتُهُ', 3);
console.log('\n📚  Unit 3: আল্লাহর গুণাবলী');

// Fetch adjectives/attributes of Allah using meaning_bn patterns
const asmaRows = await dbGet<WordRow>(
  'quran_words?meaning_bn=not.is.null&select=arabic,meaning_bn,surah,ayah&order=surah,ayah',
);
// Filter for likely divine attribute words (adjective patterns + known divine-name keywords in Bengali)
const divineKeywords = ['রহমান', 'রহীম', 'করীম', 'আজীজ', 'হাকীম', 'সামী', 'বাসীর', 'গাফূর',
  'শাকূর', 'হালীম', 'ওয়াদূদ', 'কারীব', 'মুজীব', 'খালিক', 'রাজ্জাক', 'কাদীর',
  'জাব্বার', 'মালিক', 'কুদ্দুস', 'সালাম', 'মুহাইমিন'];
const asmaCandidates = asmaRows.filter(r =>
  divineKeywords.some(kw => r.meaning_bn.includes(kw))
);
const asmaUnique = dedup(asmaCandidates).slice(0, 18);

// Split into 3 batches
const batch1 = asmaUnique.slice(0, 6);
const batch2 = asmaUnique.slice(6, 12);
const batch3 = asmaUnique.slice(12);

const asmaBatches = [
  { titleBn: 'রহমত ও ক্ষমার গুণ', sort: 1, level: 'beginner', words: batch1 },
  { titleBn: 'জ্ঞান ও শক্তির গুণ', sort: 2, level: 'intermediate', words: batch2 },
  { titleBn: 'অন্যান্য গুণাবলী', sort: 3, level: 'intermediate', words: batch3 },
];

for (const lb of asmaBatches) {
  if (lb.words.length === 0) {
    console.log(`  ⚠  L${lb.sort}: ${lb.titleBn} — no words found, skipping`);
    continue;
  }
  const lessonId = await upsertLesson(unit3Id, lb.titleBn, lb.sort, lb.level);
  const { ayahTexts, tafsirSnippets } = await fetchContext(lb.words.map(w => ({ surah: w.surah, ayah: w.ayah })));
  const enrichMap = await enrichWords(lb.words);
  const { vocab, exercises } = await insertContent(lessonId, lb.titleBn, lb.words, enrichMap, ayahTexts, tafsirSnippets);
  console.log(`  ✅  L${lb.sort}: ${lb.titleBn} — ${vocab} vocab, ${exercises} exercises`);
  totalLessons++; totalVocab += vocab; totalExercises += exercises;
}

// ── Summary ───────────────────────────────────────────────────────────────────

console.log(`
✅  Seeding complete!
    Lessons  : ${totalLessons}
    Vocab    : ${totalVocab}
    Exercises: ${totalExercises}

Next step: publish units in the admin panel (Review → set status → Publish)
`);
