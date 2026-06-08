// Fetches Arabic Uthmani text + surah metadata from api.alquran.cloud (free, no key).
// Bengali word-by-word comes from the locally downloaded GTAF file.
// Reciter: Mishary Al-Afasy via cdn.islamic.network (streaming, no download)

const API = "https://api.alquran.cloud/v1/quran/quran-uthmani";

console.log("📥 Fetching Arabic Uthmani text + surah metadata...\n");

async function fetchWithRetry(url: string, label: string, maxTries = 3) {
  for (let i = 0; i < maxTries; i++) {
    try {
      console.log(`  Fetching ${label}...`);
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return await res.json();
    } catch (e) {
      if (i === maxTries - 1) throw e;
      const wait = 1000 * 2 ** i;
      console.log(`  ⚠️  Retry ${i+1} in ${wait}ms`);
      await new Promise(r => setTimeout(r, wait));
    }
  }
}

const apiData = await fetchWithRetry(API, "Full Quran (quran-uthmani)");
const surahs_raw = (apiData as any).data.surahs as any[];

// ── Surah Bengali names (hardcoded for accuracy) ─────────────────────────────
const SURAH_BN: Record<number, [string, string]> = {
  1:["আল-ফাতিহা","meccan"],2:["আল-বাক্বারাহ","medinan"],3:["আলে-ইমরান","medinan"],
  4:["আন-নিসা","medinan"],5:["আল-মায়িদাহ","medinan"],6:["আল-আনআম","meccan"],
  7:["আল-আরাফ","meccan"],8:["আল-আনফাল","medinan"],9:["আত-তাওবাহ","medinan"],
  10:["ইউনুস","meccan"],11:["হুদ","meccan"],12:["ইউসুফ","meccan"],
  13:["আর-রাদ","medinan"],14:["ইবরাহীম","meccan"],15:["আল-হিজর","meccan"],
  16:["আন-নাহল","meccan"],17:["আল-ইসরা","meccan"],18:["আল-কাহফ","meccan"],
  19:["মারইয়াম","meccan"],20:["ত্বহা","meccan"],21:["আল-আম্বিয়া","meccan"],
  22:["আল-হাজ্জ","medinan"],23:["আল-মু'মিনুন","meccan"],24:["আন-নূর","medinan"],
  25:["আল-ফুরক্বান","meccan"],26:["আশ-শুআরা","meccan"],27:["আন-নামল","meccan"],
  28:["আল-ক্বাসাস","meccan"],29:["আল-আনকাবুত","meccan"],30:["আর-রূম","meccan"],
  31:["লুক্বমান","meccan"],32:["আস-সাজদাহ","meccan"],33:["আল-আহযাব","medinan"],
  34:["সাবা","meccan"],35:["ফাতির","meccan"],36:["ইয়াসিন","meccan"],
  37:["আস-সাফফাত","meccan"],38:["সোয়াদ","meccan"],39:["আয-যুমার","meccan"],
  40:["গাফির","meccan"],41:["ফুস্সিলাত","meccan"],42:["আশ-শূরা","meccan"],
  43:["আয-যুখরুফ","meccan"],44:["আদ-দুখান","meccan"],45:["আল-জাসিয়াহ","meccan"],
  46:["আল-আহক্বাফ","meccan"],47:["মুহাম্মাদ","medinan"],48:["আল-ফাতহ","medinan"],
  49:["আল-হুজুরাত","medinan"],50:["ক্বাফ","meccan"],51:["আয-যারিয়াত","meccan"],
  52:["আত-তূর","meccan"],53:["আন-নাজম","meccan"],54:["আল-ক্বামার","meccan"],
  55:["আর-রাহমান","medinan"],56:["আল-ওয়াক্বিয়াহ","meccan"],57:["আল-হাদীদ","medinan"],
  58:["আল-মুজাদালাহ","medinan"],59:["আল-হাশর","medinan"],60:["আল-মুমতাহিনাহ","medinan"],
  61:["আস-সফ","medinan"],62:["আল-জুমুআহ","medinan"],63:["আল-মুনাফিকুন","medinan"],
  64:["আত-তাগাবুন","medinan"],65:["আত-ত্বালাক্ব","medinan"],66:["আত-তাহরীম","medinan"],
  67:["আল-মুলক","meccan"],68:["আল-ক্বালাম","meccan"],69:["আল-হাক্বক্বাহ","meccan"],
  70:["আল-মাআরিজ","meccan"],71:["নূহ","meccan"],72:["আল-জিন","meccan"],
  73:["আল-মুযযাম্মিল","meccan"],74:["আল-মুদ্দাস্সির","meccan"],75:["আল-ক্বিয়ামাহ","meccan"],
  76:["আল-ইনসান","medinan"],77:["আল-মুরসালাত","meccan"],78:["আন-নাবা","meccan"],
  79:["আন-নাযিআত","meccan"],80:["আবাসা","meccan"],81:["আত-তাকবীর","meccan"],
  82:["আল-ইনফিত্বার","meccan"],83:["আল-মুত্বাফফিফীন","meccan"],84:["আল-ইনশিক্বাক্ব","meccan"],
  85:["আল-বুরূজ","meccan"],86:["আত-তারিক্ব","meccan"],87:["আল-আলা","meccan"],
  88:["আল-গাশিয়াহ","meccan"],89:["আল-ফাজর","meccan"],90:["আল-বালাদ","meccan"],
  91:["আশ-শামস","meccan"],92:["আল-লাইল","meccan"],93:["আদ-দুহা","meccan"],
  94:["আশ-শারহ","meccan"],95:["আত-তীন","meccan"],96:["আল-আলাক্ব","meccan"],
  97:["আল-ক্বদর","meccan"],98:["আল-বায়্যিনাহ","medinan"],99:["আয-যিলযাল","medinan"],
  100:["আল-আদিয়াত","meccan"],101:["আল-ক্বারিআহ","meccan"],102:["আত-তাকাসুর","meccan"],
  103:["আল-আসর","meccan"],104:["আল-হুমাযাহ","meccan"],105:["আল-ফীল","meccan"],
  106:["ক্বুরাইশ","meccan"],107:["আল-মাউন","meccan"],108:["আল-কাউসার","meccan"],
  109:["আল-কাফিরুন","meccan"],110:["আন-নাসর","medinan"],111:["আল-মাসাদ","meccan"],
  112:["আল-ইখলাস","meccan"],113:["আল-ফালাক্ব","meccan"],114:["আন-নাস","meccan"],
};

