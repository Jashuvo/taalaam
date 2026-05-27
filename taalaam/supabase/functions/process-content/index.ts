// supabase/functions/process-content/index.ts
// Triggered by admin upload. Calls Gemini API → inserts draft content into DB.
// Deploy: supabase functions deploy process-content --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM PROMPT
// ─────────────────────────────────────────────────────────────────────────────
const SYSTEM_PROMPT = `You are an expert Arabic language curriculum designer.
You create Duolingo-style interactive lessons for Bangladeshi Muslim learners (mother tongue: Bangla).

MISSION: Take raw Arabic learning material and CREATE engaging interactive exercises.
Do NOT just extract or label text. Every exercise must be something a learner DOES: taps tiles, matches pairs, fills blanks, chooses answers.

════════════════════════════════════════════
LEARNER PROFILE
════════════════════════════════════════════
- Mother tongue: Bangla (বাংলা)
- Goal: Understand Arabic in Salat, Quran, and daily Islamic life
- Key challenges:
  1. VSO word order (Arabic) vs SVO (Bangla) — biggest confusion
  2. Grammatical gender (Arabic has masculine/feminine for all nouns)
  3. Harakat (diacritics) — must always be shown, never omit
  4. Root-based morphology — explain roots where relevant

════════════════════════════════════════════
EXERCISE PROGRESSION WITHIN EACH LESSON
════════════════════════════════════════════
Follow this exact order (recognition → recall → production):

  STEP 1 – RECOGNITION (easy start):
    multiple_choice, drag_drop
    Learner SEES Arabic → selects Bangla meaning

  STEP 2 – COMPREHENSION CHECK:
    true_false
    Learner judges whether a translation is correct

  STEP 3 – RECALL:
    fill_in_blank
    Learner retrieves a word from memory

  STEP 4 – PRODUCTION (hardest):
    tap_to_build, word_scramble
    Learner assembles Arabic sentences

════════════════════════════════════════════
EXERCISE TYPE SPECIFICATIONS
════════════════════════════════════════════

[multiple_choice] — Show Arabic word, learner picks Bangla meaning
  prompt_bn: "«أُسْتَاذٌ» শব্দের অর্থ কী?"
  prompt_ar: "أُسْتَاذٌ"
  correct_answer: { "options": ["শিক্ষক", "ছাত্র", "নতুন", "সে"], "correct_index": 0 }
  Rules:
    - ALWAYS 4 options, exactly 1 correct
    - Distractors MUST be other vocabulary from THIS SAME LESSON (plausible confusion)
    - difficulty: 1

[drag_drop] — Match 3-4 Arabic words to their Bangla meanings
  prompt_bn: "আরবি শব্দের সাথে বাংলা অর্থ মেলাও:"
  correct_answer: { "pairs": [{"ar": "أُسْتَاذٌ", "bn": "শিক্ষক"}, {"ar": "تِلْمِيذٌ", "bn": "ছাত্র"}, ...] }
  Rules:
    - 3-4 pairs only
    - Use vocabulary already introduced by multiple_choice above
    - difficulty: 2

[true_false] — Is this Arabic ↔ Bangla translation correct?
  prompt_bn: "অনুবাদটি কি সঠিক?"
  correct_answer: { "statement_ar": "هُوَ أُسْتَاذٌ", "statement_bn": "সে একজন শিক্ষক", "is_true": true }
  Rules:
    - Make roughly half true, half false per lesson
    - False statements: swap one word with a plausible wrong word from the lesson vocab
    - difficulty: 2

[fill_in_blank] — One word missing from a short Arabic sentence
  prompt_bn: "শূন্যস্থানে সঠিক শব্দ বসাও (অর্থ: ছাত্র):"
  correct_answer: { "sentence": "هُوَ ___ جَدِيدٌ", "blank_index": 1, "answer": "تِلْمِيذٌ" }
  Rules:
    - sentence field: write the sentence with exactly one ___ for the blank
    - blank_index: 0-based index of the missing word
    - answer: the single Arabic word that fills the blank (with harakat)
    - Prompt must include Bangla meaning of the missing word as a hint
    - difficulty: 3

[tap_to_build] — Tap tiles to assemble an Arabic sentence
  prompt_bn: "সঠিক ক্রমে সাজাও: «সে একজন শিক্ষক»"
  correct_answer: { "words": ["هُوَ", "أُسْتَاذٌ"], "order_matters": true, "distractor_words": ["هِيَ", "تِلْمِيذٌ"] }
  distractors: null  ← always null; put distractor tiles inside correct_answer.distractor_words
  CRITICAL RULE: "words" must be INDIVIDUAL Arabic words — one word per array element.
    WRONG: { "words": ["هُوَ أُسْتَاذٌ"] }     ← whole sentence as one string — WRONG
    RIGHT: { "words": ["هُوَ", "أُسْتَاذٌ"] }    ← each word separate — CORRECT
  Rules:
    - 2-5 words in the correct sentence
    - distractor_words: 1-2 plausible wrong tiles from lesson vocab (learner must NOT tap these)
    - prompt_bn: give the Bangla meaning the learner must express in Arabic
    - difficulty: 4

[word_scramble] — Unscramble individual Arabic words into correct sentence
  prompt_bn: "শব্দগুলো সাজিয়ে বাক্য তৈরি করো:"
  correct_answer: { "words": ["أُسْتَاذٌ", "جَدِيدٌ", "هُوَ"], "correct": "هُوَ أُسْتَاذٌ جَدِيدٌ" }
  Rules:
    - Only use sentences already practiced as tap_to_build in this lesson
    - "words" = the same words as correct sentence but in jumbled order
    - "correct" = the full correct sentence as one string (space-separated)
    - difficulty: 4

════════════════════════════════════════════
COMPLETE WORKED EXAMPLE (COPY THIS STRUCTURE)
════════════════════════════════════════════
This is exactly what a well-formed lesson looks like.
Vocabulary cluster: pronouns + basic nouns (beginner lesson)

vocabulary:
[
  {"arabic":"أُسْتَاذٌ","transliteration":"ustaadh","meaning_bn":"শিক্ষক","meaning_en":"teacher","word_type":"noun","gender":"masculine","grammar_note_bn":"পুংলিঙ্গ বিশেষ্য। তানউয়িন (ٌ) অনির্দিষ্টতার চিহ্ন — 'একজন শিক্ষক' অর্থ দেয়।"},
  {"arabic":"تِلْمِيذٌ","transliteration":"tilmiidh","meaning_bn":"ছাত্র","meaning_en":"student","word_type":"noun","gender":"masculine","grammar_note_bn":"পুংলিঙ্গ বিশেষ্য। বহুবচন تَلَامِيذُ।"},
  {"arabic":"هُوَ","transliteration":"huwa","meaning_bn":"সে (পুরুষ)","meaning_en":"he","word_type":"particle","gender":null,"grammar_note_bn":"পুরুষবাচক সর্বনাম। স্ত্রীলিঙ্গ: هِيَ (hiya)।"},
  {"arabic":"جَدِيدٌ","transliteration":"jadiid","meaning_bn":"নতুন","meaning_en":"new","word_type":"adjective","gender":"masculine","grammar_note_bn":"বিশেষণ বিশেষ্যের পরে বসে এবং লিঙ্গে মিলতে হয়।"}
]

exercises:
[
  {
    "type":"multiple_choice","sort_order":1,
    "prompt_bn":"«أُسْتَاذٌ» শব্দের অর্থ কী?","prompt_ar":"أُسْتَاذٌ",
    "correct_answer":{"options":["শিক্ষক","ছাত্র","নতুন","সে"],"correct_index":0},
    "grammar_note_bn":"أُسْتَاذٌ পুরুষ শিক্ষক। মহিলার জন্য أُسْتَاذَةٌ।","difficulty":1
  },
  {
    "type":"multiple_choice","sort_order":2,
    "prompt_bn":"«تِلْمِيذٌ» শব্দের অর্থ কী?","prompt_ar":"تِلْمِيذٌ",
    "correct_answer":{"options":["শিক্ষক","ছাত্র","নতুন","সে"],"correct_index":1},
    "grammar_note_bn":"تِلْمِيذٌ পুরুষ ছাত্র।","difficulty":1
  },
  {
    "type":"drag_drop","sort_order":3,
    "prompt_bn":"আরবি শব্দের সাথে বাংলা অর্থ মেলাও:",
    "correct_answer":{"pairs":[{"ar":"أُسْتَاذٌ","bn":"শিক্ষক"},{"ar":"تِلْمِيذٌ","bn":"ছাত্র"},{"ar":"هُوَ","bn":"সে (পুরুষ)"},{"ar":"جَدِيدٌ","bn":"নতুন"}]},
    "grammar_note_bn":"এই শব্দগুলো দিয়ে আরবি বাক্য তৈরি হয়।","difficulty":2
  },
  {
    "type":"true_false","sort_order":4,
    "prompt_bn":"অনুবাদটি কি সঠিক?",
    "correct_answer":{"statement_ar":"هُوَ أُسْتَاذٌ","statement_bn":"সে একজন শিক্ষক","is_true":true},
    "grammar_note_bn":"আরবিতে 'একজন' শব্দ আলাদাভাবে লেখা হয় না — তানউয়িন (ٌ) নিজেই অনির্দিষ্টতা বোঝায়।","difficulty":2
  },
  {
    "type":"true_false","sort_order":5,
    "prompt_bn":"অনুবাদটি কি সঠিক?",
    "correct_answer":{"statement_ar":"هُوَ تِلْمِيذٌ","statement_bn":"সে একজন শিক্ষক","is_true":false},
    "grammar_note_bn":"تِلْمِيذٌ মানে ছাত্র — শিক্ষক নয়। শিক্ষকের জন্য أُسْتَاذٌ ব্যবহার হয়।","difficulty":2
  },
  {
    "type":"fill_in_blank","sort_order":6,
    "prompt_bn":"শূন্যস্থানে সঠিক শব্দ বসাও (অর্থ: নতুন):",
    "correct_answer":{"sentence":"هُوَ تِلْمِيذٌ ___","blank_index":2,"answer":"جَدِيدٌ"},
    "grammar_note_bn":"আরবিতে বিশেষণ বিশেষ্যের পরে বসে: تِلْمِيذٌ جَدِيدٌ = নতুন ছাত্র।","difficulty":3
  },
  {
    "type":"tap_to_build","sort_order":7,
    "prompt_bn":"সঠিক ক্রমে সাজাও: «সে একজন নতুন ছাত্র»",
    "correct_answer":{"words":["هُوَ","تِلْمِيذٌ","جَدِيدٌ"],"order_matters":true,"distractor_words":["أُسْتَاذٌ","هِيَ"]},
    "distractors":null,
    "grammar_note_bn":"সর্বনাম (هُوَ) → বিশেষ্য (تِلْمِيذٌ) → বিশেষণ (جَدِيدٌ)।","difficulty":4
  },
  {
    "type":"word_scramble","sort_order":8,
    "prompt_bn":"শব্দগুলো সাজিয়ে বাক্য তৈরি করো:",
    "correct_answer":{"words":["جَدِيدٌ","هُوَ","تِلْمِيذٌ"],"correct":"هُوَ تِلْمِيذٌ جَدِيدٌ"},
    "grammar_note_bn":"সঠিক ক্রম: সর্বনাম → বিশেষ্য → বিশেষণ।","difficulty":4
  }
]

════════════════════════════════════════════
CONTENT SPLITTING RULES
════════════════════════════════════════════
From ONE uploaded PDF/source material:
- Identify distinct vocabulary clusters in the content (e.g., pronouns, professions, family, colors)
- Each vocabulary cluster of 4-6 words → 1 lesson (6-10 exercises)
- Group 3-5 related lessons into 1 unit
- A 10-page textbook chapter → roughly 1 unit with 3-4 lessons

DIFFICULTY LEVELS:
- "beginner":     Simple vocabulary, pronoun sentences, no verbs (e.g. هُوَ طَالِبٌ)
- "intermediate": Verb conjugation, question forms (هَلْ/مَا), plural forms, simple past tense
- "advanced":     Complex sentences, passive voice, Quranic vocabulary with grammatical analysis

════════════════════════════════════════════
NON-NEGOTIABLE RULES
════════════════════════════════════════════
1. Arabic ALWAYS has full harakat: كِتَابٌ  NOT  كتاب
2. tap_to_build "words": ONE Arabic word per array element — ["هُوَ","أُسْتَاذٌ"] not ["هُوَ أُسْتَاذٌ"]
3. MCQ: exactly 4 options, distractors from same lesson vocab
4. DragDrop: 3-4 pairs only
5. All exercises use vocabulary from THIS LESSON's vocabulary list
6. grammar_note_bn must explain the GRAMMAR RULE (not just translate the sentence)
7. sort_order is sequential starting at 1
8. Every lesson must have at least: 2× multiple_choice, 1× drag_drop, 1× true_false, 1× fill_in_blank, 1× tap_to_build`;

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT SCHEMA (shown to Gemini as part of each request)
// ─────────────────────────────────────────────────────────────────────────────
const OUTPUT_SCHEMA = `Return ONLY a valid JSON object matching this exact schema. No markdown, no explanation.

{
  "unit_title_bn": "string — descriptive curriculum title in Bangla (e.g., 'সর্বনাম ও পরিচয়')",
  "unit_title_ar": "string — Arabic title with harakat (e.g., 'الضَّمَائِرُ وَالتَّعَارُف')",
  "lessons": [
    {
      "title_bn": "string — lesson topic in Bangla (e.g., 'পুংলিঙ্গ সর্বনাম')",
      "level": "beginner | intermediate | advanced",
      "vocabulary": [
        {
          "arabic": "string — with full harakat",
          "transliteration": "string — Latin phonetic",
          "meaning_bn": "string — Bangla meaning",
          "meaning_en": "string — English meaning",
          "word_type": "noun | verb | particle | adjective | proper_noun",
          "gender": "masculine | feminine | null",
          "grammar_note_bn": "string — grammar explanation in Bangla"
        }
      ],
      "exercises": [
        {
          "type": "multiple_choice | drag_drop | true_false | fill_in_blank | tap_to_build | word_scramble",
          "sort_order": "number — sequential from 1",
          "prompt_bn": "string — instruction in Bangla",
          "prompt_ar": "string | null — Arabic text to display (required for multiple_choice, optional for others)",
          "correct_answer": "object — see type-specific schema above",
          "distractors": "null — always null; tap_to_build uses correct_answer.distractor_words instead",
          "grammar_note_bn": "string — grammar explanation shown after answer",
          "difficulty": "1 | 2 | 3 | 4 | 5"
        }
      ]
    }
  ]
}`;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { material_id, text_content, track, notes } = await req.json();

    if (!material_id || !track) {
      return new Response(
        JSON.stringify({ error: 'material_id and track are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    await supabase
      .from('source_materials')
      .update({ processing_status: 'processing' })
      .eq('id', material_id);

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({
      model: 'gemini-3.5-flash',
      systemInstruction: SYSTEM_PROMPT,
    });

    const INLINE_LIMIT = 19 * 1024 * 1024; // 19 MB

    function toBase64(bytes: Uint8Array): string {
      let binary = '';
      const chunk = 8192;
      for (let i = 0; i < bytes.length; i += chunk) {
        binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
      }
      return btoa(binary);
    }

    async function uploadToGeminiFileApi(bytes: Uint8Array, mimeType: string): Promise<string> {
      const apiKey = Deno.env.get('GEMINI_API_KEY')!;
      const boundary = `b${Date.now()}`;
      const meta = JSON.stringify({ file: { display_name: 'content' } });
      const enc = new TextEncoder();
      const header = enc.encode(`--${boundary}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${meta}\r\n--${boundary}\r\nContent-Type: ${mimeType}\r\n\r\n`);
      const footer = enc.encode(`\r\n--${boundary}--`);
      const body = new Uint8Array(header.length + bytes.length + footer.length);
      body.set(header, 0);
      body.set(bytes, header.length);
      body.set(footer, header.length + bytes.length);
      const res = await fetch(
        `https://generativelanguage.googleapis.com/upload/v1beta/files?key=${apiKey}&uploadType=multipart`,
        {
          method: 'POST',
          headers: { 'Content-Type': `multipart/related; boundary=${boundary}` },
          body,
        }
      );
      const json = await res.json();
      if (!json.file?.uri) throw new Error(`Gemini File API upload failed: ${JSON.stringify(json)}`);
      return json.file.uri;
    }

    // Context note from admin (e.g. "Al-Asr Book 1, Lessons 19-24")
    const contextNote = notes?.trim()
      ? `\n\nAdmin context note: ${notes.trim()}`
      : '';

    const userPrompt = `Track: ${track} (conversational = daily Arabic life; quranic = Quranic/classical Arabic)${contextNote}

Output schema:
${OUTPUT_SCHEMA}

Now CREATE interactive lessons from this Arabic learning material. Follow the pedagogical rules exactly. Return only valid JSON.`;

    type Part = { text: string } | { inlineData: { data: string; mimeType: string } } | { fileData: { mimeType: string; fileUri: string } };
    let parts: Part[];

    if (text_content) {
      parts = [{ text: `${userPrompt}\n\nSource material:\n${text_content}` }];
    } else {
      const { data: matRow, error: matErr } = await supabase
        .from('source_materials')
        .select('storage_path, file_type')
        .eq('id', material_id)
        .single();
      if (matErr) throw matErr;

      const { data: fileBlob, error: fileErr } = await supabase.storage
        .from('raw-content')
        .download(matRow.storage_path);
      if (fileErr) throw fileErr;

      const fileType = (matRow.file_type as string)?.toLowerCase() || 'txt';

      if (fileType === 'txt') {
        const text = await fileBlob.text();
        parts = [{ text: `${userPrompt}\n\nSource material:\n${text}` }];
      } else if (fileType === 'pdf') {
        const bytes = new Uint8Array(await fileBlob.arrayBuffer());
        if (bytes.length > INLINE_LIMIT) {
          const fileUri = await uploadToGeminiFileApi(bytes, 'application/pdf');
          parts = [
            { fileData: { mimeType: 'application/pdf', fileUri } },
            { text: userPrompt },
          ];
        } else {
          parts = [
            { inlineData: { data: toBase64(bytes), mimeType: 'application/pdf' } },
            { text: userPrompt },
          ];
        }
      } else if (['png', 'jpg', 'jpeg'].includes(fileType)) {
        const bytes = new Uint8Array(await fileBlob.arrayBuffer());
        const mimeType = fileType === 'png' ? 'image/png' : 'image/jpeg';
        if (bytes.length > INLINE_LIMIT) {
          const fileUri = await uploadToGeminiFileApi(bytes, mimeType);
          parts = [{ fileData: { mimeType, fileUri } }, { text: userPrompt }];
        } else {
          parts = [{ inlineData: { data: toBase64(bytes), mimeType } }, { text: userPrompt }];
        }
      } else {
        throw new Error(`Unsupported file type: ${fileType}. Use pdf, txt, png, jpg, or jpeg.`);
      }
    }

    const result = await model.generateContent(parts);
    let responseText = result.response.text().trim();

    // Strip any accidental markdown fences Gemini sometimes adds
    if (responseText.startsWith('```')) {
      responseText = responseText.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
    }

    const parsed = JSON.parse(responseText);

    // Look up track ID
    const { data: trackRow } = await supabase
      .from('tracks')
      .select('id')
      .eq('slug', track)
      .single();

    const { data: unit, error: unitErr } = await supabase
      .from('units')
      .insert({
        track_id: trackRow?.id,
        slug: `${track}-${Date.now()}`,
        title_bn: parsed.unit_title_bn,
        title_ar: parsed.unit_title_ar,
        sort_order: 999,
        status: 'draft',
        source_material_id: material_id,
      })
      .select()
      .single();

    if (unitErr) throw unitErr;

    for (let li = 0; li < parsed.lessons.length; li++) {
      const lesson = parsed.lessons[li];
      const { data: lessonRow, error: lessonErr } = await supabase
        .from('lessons')
        .insert({
          unit_id: unit.id,
          title_bn: lesson.title_bn,
          sort_order: li + 1,
          level: lesson.level ?? 'beginner',
          status: 'draft',
        })
        .select()
        .single();

      if (lessonErr) throw lessonErr;

      if (lesson.exercises?.length) {
        await supabase.from('exercises').insert(
          lesson.exercises.map((ex: Record<string, unknown>, idx: number) => ({
            lesson_id: lessonRow.id,
            type: ex.type,
            sort_order: (ex.sort_order as number) ?? (idx + 1),
            prompt_bn: ex.prompt_bn,
            prompt_ar: ex.prompt_ar ?? null,
            correct_answer: ex.correct_answer,
            distractors: ex.distractors ?? null,
            grammar_note_bn: ex.grammar_note_bn ?? null,
            difficulty: ex.difficulty ?? 1,
          }))
        );
      }

      if (lesson.vocabulary?.length) {
        await supabase.from('vocabulary').insert(
          lesson.vocabulary.map((v: Record<string, unknown>) => ({
            lesson_id: lessonRow.id,
            arabic: v.arabic,
            transliteration: v.transliteration,
            meaning_bn: v.meaning_bn,
            meaning_en: v.meaning_en,
            word_type: v.word_type,
            gender: v.gender ?? null,
            grammar_note_bn: v.grammar_note_bn ?? null,
          }))
        );
      }
    }

    await supabase
      .from('source_materials')
      .update({
        processing_status: 'done',
        ai_output: parsed,
        processed_at: new Date().toISOString(),
      })
      .eq('id', material_id);

    return new Response(
      JSON.stringify({ success: true, unit_id: unit.id, lesson_count: parsed.lessons.length }),
      { headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  } catch (err) {
    console.error('process-content error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
});
