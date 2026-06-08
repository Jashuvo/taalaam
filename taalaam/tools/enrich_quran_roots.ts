// enrich_quran_roots.ts
// Batch-enriches quran_words with root (الجذر) and pos (verb/noun/particle/adjective/pronoun).
// Run after quran_words is populated. Safe to re-run — skips words that already have a root.
//
// Usage:
//   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... GEMINI_API_KEY=... \
//   deno run --allow-net --allow-env tools/enrich_quran_roots.ts

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';

const SUPABASE_URL       = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY        = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const GEMINI_API_KEY     = Deno.env.get('GEMINI_API_KEY')!;
const BATCH_SIZE         = 40;   // words per Gemini call
const DELAY_MS           = 5000; // pause between batches to avoid rate limiting

const MODELS = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite', 'gemini-2.5-flash'];

const headers = {
  'Authorization': `Bearer ${SERVICE_KEY}`,
  'apikey': SERVICE_KEY,
  'Content-Type': 'application/json',
};

async function geminiGenerate(prompt: string): Promise<string> {
  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
  let lastErr: unknown;
  for (const modelName of MODELS) {
    for (let attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) await new Promise(r => setTimeout(r, 4000));
      try {
        const m = genAI.getGenerativeModel({ model: modelName });
        const result = await m.generateContent(prompt);
        return result.response.text();
      } catch (err) { lastErr = err; }
    }
  }
  throw new Error(`All Gemini models failed: ${(lastErr as Error).message}`);
}

function extractJsonArray(s: string): string {
  const stripped = s.trim().replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
  const start = stripped.indexOf('[');
  const end   = stripped.lastIndexOf(']');
  if (start === -1 || end <= start) throw new Error(`No JSON array: ${stripped.slice(0, 200)}`);
  return stripped.slice(start, end + 1);
}

// Fetch unique Arabic words that have no root yet
async function fetchUnenrichedWords(): Promise<{ arabic: string }[]> {
  const url = `${SUPABASE_URL}/rest/v1/quran_words?select=arabic&root=is.null&meaning_bn=not.is.null&order=arabic`;
  const res  = await fetch(url, { headers });
  if (!res.ok) throw new Error(await res.text());
  const rows = await res.json() as { arabic: string }[];
  // Deduplicate
  const seen = new Set<string>();
  return rows.filter(r => {
    if (seen.has(r.arabic)) return false;
    seen.add(r.arabic);
    return true;
  });
}

// Update all rows with the given arabic text
async function updateWords(updates: { arabic: string; root: string; pos: string }[]) {
  for (const u of updates) {
    const url = `${SUPABASE_URL}/rest/v1/quran_words?arabic=eq.${encodeURIComponent(u.arabic)}`;
    const res = await fetch(url, {
      method: 'PATCH',
      headers: { ...headers, 'Prefer': 'return=minimal' },
      body: JSON.stringify({ root: u.root, pos: u.pos }),
    });
    if (!res.ok) {
      console.warn(`  PATCH failed for ${u.arabic}: ${await res.text()}`);
    }
  }
}

async function enrichBatch(words: { arabic: string }[]): Promise<{ arabic: string; root: string; pos: string }[]> {
  const list = words.map((w, i) => `${i + 1}. ${w.arabic}`).join('\n');

  const prompt = `You are an Arabic morphology expert specialising in Quranic Arabic.
For each Arabic word below, provide:
  - root: the 3-letter Arabic root (الجذر الثلاثي), unvoweled, e.g. "قول", "علم", "رحم". If 4-letter root, use 4 letters.
  - pos: part of speech — one of: verb | noun | adjective | particle | pronoun | proper_noun

Return a JSON array where each object has exactly: {"arabic":"...","root":"...","pos":"..."}
Return ONLY the JSON array — no markdown, no explanation.

Words:
${list}`;

  const raw = await geminiGenerate(prompt);
  return JSON.parse(extractJsonArray(raw)) as { arabic: string; root: string; pos: string }[];
}

async function main() {
  console.log('Fetching unenriched words from quran_words…');
  const words = await fetchUnenrichedWords();
  console.log(`Found ${words.length} unique Arabic words without root.\n`);

  if (words.length === 0) {
    console.log('All words already enriched. Done.');
    return;
  }

  let processed = 0;
  for (let i = 0; i < words.length; i += BATCH_SIZE) {
    const batch = words.slice(i, i + BATCH_SIZE);
    console.log(`Batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(words.length / BATCH_SIZE)} (${batch.length} words)…`);

    try {
      const enriched = await enrichBatch(batch);
      await updateWords(enriched);
      processed += enriched.length;
      console.log(`  ✓ ${enriched.length} words updated (total: ${processed}/${words.length})`);
    } catch (e) {
      console.error(`  ✗ Batch failed: ${(e as Error).message}`);
    }

    if (i + BATCH_SIZE < words.length) {
      console.log(`  Waiting ${DELAY_MS / 1000}s before next batch…`);
      await new Promise(r => setTimeout(r, DELAY_MS));
    }
  }

  console.log(`\nDone! Enriched ${processed}/${words.length} words.`);
  console.log('Run curate-quran-lesson with unit_type=verbs to generate verb lessons.');
}

main().catch(e => { console.error('Fatal:', e); Deno.exit(1); });
