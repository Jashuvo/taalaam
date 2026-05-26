# Feature Checklist — Ta'allam
## Phase 1 = MVP. Phase 2 = Growth. Phase 3 = Full.
## Use [ ] / [x] to track progress. Claude Code will check these off.

---

## PHASE 1 — MVP (build first, test immediately)

### Infrastructure
- [x] Flutter project scaffold (main.dart + main_admin.dart)
- [x] Supabase project setup + local dev environment
- [x] Drift local database with all tables
- [x] GoRouter setup (learner routes + admin routes)
- [x] Riverpod setup with ProviderScope
- [x] Environment config (.env handling)
- [x] Arabic RTL text rendering verified
- [x] Theme system (Islamic color palette, both light/dark)

### Auth
- [x] Anonymous login (learner can start without account)
- [x] Email/password signup (optional, to save progress)
- [x] Admin login (restricted email list)
- [x] Auth state persistence across app restarts

### Learner App — Home
- [x] Track selection screen (Conversational vs Quranic)
- [x] Lesson path map (visual road through units)
- [x] Daily streak counter with flame icon
- [x] XP display and progress bar
- [x] Today's review queue indicator

### Lesson Engine (core feature)
- [x] ExerciseEngine widget (renders all 6 exercise types)
- [x] TapToBuild exercise
- [x] FillInBlank exercise
- [x] MultipleChoice exercise
- [x] DragDrop matching exercise
- [x] WordScramble exercise
- [x] TrueFalse swipe exercise
- [x] Hearts/lives system (5 hearts per lesson)
- [x] Correct/wrong feedback animation
- [x] Bangla grammar note shown after each exercise
- [x] Lesson completion screen (XP earned, accuracy %)
- [x] Arabic audio playback (cached)

### SRS (Spaced Repetition)
- [x] FSRS4Dart integration
- [x] SRS card creation on vocabulary unlock
- [x] Daily review session (separate from lessons)
- [x] Rating buttons (Again / Hard / Good / Easy)
- [x] Due card count shown on home screen

### Offline Support
- [x] Drift sync on app start (background)
- [x] PendingSync queue (actions saved while offline)
- [x] Sync on reconnect
- [x] Graceful offline indicators

### Admin Panel — Content Management
- [x] Admin login screen (web-only route)
- [x] File upload widget (PDF, image, text)
- [x] Track selector (Conversational / Quranic)
- [x] "Process with AI" button → triggers edge function
- [x] Processing status indicator
- [x] Draft lesson review list
- [x] Inline exercise editor
- [x] Vocabulary editor (per lesson)
- [x] Publish / Unpublish toggle
- [x] Unit reordering

### Supabase Edge Functions
- [x] process-content: upload → Claude API → DB insert
- [x] Text extraction from PDF uploads

---

## PHASE 2 — Growth

### Learner Features
- [x] Onboarding placement quiz (5 questions)
- [x] Streak freeze mechanic
- [x] Weekly leaderboard (anonymous usernames)
- [ ] Push notifications (prayer-time aware via Adhan API) — requires FCM / google-services.json
- [x] Du'aa shown on lesson completion (rotating collection)
- [x] Sound settings (chime on/off, Takbeer on/off)
- [ ] Bangla/English toggle (UI language) — requires full i18n system
- [x] Lesson bookmarking

### Quranic Track Specifics
- [ ] Word-by-word Quran reading mode — requires Quran word dataset
- [ ] I'rab (grammatical analysis) display toggle — requires morphology data
- [x] Root letter display for each word
- [x] Quran frequency rank shown on vocabulary

### Admin Improvements
- [x] Bulk upload (multiple files at once)
- [x] AI regenerate single exercise
- [x] Audio file upload per vocabulary item
- [x] Preview mode (see lesson as learner would)
- [x] Export unit as JSON backup

### Technical
- [ ] iOS app build + test — requires Xcode / Apple developer account
- [ ] Performance profiling (60fps on mid-range Android) — requires physical device
- [x] Crash reporting (Sentry free tier)
- [x] Analytics (PostHog free tier: 1M events/month)

---

## PHASE 3 — Full Product

### Conversational Track
- [x] AI conversation practice (roleplay as Arab speaker) — Gemini edge fn, 4 scenarios
- [ ] Speech recognition for pronunciation practice — requires platform mic API
- [x] Hajj & Umrah scenario pack — included in conversation scenarios

### Quranic Track
- [x] Tafsir passage reader (as-Sa'di text) — read-only mode, vocab + grammar notes
- [ ] Morphological analysis per word — requires morphology dataset
- [x] Memorization mode with spaced repetition — text recall, harakat-normalized

### Community
- [x] Study circles (halaqah groups, max 10) — invite code join, max 10 members, RLS migration
- [x] Shared streak challenges — streak goal per group, member leaderboard with goal badge
- [x] Progress sharing (screenshot card) — gradient card with streak/XP/du'aa

### Monetization (when commercially ready)
- [ ] One-time supporter purchase (300-500 BDT)
- [ ] bKash / Nagad payment integration
- [ ] Supporter badge in profile
- [ ] Unlock Book 2+ content for supporters

---

## NEVER-DO LIST
- [ ] No background music / autoplay audio
- [ ] No animated living creature mascot
- [ ] No subscription-trap mechanics
- [ ] No in-app currency / gem system
- [ ] No selling user data
- [ ] No ads on learner's reading/exercise screens
