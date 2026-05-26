# Architecture — Ta'allam

## System Overview
```
┌─────────────────────────────────────────────────────────┐
│  LEARNER APP (Flutter)         ADMIN PANEL (Flutter Web) │
│  lib/main.dart                 lib/main_admin.dart       │
└────────────┬────────────────────────────┬───────────────┘
             │ Supabase client             │ Supabase client
             ▼                             ▼
┌─────────────────────────────────────────────────────────┐
│  SUPABASE (free tier)                                    │
│  ├── PostgreSQL DB (500MB limit)                         │
│  ├── Storage (1GB — audio files, PDFs)                   │
│  ├── Auth (email/password + anonymous)                   │
│  └── Edge Functions (Deno)                               │
│       ├── process-content/  ← Admin uploads → AI parse  │
│       └── generate-exercise/ ← Generate new exercises   │
└─────────────────────────────────────────────────────────┘
             │ Gemini API (free tier)
             ▼
┌─────────────────────────────────────────────────────────┐
│  GOOGLE GEMINI API                                       │
│  Model: gemini-3.5-flash  (free: 1,500 req/day)          │
│  Purpose: Parse source material → structured lesson JSON │
│  Bonus: reads PDFs and images natively                   │
└─────────────────────────────────────────────────────────┘
```

## Data Flow — Learner
```
App Launch
  → Load FSRS due-cards from Drift (offline)
  → Sync Supabase in background (if online)
  → User picks track (Conversational / Quranic)
  → Load lesson from Drift
  → Render exercises via ExerciseEngine
  → Score → update Drift SRS card
  → Batch sync to Supabase every 30s
```

## Data Flow — Content Pipeline (Admin)
```
Admin uploads PDF/text/image
  → Supabase Storage (raw-content bucket)
  → Triggers Edge Function: process-content
  → Edge Function calls Claude API with structured prompt
  → Claude returns JSON: { units[], lessons[], exercises[] }
  → Edge Function validates schema
  → Inserts into DB as status='draft'
  → Admin reviews on web panel
  → Admin publishes → status='published'
  → Learners see new content on next sync
```

## Two App Flavors (same codebase)
```dart
// lib/main.dart
void main() => runApp(const TaalamaApp(flavor: AppFlavor.learner));

// lib/main_admin.dart  
void main() => runApp(const TaalamaApp(flavor: AppFlavor.admin));
```
AppFlavor is passed down via a Provider. Admin-only routes/widgets check this.

## State Architecture (Riverpod)
```
UI Widget
  → watches/reads Provider
    → Provider calls Repository method
      → Repository: checks Drift first, then Supabase
        → Returns domain model
```

## FSRS (Spaced Repetition) Integration
- Package: `fsrs4dart` (pub.dev)
- Each vocabulary item = one SRS card in Drift
- Cards have: due_date, stability, difficulty, last_review
- On lesson complete: rate cards (again/hard/good/easy) → FSRS updates schedule
- Daily review queue: cards WHERE due_date <= today

## Exercise Engine (6 types — all share one interface)
```dart
abstract class Exercise {
  ExerciseType get type;
  ExerciseResult check(dynamic userAnswer);
  Widget buildWidget(ExerciseController controller);
}
```
Types: TapToBuild | FillInBlank | MultipleChoice | DragDrop | WordScramble | TrueFalse

## Offline Strategy
- All lesson content: stored in Drift after first download
- User progress: written to Drift immediately, synced to Supabase async
- Audio files: cached in device storage (flutter_cache_manager)
- No internet = full lesson functionality, only sync paused
