// Usage:
//   SUPABASE_URL=https://xxx.supabase.co SUPABASE_SERVICE_ROLE_KEY=eyJ... \
//   deno run --allow-read --allow-net --allow-env tools/import_to_supabase.ts

const URL_ = Deno.env.get("SUPABASE_URL");
const KEY  = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
if (!URL_ || !KEY) {
  console.error("❌ Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY");
  Deno.exit(1);
}

const h = {
  apikey: KEY,
  Authorization: `Bearer ${KEY}`,
  "Content-Type": "application/json",
  Prefer: "resolution=merge-duplicates",
};
const hDel = { apikey: KEY, Authorization: `Bearer ${KEY}` };

// Each table uses a different PK column — map them here.
const pkFilter: Record<string, string> = {
  quran_surahs: "number=gt.0",
  quran_words:  "id=not.is.null",
  quran_tafsir: "id=not.is.null",
};

// Delete all rows before re-importing so stale rows (e.g. old basmala words
// that no longer exist in the pipeline output) don't linger in Supabase.
async function truncateTable(table: string): Promise<void> {
  const filter = pkFilter[table] ?? "id=not.is.null";
  const res = await fetch(`${URL_}/rest/v1/${table}?${filter}`, {
    method: "DELETE", headers: hDel,
  });
  if (!res.ok) {
    const txt = await res.text();
    console.error(`\n  ❌ truncate ${table}: ${txt}`);
    Deno.exit(1);
  }
  console.log(`  🗑️  Cleared ${table}`);
}

async function upsert(table: string, rows: object[], label: string): Promise<boolean> {
  const res = await fetch(`${URL_}/rest/v1/${table}`, {
    method: "POST", headers: h, body: JSON.stringify(rows),
  });
  if (!res.ok) {
    console.error(`\n  ❌ ${label}: ${await res.text()}`);
    return false;
  }
  return true;
}

async function importTable(
  jsonFile: string, table: string, label: string, batchSize = 500,
  clearFirst = false,
) {
  console.log(`\n📥 Importing ${label}...`);
  if (clearFirst) await truncateTable(table);
  const rows = JSON.parse(await Deno.readTextFile(jsonFile));
  let done = 0;
  for (let i = 0; i < rows.length; i += batchSize) {
    const batch = rows.slice(i, i + batchSize);
    const ok = await upsert(table, batch,
      `${label} [${i+1}–${Math.min(i+batchSize, rows.length)}]`);
    if (ok) done += batch.length;
    const pct = Math.round((done / rows.length) * 100);
    Deno.stdout.writeSync(
      new TextEncoder().encode(`\r  ${pct}% (${done}/${rows.length})`));
    await new Promise(r => setTimeout(r, 80));
  }
  console.log(`\n  ✅ ${done} rows imported`);
}

await importTable("tools/quran_data/surahs.json",       "quran_surahs", "Surahs (114)", 200, true);
await importTable("tools/quran_data/words_merged.json",  "quran_words",  "Words (~82k)", 500, true);
await importTable("tools/quran_data/tafsir_merged.json", "quran_tafsir", "Tafsir Abu Bakr Zakaria (6236 ayahs)", 300, true);

console.log("\n✅ All tables imported successfully.");
console.log("   Apply migrations 0025+0026 in Supabase Studio before running this.");
