// supabase/functions/regenerate-exercise/index.ts
// Regenerates a single exercise using Gemini AI given its lesson context.
// Deploy: supabase functions deploy regenerate-exercise --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

const SYSTEM_PROMPT = `You are an expert Arabic language curriculum designer.
Given an existing Arabic exercise and its lesson context, generate a NEW improved version
of the same exercise type. Keep the same exercise type but make the content better.
Return ONLY valid JSON matching the exact schema below. No explanation. No markdown fences.`;

Deno.serve(async (req: Request) => {
  try {
    const { exercise_id } = await req.json();

    if (!exercise_id) {
      return new Response(
        JSON.stringify({ error: 'exercise_id is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Fetch exercise + its lesson + unit + track context
    const { data: exercise, error: exErr } = await supabase
      .from('exercises')
      .select(`
        *,
        lessons (
          id, title_bn, level,
          units (
            title_bn, title_ar,
            tracks ( slug, name_en )
          )
        )
      `)
      .eq('id', exercise_id)
      .single();

    if (exErr) throw exErr;

    // Fetch sibling vocabulary for context
    const { data: vocab } = await supabase
      .from('vocabulary')
      .select('arabic, meaning_bn, word_type')
      .eq('lesson_id', exercise.lesson_id)
      .limit(10);

    const lesson = exercise.lessons;
    const unit = lesson?.units;
    const track = unit?.tracks?.slug ?? 'conversational';

    const context = `
Lesson: ${lesson?.title_bn ?? ''}
Level: ${lesson?.level ?? 'beginner'}
Unit: ${unit?.title_bn ?? ''}
Track: ${track}
Vocabulary in this lesson: ${JSON.stringify(vocab ?? [])}

Current exercise to regenerate:
Type: ${exercise.type}
Current prompt_bn: ${exercise.prompt_bn ?? ''}
Current prompt_ar: ${exercise.prompt_ar ?? ''}
Current correct_answer: ${JSON.stringify(exercise.correct_answer)}
Current grammar_note_bn: ${exercise.grammar_note_bn ?? ''}`.trim();

    const schema = getSchemaForType(exercise.type);

    const prompt = `${context}

Generate a new, improved exercise of type "${exercise.type}" for this lesson.
The exercise should test the same vocabulary/grammar but with fresh content.
Return JSON matching this schema exactly:
{
  "type": "${exercise.type}",
  "prompt_bn": string,
  "prompt_ar": string | null,
  "correct_answer": ${schema},
  "distractors": object | null,
  "grammar_note_bn": string,
  "difficulty": 1 | 2 | 3 | 4 | 5
}`;

    const genAI = new GoogleGenerativeAI(Deno.env.get('GEMINI_API_KEY')!);
    const model = genAI.getGenerativeModel({
      model: 'gemini-3.5-flash',
      systemInstruction: SYSTEM_PROMPT,
    });

    const result = await model.generateContent(prompt);
    const responseText = result.response.text();
    const newExercise = JSON.parse(responseText);

    // Update the exercise in DB
    const { error: updateErr } = await supabase
      .from('exercises')
      .update({
        prompt_bn: newExercise.prompt_bn,
        prompt_ar: newExercise.prompt_ar,
        correct_answer: newExercise.correct_answer,
        distractors: newExercise.distractors,
        grammar_note_bn: newExercise.grammar_note_bn,
        difficulty: newExercise.difficulty ?? exercise.difficulty,
      })
      .eq('id', exercise_id);

    if (updateErr) throw updateErr;

    return new Response(
      JSON.stringify({ success: true, exercise: newExercise }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('regenerate-exercise error:', err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

function getSchemaForType(type: string): string {
  switch (type) {
    case 'tap_to_build':    return '{ "words": string[], "order_matters": boolean }';
    case 'fill_in_blank':   return '{ "sentence": string, "blank_index": number, "answer": string }';
    case 'multiple_choice': return '{ "options": string[], "correct_index": number }';
    case 'drag_drop':       return '{ "pairs": [{"ar": string, "bn": string}] }';
    case 'word_scramble':   return '{ "words": string[], "correct": string }';
    case 'true_false':      return '{ "statement_ar": string, "statement_bn": string, "is_true": boolean }';
    default:                return 'object';
  }
}
