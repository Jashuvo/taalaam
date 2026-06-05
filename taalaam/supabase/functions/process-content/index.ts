// supabase/functions/process-content/index.ts
// Triggered by admin upload. Calls Gemini API → inserts draft content into DB.
// Deploy: supabase functions deploy process-content --no-verify-jwt

import { GoogleGenerativeAI } from 'npm:@google/generative-ai';
import { createClient } from 'npm:@supabase/supabase-js';

// ─────────────────────────────────────────────────────────────────────────────
// SYSTEM PROMPT
// ─────────────────────────────────────────────────────────────────────────────
const SYSTEM_PROMPT = `You are an expert Arabic language Curriculum Designer, Instructional Designer, and Gamification Specialist.
You create Duolingo-style interactive micro-lessons for Bangladeshi Muslim learners (mother tongue: Bangla), with a Salafi/Islamic contextual focus (Salat, Quran, Hadith, and daily Islamic life vocabulary).

MISSION: Take raw Arabic learning material — including textbook PDFs whose Arabic text may have corrupted or missing harakat — and CREATE highly interactive, micro-learning exercises.
Do NOT just extract or label text. Every exercise must be something a learner DOES: taps tiles, matches pairs, fills blanks, chooses answers.

════════════════════════════════════════════
🚨 CRITICAL: AUTOMATED LEVEL PROFILING
════════════════════════════════════════════
Before designing the content arrays, parse the structural limits of the source
material text to evaluate its true difficulty score. You must assign a root
property named "evaluated_tier" using these strict boundaries:

- Assign "evaluated_tier": 1 (মৌলিক শব্দ ও পরিচিতি | المُفْرَدَاتُ وَالتَّعَارُفُ)
  * Content contains only absolute basic nouns (objects, locations, roles),
    detached independent pronouns, or basic demonstrative pointers (هذا/هذه).
  * ABSOLUTELY NO VERBS are present on the raw text page.

- Assign "evaluated_tier": 2 (বাক্যরীতি ও যৌগিক পদ | التَّرَاكِيبُ وَالنَّحْوُ)
  * Content introduces structured grammar configurations like the Possessive
    Construct (إضافة), Adjective-Noun agreement pairs (صفة وموصوف), or
    directional prepositional modifiers (حروف الجر).
  * ABSOLUTELY NO VERBS are present on the raw text page.

- Assign "evaluated_tier": 3 (ক্রিয়াপদ ও রূপান্তর | الأَفْعَالُ وَالصَّرْفُ)
  * Content transitions into basic 3-letter active/passive verb past or present
    tense patterns (الماضي / المضارع basics), commands (الأمر), or prohibitions
    (النهي).

- Assign "evaluated_tier": 4 (উচ্চতর শাস্ত্র ও তাফসির | عُلُومُ اللُّغَةِ وَالتَّفْسِيرُ)
  * Content features highly complex morphological tables, derived verb groups
    (الأبواب المزيدة), word root derivation dynamics (الإشتقاق), or dense
    classical Islamic/Salafi text and Tafsir fragments.

════════════════════════════════════════════
🚨 CRITICAL: AUTOMATED TRACK CLASSIFICATION
════════════════════════════════════════════
After tier profiling, classify the content into exactly one learning track.
Set the root "evaluated_track" property to one of:

- "conversational": Content teaches modern everyday spoken Arabic for daily
  life situations — greetings, shopping, directions, food, family, work,
  emotions, common Saudi/Gulf phrases. Primary purpose is spoken fluency
  for real-world conversations.

- "quranic": Content teaches Quranic vocabulary, Islamic religious terminology,
  classical Arabic grammar (نحو / صرف), morphological conjugation tables (أبواب),
  Hadith phrasing, root-letter analysis, tafsir vocabulary, or any material
  whose primary framing is understanding the Quran, Sunnah, or classical texts.
  Even if individual words appear in daily speech, classify as "quranic" when
  the instructional context is religious or classical.

TIEBREAKER: When content spans both tracks (e.g. basic nouns illustrated with
Quranic examples), default to "quranic" — the app's primary mission is
Quranic and Salafi Arabic comprehension.

════════════════════════════════════════════
HARAKAT CORRECTION (CRITICAL):
Raw PDF text often corrupts or strips Arabic vowel marks. You MUST use your Arabic linguistic knowledge to reconstruct and apply the correct full harakat on every Arabic word you output. Never output Arabic without harakat.

════════════════════════════════════════════
LEARNER PROFILE
════════════════════════════════════════════
- Mother tongue: Bangla (বাংলা)
- Goal: Understand Arabic in Salat, Quran, and daily Islamic life (Salafi/Islamic vocabulary context)
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
  distractors: { "options": ["أُسْتَاذٌ", "جَدِيدٌ"] }   ← REQUIRED: 2-3 wrong Arabic words from THIS lesson's vocabulary
  Rules:
    - sentence field: write the sentence with exactly one ___ for the blank
    - blank_index: 0-based index of the missing word
    - answer: the single Arabic word that fills the blank (with harakat)
    - distractors.options: 2-3 plausible wrong words from this lesson's vocabulary (NOT null)
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
    "distractors":{"options":["أُسْتَاذٌ","تِلْمِيذٌ"]},
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
🚨 STICK POLICY: ABSOLUTE ZERO EXCLUSION
════════════════════════════════════════════
This rule OVERRIDES any length or density concerns:
1. You MUST audit the specified pages row-by-row, column-by-column.
2. EVERY SINGLE verb or vocabulary item listed in the source text tables MUST
   appear as a vocabulary entry somewhere in the output. Zero omissions.
3. If a page has more items than the 8-word lesson limit, SPLIT across multiple
   lessons — do NOT drop items to fit the limit.
   - 15 verbs → 2 lessons (e.g. 8 + 7), each with their own exercises.
   - 11 verbs → 2 lessons (e.g. 6 + 5).
   - Each lesson still follows the MAX 8 words rule.
4. Before finalising output, run this internal self-audit:
   - Count the total number of table rows on the source pages.
   - Count the total vocabulary entries across ALL lessons in your output.
   - If (Total Generated Entries ≠ Source Row Count) → find the missing items
     and add them before outputting.

════════════════════════════════════════════
VERB TABLE (ABWAB) EXTRACTION
════════════════════════════════════════════
When the source material contains Arabic verb conjugation tables (أبواب / Abwab),
extract the following fields for every single row:

  • الماضي  (Past Tense)  → store in "arabic" field (standard dictionary form)
  • المضارع (Present Tense) → store as "يَفْعَلُ: <present>" inside grammar_note_bn
  • المصدر  (Verbal Noun) → append "| مصدر: <masdar>" to grammar_note_bn if present
  • Bengali meaning (অর্থ) → store in "meaning_bn"
  • word_type → always "verb" for verb rows
  • transliteration → phonetic of the past tense form

Example mapping for one Abwab row:
  Source row: كَتَبَ / يَكْتُبُ / كِتَابَةٌ / লিখা
  JSON output:
  {
    "arabic": "كَتَبَ",
    "transliteration": "kataba",
    "meaning_bn": "লিখা",
    "meaning_en": "to write",
    "word_type": "verb",
    "gender": null,
    "grammar_note_bn": "مضارع: يَكْتُبُ (সে লেখে) | مصدر: كِتَابَةٌ — বাব ফাতহা-যম্মা রূপ।",
    "context_snippet_ar": null,
    "context_snippet_bn": null
  }

Chapter/Bab headings from the source (e.g., "باب فَعَلَ يَفْعُلُ") should be
reflected in the lesson title_bn for that cluster of verbs.

After extracting all verb table rows, also process any surrounding grammar
explanations, example sentences, or non-table vocabulary on the same pages
per the standard content extraction rules. Do not let the verb-counting
self-audit cause you to ignore non-table content.

════════════════════════════════════════════
CONTENT EXTRACTION & DENSITY RULES
════════════════════════════════════════════
When processing textbook or PDF material:
1. Shred the Density: Break long grammar paragraphs into single-sentence Micro-Rules
   shown as grammar_note_bn. Never dump a full paragraph into one note.
2. Focus on Actionable Examples: Prefer concrete Islamic/daily-life example sentences
   over abstract grammar charts. Every grammar rule must have a Bengali sentence
   demonstrating it.
3. Vocabulary Pairing: Extract vocabulary ONLY as strict pairs with full harakat:
   [Arabic + full harakat] → [Bengali meaning]. No harakat = do not include the word.
4. Exercise Blueprint Thinking: Before writing exercises, mentally categorise each
   target sentence as: tap_to_build (sentence construction), fill_in_blank
   (target vocab/conjugation), true_false (gender/meaning check), or
   multiple_choice (recognition). Then generate exercises in that progression.

════════════════════════════════════════════
CONTENT SPLITTING RULES
════════════════════════════════════════════
From ONE uploaded PDF/source material:
- Identify distinct vocabulary clusters in the content (e.g., pronouns, professions, family, colors)
- Each vocabulary cluster of 5-8 words → 1 lesson (6-10 exercises). MAX 8 words per lesson to prevent cognitive overload.
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
6. grammar_note_bn must match the EXERCISE TYPE — write feedback the learner actually needs:
   • multiple_choice   → why the correct option is right; why common wrong options are wrong
                         Example: "أُسْتَاذٌ = শিক্ষক (পুংলিঙ্গ) — أُسْتَاذَةٌ হবে নারী শিক্ষকের জন্য।"
   • true_false        → the grammar rule being tested (gender, case, word meaning)
                         Example: "তানউয়িন (ٌ) অনির্দিষ্টতা বোঝায় — 'একজন' শব্দ আলাদা লিখতে হয় না।"
   • fill_in_blank     → why the correct word fills that slot (agreement, case, meaning)
                         Example: "বিশেষণ বিশেষ্যের পরে বসে এবং লিঙ্গে মিলতে হয়।"
   • tap_to_build      → the word-order rule demonstrated by this sentence
                         Example: "আরবিতে সর্বনাম → বিশেষ্য → বিশেষণ ক্রমে বাক্য গঠন হয়।"
   • translate_build   → what each key word/phrase means + sentence structure tip
                         Example: "فِي = এ/তে (স্থান বোঝায়) | الْمَضْنَعِ = কারখানা — فِي-এর পরে শব্দে কাসরা হয়।"
   • word_scramble     → the correct word order rule for this sentence type
   • drag_drop         → the meaning link between the paired words
   • listen_select     → what the word means and a memory tip
                         Example: "طَبِيبٌ = ডাক্তার — মনে রাখুন: طِبّ মানে চিকিৎসা।"
   • chat_complete     → why the correct reply fits the context; why wrong ones don't
   • speak_arabic      → pronunciation tip for the word
                         Example: "مَضْنَعٌ-এ 'দ্ব' উচ্চারণ জোরালো — জিহ্বার পেছন দিয়ে বলুন।"
7. sort_order is sequential starting at 1
8. Every lesson must have at least: 2× multiple_choice, 1× drag_drop, 1× true_false, 1× fill_in_blank, 1× tap_to_build

════════════════════════════════════════════
NEW EXERCISE TYPES (use in addition to the 6 above)
════════════════════════════════════════════

[translate_build] — Show Arabic sentence, learner builds Bengali translation using Bengali word chips
  DIRECTION: Arabic → Bengali (opposite of tap_to_build)
  prompt_ar: "أَنَا طَالِبٌ جَدِيدٌ"
  prompt_bn: "বাংলায় অনুবাদ করুন"
  correct_answer: { "words": ["আমি","একজন","নতুন","ছাত্র"], "order_matters": true, "distractor_words": ["শিক্ষক","পুরানো","সে"] }
  Rules:
    - "words" = Bengali translation words, one per array element
    - "distractor_words" = 2-3 wrong Bengali chips from lesson vocab meanings
    - Use vocabulary already introduced earlier in this lesson
    - difficulty: 3
    - Generate at least 1 per lesson (or 2 if lesson has 6+ words)

[chat_complete] — CONVERSATIONAL TRACK ONLY. Show a dialogue opener, learner picks the correct reply.
  prompt_bn: "কথোপকথন সম্পন্ন করুন"
  correct_answer: {
    "speaker_a_ar": "كَيْفَ حَالُكَ؟",
    "speaker_a_bn": "তুমি কেমন আছ?",
    "options": [
      {"ar": "بِخَيْرٍ، وَأَنْتَ؟", "bn": "ভালো, তুমি?"},
      {"ar": "شُكْرًا", "bn": "ধন্যবাদ"},
      {"ar": "مَعَ السَّلَامَةِ", "bn": "আল্লাহ হাফেজ"}
    ],
    "correct_index": 0
  }
  Rules:
    - ONLY generate for "conversational" track content
    - Exactly 3 options; all must use vocabulary from THIS lesson
    - speaker_a line must be from the lesson's conversational context
    - difficulty: 3

[listen_select] — Learner hears an Arabic word (TTS), picks the Bangla meaning.
  prompt_bn: "শুনুন এবং সঠিক অর্থ বেছে নিন"
  correct_answer: {
    "speak_text": "أُسْتَاذٌ",
    "mode": "ar_to_bn",
    "options": ["শিক্ষক","ছাত্র","নতুন","সে"],
    "correct_index": 0
  }
  Rules:
    - "speak_text" = the exact Arabic word/phrase to speak (with full harakat)
    - "mode" is always "ar_to_bn" for our app
    - Exactly 4 options, from THIS lesson's vocabulary
    - Generate 1-2 per lesson using KEY vocabulary words
    - difficulty: 2

[speak_arabic] — Learner speaks an Arabic word aloud; Gemini transcribes and checks pronunciation.
  prompt_bn: "এই আরবি শব্দটি বলুন"
  prompt_ar: null
  correct_answer: {
    "expected_ar": "كِتَابٌ",
    "transliteration": "kitābun",
    "meaning_bn": "বই"
  }
  Rules:
    - Generate at most 1 per lesson (pick the most important vocab word for the lesson)
    - "expected_ar" must have full harakat — this is what gets spoken and verified
    - difficulty: 2
    - Do NOT generate for chat_complete lessons (conversational only)

════════════════════════════════════════════
VARIABLE EXERCISE COUNT RULE
════════════════════════════════════════════
Do NOT use a fixed number of exercises. Scale based on vocabulary:
  - 1-3 vocab words  → generate 5-6 exercises
  - 4-5 vocab words  → generate 7-9 exercises
  - 6-8 vocab words  → generate 10-14 exercises
  Each vocabulary word MUST appear in at least 2 different exercises.
  Vary exercise types to prevent monotony — no more than 2 consecutive exercises of the same type.

════════════════════════════════════════════
NEW WORD LABELLING RULE
════════════════════════════════════════════
For the FIRST exercise that introduces each vocabulary word (always a multiple_choice or listen_select),
prefix prompt_bn with "নতুন শব্দ: " followed by the normal instruction.
Example: "নতুন শব্দ: «أُسْتَاذٌ» শব্দের অর্থ কী?"
This signals to the app that this exercise introduces a brand-new word.`;

