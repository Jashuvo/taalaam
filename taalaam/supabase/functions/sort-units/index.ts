// supabase/functions/sort-units/index.ts
// Sorts units, assigns tier levels (T1–T4), AND merges near-identical duplicates.
// Deploy: supabase functions deploy sort-units --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const ADMIN_EMAIL = 'jubayedsr@gmail.com';
async function checkAdmin(req: Request): Promise<Response | null> {
  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json', ...cors } });
  const { data: { user }, error } = await createClient(
    Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!
  ).auth.getUser(token);
  if (error || user?.email !== ADMIN_EMAIL) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: { 'Content-Type': 'application/json', ...cors } });
  return null;
}

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite'];

async function geminiGenerate(apiKey: string, systemInstruction: string, prompt: string): Promise<{ text: string; model: string }> {
  const genAI = new GoogleGenerativeAI(apiKey);
  let lastErr: unknown;
  for (const modelName of GEMINI_MODELS) {
    try {
      const m = genAI.getGenerativeModel({ model: modelName, systemInstruction });
      const result = await m.generateContent(prompt);
      return { text: result.response.text(), model: modelName };
    } catch (err) {
      lastErr = err;
    }
  }
  const msg = lastErr instanceof Error ? lastErr.message : JSON.stringify(lastErr);
  throw new Error(`All Gemini models failed: ${msg}`);
}

