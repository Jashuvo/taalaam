console.log("🔀 Merging Quran data...\n");

const arabicWords = JSON.parse(
  await Deno.readTextFile("tools/quran_data/arabic_words.json"));
const gtafRaw = JSON.parse(
  await Deno.readTextFile("tools/quran_data/gtaf_bn_wbw.json"));
const tafsirRaw = JSON.parse(
  await Deno.readTextFile("tools/quran_data/tafsir_abu_bakr_zakaria.json"));

// ── GTAF Bengali WBW ──────────────────────────────────────────────────────────
// Structure: flat object keyed "surah:ayah:position" → Bengali string
// e.g. { "1:1:1": "নামে", "1:1:2": "আল্লাহ (র)", ... }
const gtafMap = new Map<string, string>();

if (Array.isArray(gtafRaw)) {
  for (const row of gtafRaw) {
    const s = row.chapter_number ?? row.surah ?? row.chapter;
    const a = row.verse_number  ?? row.ayah  ?? row.verse;
    const p = row.word_number   ?? row.position ?? row.word;
    const t = row.translation   ?? row.text ?? row.meaning ?? row.bn;
    if (s && a && p && t) gtafMap.set(`${s}:${a}:${p}`, t as string);
  }
} else {
  // Check if keys are "s:a:p" format (flat) or nested { surah: { ayah: { pos: text } } }
  const firstKey = Object.keys(gtafRaw)[0];
  if (firstKey && firstKey.includes(":")) {
    // Flat object keyed "surah:ayah:position"
    for (const [key, val] of Object.entries(gtafRaw as Record<string, string>)) {
      gtafMap.set(key, val);
    }
  } else {
    // Nested { surah: { ayah: { position: text } } }
    for (const [s, ayahs] of Object.entries(gtafRaw as any)) {
      for (const [a, words] of Object.entries(ayahs as any)) {
        for (const [p, t] of Object.entries(words as any)) {
          gtafMap.set(`${s}:${a}:${p}`, t as string);
        }
      }
    }
  }
}
console.log(`  GTAF Bengali entries: ${gtafMap.size}`);
console.log(`  Sample keys: ${Array.from(gtafMap.keys()).slice(0,3).join(", ")}`);

// ── Tafsir Abu Bakr Zakaria ───────────────────────────────────────────────────
// Structure: object keyed "surah:ayah" → { text: "<p>HTML</p>" }
// Strip HTML tags to get plain Bengali text for Flutter Text widget

function stripHtml(html: string): string {
  return html
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<[^>]+>/g, "")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

const tafsirMap = new Map<string, string>();

if (Array.isArray(tafsirRaw)) {
  for (const row of tafsirRaw) {
    const s = row.chapter_number ?? row.surah_number ?? row.chapter ?? row.surah;
    const a = row.verse_number   ?? row.ayah_number  ?? row.verse   ?? row.ayah;
    const t = row.text ?? row.tafsir ?? row.content;
    if (s && a && t) tafsirMap.set(`${s}:${a}`, typeof t === "string" ? stripHtml(t) : "");
  }
} else {
  for (const [key, val] of Object.entries(tafsirRaw as any)) {
    const raw = (val as any)?.text ?? val;
    tafsirMap.set(key, typeof raw === "string" ? stripHtml(raw) : "");
  }
}
console.log(`  Tafsir entries: ${tafsirMap.size}`);
const firstTafsir = Array.from(tafsirMap.values())[0];
console.log(`  Tafsir sample (1:1): ${firstTafsir?.slice(0, 80)}...`);

// ── Merge word rows ───────────────────────────────────────────────────────────
const merged = (arabicWords as any[]).map(w => ({
  id:         w.id,
  surah:      w.surah,
  ayah:       w.ayah,
  position:   w.position,
  arabic:     w.arabic,
  meaning_bn: gtafMap.get(w.id) ?? null,
}));

const noMeaning = merged.filter(w => !w.meaning_bn).length;
console.log(`\n  Words with GTAF meaning: ${merged.length - noMeaning}/${merged.length}`);
if (noMeaning > 0 && noMeaning === merged.length) {
  console.error("  ❌ ALL words missing meaning — key mismatch! First 3 GTAF keys:");
  Array.from(gtafMap.keys()).slice(0, 3).forEach(k => console.error("    ", k));
  Deno.exit(1);
} else if (noMeaning > 0) {
  console.log(`  ⚠️  ${noMeaning} words have no Bengali meaning (expected for some)`)
}

// ── Tafsir rows ───────────────────────────────────────────────────────────────
const tafsirRows = Array.from(tafsirMap.entries())
  .filter(([, text]) => text.length > 0)
  .map(([key, text]) => {
    const [s, a] = key.split(":").map(Number);
    return { id: key, surah: s, ayah: a, text };
  });

await Deno.writeTextFile("tools/quran_data/words_merged.json",
  JSON.stringify(merged, null, 0));
await Deno.writeTextFile("tools/quran_data/tafsir_merged.json",
  JSON.stringify(tafsirRows, null, 0));

console.log(`\n✅ Merge complete!`);
console.log(`   ${merged.length} word rows → words_merged.json`);
console.log(`   ${tafsirRows.length} tafsir rows → tafsir_merged.json`);
