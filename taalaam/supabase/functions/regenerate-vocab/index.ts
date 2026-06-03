// supabase/functions/regenerate-vocab/index.ts
// Takes a lesson_id, reads its exercises, and uses Gemini to extract a
// structured vocabulary list with context snippets. Replaces any existing
// vocabulary rows for the lesson.
// Deploy: supabase functions deploy regenerate-vocab --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const ADMIN_EMAIL = 'jubayedsr@gmail.com';
async function checkAdmin(req: Request): Promise<Response | null> {
  const token = (req.headers.get('Authorization') ?? '').replace('Bearer ', '').trim();
  if (!token) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  const { data: { user }, error } = await createClient(
    Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!
  ).auth.getUser(token);
  if (error || user?.email !== ADMIN_EMAIL) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: { 'Content-Type': 'application/json', ...corsHeaders } });
  return null;
}

const VOCAB_SYSTEM_PROMPT = `You are an expert Arabic lexicographer and curriculum designer for Bangladeshi Muslim learners.

Your task: analyse Arabic language exercises and extract a clean vocabulary list from them.

RULES:
1. Extract ONLY Arabic words/phrases that are the actual learning targets — skip function words (الـ، و، في) unless the lesson is explicitly about them.
2. Every Arabic entry MUST have full, accurate harakat (vowel marks). Never output bare Arabic without diacritics.
3. For each word provide an authentic context_snippet_ar — a real Quranic Ayah, Hadith, or classical sentence that contains this word. Keep snippets short (≤ 10 words). If you cannot recall a verified real example, set null.
4. context_snippet_bn is the Bengali translation of context_snippet_ar.
5. word_type: noun | verb | particle | adjective | proper_noun
6. gender: masculine | feminine | null (null for verbs/particles)
7. grammar_note_bn: one concise sentence explaining the most important grammar point about this word (in Bengali).
8. De-duplicate: if the same root appears in multiple exercises, include it once.
9. Output ONLY a valid JSON array — no markdown fences, no extra text.

OUTPUT FORMAT (array of objects):
[
  {
    "arabic": "سَيَّارَةٌ",
    "transliteration": "sayyaaratun",
    "meaning_bn": "গাড়ি",
    "meaning_en": "car",
    "word_type": "noun",
    "gender": "feminine",
    "grammar_note_bn": "স্ত্রীলিঙ্গ বিশেষ্য। তানউয়িন (ٌ) অনির্দিষ্টতার চিহ্ন।",
    "context_snippet_ar": null,
    "context_snippet_bn": null
  }
]`;

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  const denied = await checkAdmin(req); if (denied) return denied;

  try {
    const { lesson_id } = await req.json();
    if (!lesson_id) {
      return new Response(
        JSON.stringify({ error: 'lesson_id is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Fetch the lesson title + all its exercises
    const { data: lesson, error: lessonErr } = await supabase
      .from('lessons')
      .select('id, title_bn')
      .eq('id', lesson_id)
      .single();
    if (lessonErr) throw lessonErr;

    const { data: exercises, error: exErr } = await supabase
      .from('exercises')
      .select('type, prompt_bn, prompt_ar, correct_answer, grammar_note_bn')
      .eq('lesson_id', lesson_id)
      .order('sort_order');
    if (exErr) throw exErr;
    if (!exercises?.length) {
      return new Response(
        JSON.stringify({ error: 'No exercises found for this lesson.' }),
        { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const exerciseSummary = exercises.map((ex, i) => (
      `Exercise ${i + 1} [${ex.type}]:\n` +
      (ex.prompt_ar ? `  Arabic: ${ex.prompt_ar}\n` : '') +
      (ex.prompt_bn ? `  Instruction: ${ex.prompt_bn}\n` : '') +
      `  Correct answer: ${JSON.stringify(ex.correct_answer)}\n` +
      (ex.grammar_note_bn ? `  Grammar note: ${ex.grammar_note_bn}` : '')
    )).join('\n\n');

    const userPrompt =
      `Lesson title: "${lesson.title_bn}"\n\n` +
      `Exercises:\n${exerciseSummary}\n\n` +
      `Extract the vocabulary list from these exercises. Return only the JSON array.`;

    const GEMINI_MODELS = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite', 'gemini-2.5-flash'];
    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    let rawText = '';
    for (const modelName of GEMINI_MODELS) {
      try {
        const m = genAI.getGenerativeModel({ model: modelName, systemInstruction: VOCAB_SYSTEM_PROMPT });
        const res = await m.generateContent(userPrompt);
        rawText = res.response.text();
        break;
      } catch (err) {
        const msg = String(err);
        if ((msg.includes('503') || msg.includes('overloaded') || msg.includes('UNAVAILABLE') || msg.includes('unavailable')) && modelName !== GEMINI_MODELS[GEMINI_MODELS.length - 1]) {
          continue;
        }
        throw err;
      }
    }
    let responseText = rawText.trim();
    if (responseText.startsWith('```')) {
      responseText = responseText
        .replace(/^```(?:json)?\n?/, '')
        .replace(/\n?```$/, '')
        .trim();
    }

    const vocabList: Record<string, unknown>[] = JSON.parse(responseText);
    if (!Array.isArray(vocabList) || vocabList.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Gemini returned an empty vocabulary list.' }),
        { status: 422, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    // Delete existing vocabulary for this lesson before reinserting
    await supabase.from('vocabulary').delete().eq('lesson_id', lesson_id);

    const { error: insertErr } = await supabase.from('vocabulary').insert(
      vocabList.map((v) => ({
        lesson_id,
        arabic: v.arabic,
        transliteration: v.transliteration ?? null,
        meaning_bn: v.meaning_bn,
        meaning_en: v.meaning_en ?? null,
        word_type: v.word_type ?? null,
        gender: v.gender ?? null,
        grammar_note_bn: v.grammar_note_bn ?? null,
        context_snippet_ar: v.context_snippet_ar ?? null,
        context_snippet_bn: v.context_snippet_bn ?? null,
      }))
    );
    if (insertErr) throw insertErr;

    return new Response(
      JSON.stringify({ success: true, vocab_count: vocabList.length }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  } catch (err) {
    console.error('regenerate-vocab error:', err);
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
});
