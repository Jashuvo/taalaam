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
  jsonFile: string, table: string, label: string, batchSize = 500
) {
  console.log(`\n📥 Importing ${label}...`);
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

await importTable("tools/quran_data/surahs.json",       "quran_surahs", "Surahs (114)", 200);
await importTable("tools/quran_data/words_merged.json",  "quran_words",  "Words (~82k)", 500);
await importTable("tools/quran_data/tafsir_merged.json", "quran_tafsir", "Tafsir Abu Bakr Zakaria (6236 ayahs)", 300);

console.log("\n✅ All tables imported successfully.");
console.log("   Apply migrations 0025+0026 in Supabase Studio before running this.");
