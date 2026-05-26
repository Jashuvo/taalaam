// supabase/functions/process-content/index.ts
// Triggered by admin upload. Calls Gemini API → inserts draft content into DB.
// Deploy: supabase functions deploy process-content --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const SYSTEM_PROMPT = `You are an expert Arabic language curriculum designer.
You receive raw text from Arabic learning materials (books, PDFs, worksheets).
Extract and structure the content into lessons following the EXACT JSON schema below.
Return ONLY valid JSON. No explanation. No markdown fences.

EXERCISE TYPES and their correct_answer formats:
- tap_to_build:    { "words": string[], "order_matters": boolean }
- fill_in_blank:   { "sentence": string, "blank_index": number, "answer": string }
- multiple_choice: { "options": string[], "correct_index": number }
- drag_drop:       { "pairs": [{"ar": string, "bn": string}] }
- word_scramble:   { "words": string[], "correct": string }
- true_false:      { "statement_ar": string, "statement_bn": string, "is_true": boolean }

Always include full harakat (diacritics) on Arabic text for learners.
Use Bangla (বাংলা) for all explanations and grammar notes.
Learner context: Bangladeshi Salafi Muslim beginners.`;

const OUTPUT_SCHEMA = `{
  "unit_title_bn": string,
  "unit_title_ar": string,
  "lessons": [{
    "title_bn": string,
    "level": "beginner" | "intermediate" | "advanced",
    "vocabulary": [{
      "arabic": string,
      "transliteration": string,
      "meaning_bn": string,
      "meaning_en": string,
      "word_type": "noun" | "verb" | "particle" | "adjective" | "proper_noun",
      "gender": "masculine" | "feminine" | null,
      "grammar_note_bn": string
    }],
    "exercises": [{
      "type": string,
      "prompt_bn": string,
      "prompt_ar": string | null,
      "correct_answer": object,
      "distractors": object | null,
      "grammar_note_bn": string,
      "difficulty": 1 | 2 | 3 | 4 | 5
    }]
  }]
}`;

Deno.serve(async (req: Request) => {
  try {
    const { material_id, text_content, track } = await req.json();

    if (!material_id || !track) {
      return new Response(
        JSON.stringify({ error: 'material_id and track are required' }),
        { status: 400 }
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

    const basePrompt = `Track: ${track} (conversational or quranic)\n\nOutput schema:\n${OUTPUT_SCHEMA}\n\nParse this Arabic learning material into structured lessons. Return only valid JSON.`;

    // Build content parts — Gemini reads PDFs and images natively
    type Part = { text: string } | { inlineData: { data: string; mimeType: string } };
    let parts: Part[];

    if (text_content) {
      parts = [{ text: `Track: ${track}\n\nSource material:\n${text_content}\n\nOutput schema:\n${OUTPUT_SCHEMA}\n\nParse this material into structured lessons. Return only valid JSON.` }];
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
        parts = [{ text: `Track: ${track}\n\nSource material:\n${text}\n\n${basePrompt}` }];
      } else if (fileType === 'pdf') {
        const base64 = btoa(
          String.fromCharCode(...new Uint8Array(await fileBlob.arrayBuffer()))
        );
        parts = [
          { inlineData: { data: base64, mimeType: 'application/pdf' } },
          { text: basePrompt },
        ];
      } else if (['png', 'jpg', 'jpeg'].includes(fileType)) {
        const base64 = btoa(
          String.fromCharCode(...new Uint8Array(await fileBlob.arrayBuffer()))
        );
        const mimeType = fileType === 'png' ? 'image/png' : 'image/jpeg';
        parts = [
          { inlineData: { data: base64, mimeType } },
          { text: basePrompt },
        ];
      } else {
        throw new Error(`Unsupported file type: ${fileType}. Use pdf, txt, png, jpg, or jpeg.`);
      }
    }

    const result = await model.generateContent(parts);
    const responseText = result.response.text();
    const parsed = JSON.parse(responseText);

    // Insert unit
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

    // Insert lessons, exercises, vocabulary
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
            sort_order: idx + 1,
            prompt_bn: ex.prompt_bn,
            prompt_ar: ex.prompt_ar,
            correct_answer: ex.correct_answer,
            distractors: ex.distractors,
            grammar_note_bn: ex.grammar_note_bn,
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
            gender: v.gender,
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
      JSON.stringify({ success: true, unit_id: unit.id }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('process-content error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