// ─────────────────────────────────────────────────────────────────────────────
// OUTPUT SCHEMA (shown to Gemini as part of each request)
// ─────────────────────────────────────────────────────────────────────────────
const OUTPUT_SCHEMA = `Return ONLY a valid JSON object matching this exact schema. No markdown, no explanation.

{
  "evaluated_tier": "number — 1 | 2 | 3 | 4 based on profiling rules above",
  "evaluated_track": "conversational | quranic — auto-classified learning track",
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
          "grammar_note_bn": "string — grammar explanation in Bangla",
          "context_snippet_ar": "string | null — short authentic Quranic Ayah, Hadith, or classical Arabic sentence that contains this exact word (with full harakat). Must be a real, verifiable example.",
          "context_snippet_bn": "string | null — Bengali translation of context_snippet_ar"
        }
      ],
      "exercises": [
        {
          "type": "multiple_choice | drag_drop | true_false | fill_in_blank | tap_to_build | word_scramble | chat_complete | translate_build | listen_select | speak_arabic",
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

const GEMINI_MODELS = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.1-flash-lite', 'gemini-2.5-flash'];

type Part = { text: string } | { inlineData: { mimeType: string; data: string } } | { fileData: { mimeType: string; fileUri: string } };

async function geminiGenerateMultimodal(apiKey: string, parts: Part[]): Promise<string> {
  const genAI = new GoogleGenerativeAI(apiKey);
  let lastErr: unknown;
  for (const modelName of GEMINI_MODELS) {
    try {
      const m = genAI.getGenerativeModel({ model: modelName, systemInstruction: SYSTEM_PROMPT });
      const result = await m.generateContent({ contents: [{ role: 'user', parts }] });
      return result.response.text();
    } catch (err) {
      lastErr = err;
    }
  }
  const msg = lastErr instanceof Error ? lastErr.message : JSON.stringify(lastErr);
  throw new Error(`All Gemini models failed: ${msg}`);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  const denied = await checkAdmin(req); if (denied) return denied;

  try {
    // track: 'conversational' | 'quranic' | 'auto' | omitted → auto-detect via Gemini
    const { material_id, text_content, track, notes } = await req.json();

    if (!material_id) {
      return new Response(
        JSON.stringify({ error: 'material_id is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
      );
    }
    const autoDetect = !track || track === 'auto';

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    await supabase
      .from('source_materials')
      .update({ processing_status: 'processing' })
      .eq('id', material_id);

    const INLINE_LIMIT = 19 * 1024 * 1024; // 19 MB

    function toBase64(bytes: Uint8Array): string {
      let binary = '';
      const chunk = 8192;
      for (let i = 0; i < bytes.length; i += chunk) {
        binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
      }
      return btoa(binary);
    }

    /** Wrap raw PCM bytes (16-bit / 24 kHz / mono) in a WAV container. */
    function pcmToWav(pcmBytes: Uint8Array): Uint8Array {
      const sampleRate = 24000, numCh = 1, bps = 16;
      const byteRate = sampleRate * numCh * bps / 8;
      const buf = new ArrayBuffer(44 + pcmBytes.length);
      const v = new DataView(buf);
      const enc = (s: string, off: number) => [...s].forEach((c, i) => v.setUint8(off + i, c.charCodeAt(0)));
      enc('RIFF', 0); v.setUint32(4, 36 + pcmBytes.length, true); enc('WAVE', 8);
      enc('fmt ', 12); v.setUint32(16, 16, true); v.setUint16(20, 1, true);
      v.setUint16(22, numCh, true); v.setUint32(24, sampleRate, true);
      v.setUint32(28, byteRate, true); v.setUint16(32, numCh * bps / 8, true);
      v.setUint16(34, bps, true); enc('data', 36); v.setUint32(40, pcmBytes.length, true);
      new Uint8Array(buf).set(pcmBytes, 44);
      return new Uint8Array(buf);
    }

    /** Try 2.5 first, fall back to 3.1 on 429. Returns raw PCM bytes or null. */
    async function ttsGenerate(text: string): Promise<Uint8Array | null> {
      const models = ['gemini-2.5-flash-preview-tts', 'gemini-3.1-flash-tts-preview'];
      for (const model of models) {
        try {
          const r = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${Deno.env.get('GEMINI_API_KEY')}`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                contents: [{ parts: [{ text }] }],
                generationConfig: {
                  responseModalities: ['AUDIO'],
                  speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: 'Sulafat' } } },
                },
              }),
            },
          );
          if (r.status === 429) continue;
          if (!r.ok) continue;
          const d = await r.json();
          const b64: string | undefined = d?.candidates?.[0]?.content?.parts?.[0]?.inlineData?.data;
          if (b64) return Uint8Array.from(atob(b64), c => c.charCodeAt(0));
        } catch { continue; }
      }
      return null;
    }

    /** Generate Arabic TTS (with 2.5→3.1 failsafe), upload WAV to Storage.
     *  Returns public URL or null on any failure (best-effort). */
    async function generateAudio(
      speakText: string,
      lessonId: string,
    ): Promise<string | null> {
      try {
        const pcmBytes = await ttsGenerate(speakText);
        if (!pcmBytes) return null;

        const wav = pcmToWav(pcmBytes);

        // Sanitised filename: keep Arabic + alphanumeric chars, max 40
        const slug = speakText.replace(/[^؀-ۿa-zA-Z0-9]/g, '_').substring(0, 40);
        const path = `lessons/${lessonId}/${slug}_${Date.now()}.wav`;

        const { error: upErr } = await supabase.storage
          .from('audio')
          .upload(path, wav, { contentType: 'audio/wav', upsert: true });
        if (upErr) return null;

        const { data: { publicUrl } } = supabase.storage.from('audio').getPublicUrl(path);
        return publicUrl;
      } catch {
        return null; // never fail the whole import because of TTS
      }
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

    const trackInstruction = autoDetect
      ? 'Track: auto-detect — use your AUTOMATED TRACK CLASSIFICATION rules to set "evaluated_track".'
      : `Track: ${track} (conversational = daily Arabic life; quranic = Quranic/classical Arabic) — also set "evaluated_track" to match.`;

    const userPrompt = `${trackInstruction}${contextNote}

Output schema:
${OUTPUT_SCHEMA}

Now CREATE interactive lessons from this Arabic learning material. Follow the pedagogical rules exactly. Return only valid JSON.`;

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

    const timeoutPromise = new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('Gemini API timeout after 110 seconds')), 110_000)
    );
    let responseText = (await Promise.race([
      geminiGenerateMultimodal(Deno.env.get('GEMINI_API_KEY')!, parts),
      timeoutPromise,
    ])).trim();

    // Strip any accidental markdown fences Gemini sometimes adds
    if (responseText.startsWith('```')) {
      responseText = responseText.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '').trim();
    }

    const parsed = JSON.parse(responseText);

    // Resolve final track: Gemini's classification wins when auto-detect is on
    const finalTrack: string = autoDetect
      ? (parsed.evaluated_track === 'conversational' ? 'conversational' : 'quranic')
      : track;

    // Look up track ID
    const { data: trackRow } = await supabase
      .from('tracks')
      .select('id')
      .eq('slug', finalTrack)
      .single();

    // Smart tier-based insertion: slots the unit at the correct position
    // and shifts higher-tier units forward automatically.
    const unitSlug = `${finalTrack}-${Date.now()}`;
    const { data: newUnitId, error: unitErr } = await supabase.rpc('insert_and_shift_unit', {
      p_track_id: trackRow?.id,
      p_title_bn: parsed.unit_title_bn,
      p_title_ar: parsed.unit_title_ar,
      p_tier_level: parsed.evaluated_tier ?? 1,
      p_slug: unitSlug,
    });
    if (unitErr) throw unitErr;

    // Set source_material_id (slug already set by the RPC)
    await supabase
      .from('units')
      .update({ source_material_id: material_id })
      .eq('id', newUnitId);

    const unit = { id: newUnitId as string };

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
        const { data: insertedExercises } = await supabase
          .from('exercises')
          .insert(
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
          )
          .select('id, type, correct_answer');

        // Generate TTS audio for listen_select exercises (best-effort, parallel)
        if (insertedExercises) {
          const audioJobs = insertedExercises
            .filter(e => e.type === 'listen_select' && e.correct_answer?.speak_text)
            .map(async e => {
              const url = await generateAudio(e.correct_answer.speak_text, lessonRow.id);
              if (url) {
                await supabase.from('exercises').update({ audio_url: url }).eq('id', e.id);
              }
            });
          await Promise.all(audioJobs);
        }
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
            context_snippet_ar: v.context_snippet_ar ?? null,
            context_snippet_bn: v.context_snippet_bn ?? null,
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
    const message = err instanceof Error
      ? err.message
      : (typeof err === 'object' ? JSON.stringify(err) : String(err));
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
    );
  }
});
