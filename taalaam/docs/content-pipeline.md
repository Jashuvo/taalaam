# Content Pipeline — Ta'allam
## How source material (PDFs, books, images) becomes structured lessons

## Overview
```
Admin uploads file
  → Supabase Storage (raw-content/)
  → Edge Function: process-content (Deno)
  → Gemini API: gemini-3.5-flash (free tier, reads PDF/image natively)
  → Structured JSON → DB (status=draft)
  → Admin reviews → edits → publishes
```

## Edge Function: supabase/functions/process-content/index.ts

```typescript
import { GoogleGenerativeAI } from "npm:@google/generative-ai";
import { createClient } from "npm:@supabase/supabase-js";

const SYSTEM_PROMPT = `You are an expert Arabic language curriculum designer.
You will receive raw text from Arabic learning materials (books, PDFs, worksheets).
Extract and structure the content into lessons following this EXACT JSON schema.
Return ONLY valid JSON. No explanation. No markdown fences.

EXERCISE TYPES and their JSON formats:
- tap_to_build: { "words": string[], "order_matters": boolean }
- fill_in_blank: { "sentence": string, "blank_index": number, "answer": string }
- multiple_choice: { "options": string[], "correct_index": number }
- drag_drop: { "pairs": [{"ar": string, "bn": string}] }
- word_scramble: { "words": string[], "correct": string }
- true_false: { "statement_ar": string, "statement_bn": string, "is_true": boolean }

For vocabulary items, always include:
- arabic (with full harakat/diacritics if possible)
- meaning_bn (Bangla translation)
- word_type (noun/verb/particle/adjective)
- grammar_note_bn (brief grammar explanation in Bangla)`;

const OUTPUT_SCHEMA = `{
  "unit_title_bn": string,
  "unit_title_ar": string,
  "lessons": [{
    "title_bn": string,
    "level": "beginner"|"intermediate"|"advanced",
    "vocabulary": [{
      "arabic": string,
      "transliteration": string,
      "meaning_bn": string,
      "meaning_en": string,
      "word_type": string,
      "gender": string|null,
      "grammar_note_bn": string
    }],
    "exercises": [{
      "type": ExerciseType,
      "prompt_bn": string,
      "prompt_ar": string|null,
      "correct_answer": object,
      "distractors": object|null,
      "grammar_note_bn": string,
      "difficulty": 1|2|3|4|5
    }]
  }]
}`;

Deno.serve(async (req) => {
  const { material_id, text_content, track } = await req.json();
  
  const client = new Anthropic();
  
  const genAI = new GoogleGenerativeAI(Deno.env.get("GEMINI_API_KEY")!);
  const model = genAI.getGenerativeModel({
    model: "gemini-3.5-flash",
    systemInstruction: SYSTEM_PROMPT,
  });

  // PDFs and images are passed as inlineData — Gemini reads them natively
  const result = await model.generateContent([
    { text: `Track: ${track}\n\nOutput schema:\n${OUTPUT_SCHEMA}\n\nParse this material and return structured lessons.` }
  ]);

  const parsed = JSON.parse(result.response.text());
  
  // Insert into DB as draft
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );
  
  // Insert unit, lessons, exercises, vocabulary
  // ... (full insertion logic)
  
  return new Response(JSON.stringify({ success: true, unit_id: newUnit.id }));
});
```

## Admin Panel Workflow (Flutter Web)
```
1. Admin Panel → Upload tab
2. Drag-drop PDF/image/text file
3. Select track (Conversational / Quranic)
4. Optional: add context note (e.g. "This is Al-'Asr Book 1, Lessons 19-24")
5. Hit "Process with AI" → uploads to Storage → triggers edge function
6. Loading indicator while processing (10-30 seconds)
7. Draft unit appears in "Review" tab
8. Admin can:
   - Edit any exercise or vocabulary item inline
   - Add/delete exercises
   - Reorder lessons
   - Set difficulty levels
   - Mark unit as "published"
9. Published content syncs to learner apps
```

## PDF and Image Handling
Gemini reads PDFs and images natively — no separate extraction library needed.
Pass the file as `inlineData` alongside the text prompt:
  ```typescript
  const result = await model.generateContent([
    { inlineData: { data: base64, mimeType: 'application/pdf' } },
    { text: prompt }
  ]);
  ```
This replaces the need for `syncfusion_flutter_pdf` entirely.

## Cost (gemini-3.5-flash free tier)
- **Free**: 1,500 requests/day — no credit card, no billing
- Processing all 200–300 lessons across every source book = well under limit
- This is a one-time admin operation, not per-learner

## Curriculum Level System
Claude assigns levels based on complexity:
- **beginner**: basic vocabulary, simple sentence patterns (Lessons 19-40)
- **intermediate**: verb conjugation, question forms, locations (Lessons 41-70)
- **advanced**: past/future tense, stories, Tafsir vocabulary (Lessons 70+)

The app automatically places learners on the path based on:
1. Onboarding quiz (5 questions)
2. Performance on first 3 lessons