// Build surahs.json
const surahs = surahs_raw.map((s: any) => {
  const [nameBn, revelation] = SURAH_BN[s.number] ?? ["","meccan"];
  return {
    number: s.number,
    name_ar: s.name,
    name_en: s.englishName,
    name_bn: nameBn,
    ayah_count: s.ayahs.length,
    revelation,
  };
});

// Filter out standalone Uthmani pause/sajdah marks (U+06D6–U+06DC, U+06DF–U+06E4,
// U+06E7, U+06E8, U+06EA–U+06ED) that alquran.cloud emits as separate space-separated
// tokens. A real Arabic word must contain at least one character in U+0600–U+06D5.
function isRealWord(s: string): boolean {
  for (const ch of s) {
    const cp = ch.codePointAt(0)!;
    if (cp >= 0x0600 && cp <= 0x06D5) return true;
  }
  return false;
}

// Build arabic_words.json — Arabic text only; GTAF handles Bengali
type ArabicWord = { id:string; surah:number; ayah:number; position:number; arabic:string };
const arabicWords: ArabicWord[] = [];

for (const s of surahs_raw) {
  for (const ayah of s.ayahs) {
    // numberInSurah is the ayah number within the surah (1-based) — matches GTAF keys
    const ayahNum = ayah.numberInSurah;
    // Strip BOM (﻿) that sometimes appears on first ayah
    const text = (ayah.text as string).replace(/^﻿/, "").trim();
    // Filter Uthmani marks that appear as standalone tokens in the Uthmani edition
    let words = text.split(/\s+/).filter(Boolean).filter(isRealWord);

    // alquran.cloud (quran-uthmani) prepends the basmala (4 words: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ)
    // to ayah 1 of every surah EXCEPT surah 1 (Al-Fatiha, where ayah 1 IS the basmala)
    // and surah 9 (At-Tawba, which has no basmala by Islamic tradition).
    // GTAF word positions start from the actual surah content, not the prepended basmala,
    // so we must strip those 4 words to keep position numbers aligned.
    if (s.number !== 1 && s.number !== 9 && ayahNum === 1) {
      words = words.slice(4);
    }

    words.forEach((w: string, i: number) => {
      arabicWords.push({
        id: `${s.number}:${ayahNum}:${i+1}`,
        surah: s.number,
        ayah: ayahNum,
        position: i+1,
        arabic: w,
      });
    });
  }
}

await Deno.mkdir("tools/quran_data", { recursive: true });
await Deno.writeTextFile("tools/quran_data/arabic_words.json",
  JSON.stringify(arabicWords, null, 0));
await Deno.writeTextFile("tools/quran_data/surahs.json",
  JSON.stringify(surahs, null, 2));

console.log(`\n✅ Done! ${arabicWords.length} Arabic words, ${surahs.length} surahs`);
console.log(`   Sample IDs: ${arabicWords.slice(0,3).map(w=>w.id).join(", ")}`);