const SYSTEM_PROMPT = `You are an expert Curriculum Architect and Arabic Linguist specializing in designing gamified, step-by-step language courses (Duolingo-style micro-learning).

The target audience: Bengali speakers learning Classical/Fusha Arabic, with emphasis on Islamic/Salafi vocabulary contexts.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## TIER CLASSIFICATION RULES
Assign EVERY module to exactly one of 4 tiers based on its content:

T1 — FOUNDATIONAL (মৌলিক শব্দ ও পরিচিতি):
  Target: core vocabulary, first contact with Arabic script
  Signals: greetings, pronouns (أنا/أنت/هو), demonstratives (هذا/هذه/ذلك),
           basic nouns (body, family, objects, numbers, colors, days),
           simple labels, no grammar structures yet

T2 — STRUCTURAL (বাক্যরীতি ও যৌগিক পদ):
  Target: first sentence patterns, noun grammar
  Signals: nominal sentences (جملة اسمية), ال definite article,
           إضافة genitive constructs, حروف الجر prepositions,
           adjective-noun agreement, simple plurals, topic vocabulary
           (daily life, workplace, markets, time)

T3 — VERBAL (ক্রিয়াপদ ও রূপান্তর):
  Target: verb system and morphological patterns
  Signals: Maadi/Mudaari/Amr verb forms, common أبواب (نصر، كتب، ذهب),
           verb sentences (جملة فعلية), subject-verb agreement,
           basic negation (لا/لم/لن), derived verb forms

T4 — ADVANCED (উচ্চতর শাস্ত্র ও তাফসির):
  Target: classical morphology, complex syntax, Quranic scholarship
  Signals: broken plurals, صرف derivations, conditional شرط sentences,
           إعراب case analysis, Quranic tafsir vocabulary,
           advanced نحو constructs, classical literary Arabic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## PEDAGOGICAL ORDERING RULES
Within tiers, order modules so each one builds on the previous:
1. Vocabulary before syntax — nouns before sentence structures
2. Demonstratives (هذا/هذه) before nominal sentences
3. Cognitive load: Isolated Nouns → Pointers+Nouns → Sentences → Verbs → Advanced
4. Never break a focused grammar sequence with an unrelated vocabulary module

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## MANDATORY MERGING RULE
If multiple modules target the same Arabic pattern, construction, or vocab theme → MERGE them.

Example: "ক্রিয়ার রূপান্তর: বাব নাসারা" + "ক্রিয়ার রূপান্তর (باب نَصَرَ)" → ONE module.

For merged modules: pick the most descriptive title. The "keep" module absorbs all lessons.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## TRACK CLASSIFICATION RULES
Modules belong to one of two learning tracks. If a module on the current track
actually belongs on the other track, flag it in track_assignments.

CONVERSATIONAL (কথোপকথন আরবি) — slug: "conversational":
  Purpose: everyday spoken Modern Arabic for real communication
  Signals: greetings, shopping, professions, travel, food, family, emotions,
           daily objects, common phrases, dialogues, practical scenarios
  Example titles: "পেশা ও কর্মসংস্থান", "বাজার ও কেনাকাটা", "পরিবার পরিচিতি"

QURANIC (কুরআনিক আরবি) — slug: "quranic":
  Purpose: Classical/Fusha Arabic for reading Quran and Islamic texts
  Signals: Quranic vocabulary, verb conjugation patterns (أبواب), morphological
           tables (صرف), tafsir terms, classical grammar (نحو/إعراب),
           Islamic/religious context, root-word analysis
  Example titles: "ক্রিয়ার রূপান্তর", "বাব নাসারা", "মাযি ও মুযারি"
  TIEBREAKER: When ambiguous → assign to QURANIC (app's primary mission)

In track_assignments: ONLY list modules that need to move to the OTHER track.
Omit modules that already belong on the current track.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## OUTPUT FORMAT (STRICT JSON — NO MARKDOWN, NO EXTRA TEXT)
{
  "sorted_ids": ["id-1", "id-2", "id-3"],
  "tier_assignments": [
    { "id": "id-1", "tier": 1 },
    { "id": "id-2", "tier": 1 },
    { "id": "id-3", "tier": 2 }
  ],
  "track_assignments": [
    { "id": "id-4", "track": "quranic", "reason": "Teaches verb conjugation باب — belongs in Quranic track" }
  ],
  "merge_groups": [
    {
      "keep_id": "id-2",
      "keep_title_bn": "ক্রিয়ার রূপান্তর (বাব নাসারা)",
      "keep_title_ar": "تَصْرِيفُ الأَفْعَالِ: بَابُ نَصَرَ",
      "merge_ids": ["id-5", "id-8"],
      "reason": "Three modules all teach the same بَاب نَصَرَ verb conjugation pattern"
    }
  ]
}

RULES:
- sorted_ids: final IDs REMAINING on the current track after merging and track moves
  (T1 modules first, then T2, then T3, then T4 — within each tier ordered pedagogically)
  Do NOT include IDs listed in track_assignments (those are leaving this track)
- tier_assignments: EVERY module staying on the current track must appear here
  Do NOT include track_assignments IDs here
- track_assignments: only units that are WRONG-TRACK and should move; include a reason
- merge_ids are deleted — do NOT include them in sorted_ids or tier_assignments
- If no track moves needed, return "track_assignments": []
- If no merges needed, return "merge_groups": []`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  const denied = await checkAdmin(req); if (denied) return denied;

  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();
  const enc = new TextEncoder();

  const respond = async (body: unknown) => {
    await writer.write(enc.encode(JSON.stringify(body)));
    await writer.close();
  };

  (async () => {
    try {
      const { track_id } = await req.json();
      if (!track_id) { await respond({ error: 'track_id is required' }); return; }

      const supabase = createClient(
        Deno.env.get('SUPABASE_URL')!,
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      );

      // Fetch all tracks so we can resolve slugs ↔ IDs for track reassignment
      const { data: allTracks } = await supabase.from('tracks').select('id, slug');
      const trackById  = new Map((allTracks ?? []).map((t: any) => [t.id, t.slug as string]));
      const trackBySlug = new Map((allTracks ?? []).map((t: any) => [t.slug as string, t.id as string]));
      const currentTrackSlug = trackById.get(track_id) ?? 'unknown';

      const { data: units, error: unitErr } = await supabase
        .from('units')
        .select('id, title_bn, title_ar, tier_level, sort_order')
        .eq('track_id', track_id)
        .order('sort_order');

      if (unitErr) { await respond({ error: unitErr.message }); return; }
      if (!units || units.length < 2) {
        await respond({ sorted_ids: units?.map((u: any) => u.id) ?? [], merged: [], tier_changes: [], track_changes: [] });
        return;
      }

      const userMessage =
        `Analyse these modules from the "${currentTrackSlug}" track.\n` +
        'Tasks: (1) sort pedagogically, (2) assign T1–T4 tier, (3) identify wrong-track modules, (4) merge duplicates.\n\n' +
        'Current tier shown for context — override if needed.\n\n' +
        'Modules:\n' +
        units.map((u: any, i: number) =>
          `${i + 1}. ID: ${u.id}\n   Bengali: ${u.title_bn}\n   Arabic: ${u.title_ar ?? '—'}\n   Current tier: T${u.tier_level ?? 1}`
        ).join('\n\n') +
        '\n\nReturn the strict JSON object as specified. No markdown.';

      const { text: rawTextRaw, model: modelUsed } = await geminiGenerate(Deno.env.get('GEMINI_API_KEY')!, SYSTEM_PROMPT, userMessage);
      const rawText = rawTextRaw.trim().replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();

      const parsed = JSON.parse(rawText);
      const sortedIds: string[] = parsed.sorted_ids ?? [];
      const tierAssignments: { id: string; tier: number }[] = parsed.tier_assignments ?? [];
      const trackAssignments: { id: string; track: string; reason?: string }[] = parsed.track_assignments ?? [];
      const mergeGroups: any[] = parsed.merge_groups ?? [];

      const allKnownIds = new Set(units.map((u: any) => u.id as string));

      // ── Execute merges ────────────────────────────────────────────────────
      const mergedSummary: string[] = [];
      for (const group of mergeGroups) {
        const { keep_id, merge_ids, keep_title_bn, keep_title_ar, reason } = group;
        if (!keep_id || !Array.isArray(merge_ids)) continue;
        if (!allKnownIds.has(keep_id)) continue;

        if (keep_title_bn || keep_title_ar) {
          const titleUpdate: any = {};
          if (keep_title_bn) titleUpdate.title_bn = keep_title_bn;
          if (keep_title_ar) titleUpdate.title_ar = keep_title_ar;
          await supabase.from('units').update(titleUpdate).eq('id', keep_id);
        }

        const { data: keepLessons } = await supabase
          .from('lessons').select('sort_order').eq('unit_id', keep_id)
          .order('sort_order', { ascending: false }).limit(1);
        let offset = (keepLessons?.[0]?.sort_order ?? -1) as number;

        for (const mergeId of merge_ids) {
          if (!allKnownIds.has(mergeId)) continue;
          const { data: moveLessons } = await supabase
            .from('lessons').select('id')
            .eq('unit_id', mergeId).order('sort_order');
          if (moveLessons && moveLessons.length > 0) {
            for (const lesson of moveLessons) {
              offset += 1;
              await supabase.from('lessons')
                .update({ unit_id: keep_id, sort_order: offset })
                .eq('id', lesson.id);
            }
          }
          await supabase.from('units').delete().eq('id', mergeId);
        }

        mergedSummary.push(reason ?? `Merged ${merge_ids.length} duplicate unit(s) into ${keep_id}`);
      }

      // ── Build final valid list (exclude deleted + moved-away units) ─────────
      const deletedIds = new Set(
        mergeGroups.flatMap((g: any) => (g.merge_ids as string[] | undefined) ?? [])
      );
      const validSorted = sortedIds.filter(
        (id) => allKnownIds.has(id) && !deletedIds.has(id) && !movedToOtherTrack.has(id)
      );

      // ── Apply track reassignments (move wrong-track modules) ──────────────
      const movedToOtherTrack = new Set<string>();
      const trackChanges: { id: string; title_bn: string; from_track: string; to_track: string; reason: string }[] = [];

      for (const assignment of trackAssignments) {
        const { id, track: targetSlug, reason } = assignment;
        if (!allKnownIds.has(id)) continue;
        const targetTrackId = trackBySlug.get(targetSlug);
        if (!targetTrackId || targetTrackId === track_id) continue; // already on correct track or unknown slug

        await supabase.from('units').update({ track_id: targetTrackId }).eq('id', id);
        movedToOtherTrack.add(id);
        const unit = units.find((u: any) => u.id === id);
        trackChanges.push({
          id,
          title_bn: unit?.title_bn ?? id,
          from_track: currentTrackSlug,
          to_track: targetSlug,
          reason: reason ?? `Moved to ${targetSlug} track`,
        });
      }

      // ── Apply tier_level assignments ───────────────────────────────────────
      const tierMap = new Map(tierAssignments.map((a) => [a.id, a.tier]));
      const tierChanges: { id: string; old_tier: number; new_tier: number }[] = [];

      for (const unit of units) {
        if (deletedIds.has(unit.id)) continue;
        const newTier = tierMap.get(unit.id);
        if (newTier && newTier !== unit.tier_level) {
          await supabase.from('units').update({ tier_level: newTier }).eq('id', unit.id);
          tierChanges.push({ id: unit.id, old_tier: unit.tier_level ?? 1, new_tier: newTier });
        }
      }

      // ── Apply sort_order (global position) and sequence_order (per-tier) ──
      // Group by tier in sorted order to compute per-tier sequence_order
      const tierCounters = new Map<number, number>();
      await Promise.all(
        validSorted.map((id, globalIdx) => {
          const tier = tierMap.get(id) ?? (units.find((u: any) => u.id === id)?.tier_level ?? 1);
          const seqInTier = (tierCounters.get(tier) ?? 0) + 1;
          tierCounters.set(tier, seqInTier);
          return supabase.from('units').update({
            sort_order: globalIdx,
            sequence_order: seqInTier,
          }).eq('id', id);
        }),
      );

      await respond({ sorted_ids: validSorted, merged: mergedSummary, tier_changes: tierChanges, track_changes: trackChanges, model_used: modelUsed });
    } catch (e: any) {
      const msg = e instanceof Error ? e.message : String(e);
      try { await respond({ error: msg }); } catch (_) {}
    }
  })();

  return new Response(readable, {
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
});
