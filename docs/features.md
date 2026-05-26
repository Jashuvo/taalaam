# Feature Checklist — Ta'allam
## Phase 1 = MVP. Phase 2 = Growth. Phase 3 = Full.
## Use [ ] / [x] to track progress. Claude Code will check these off.

---

## PHASE 1 — MVP (build first, test immediately)

### Infrastructure
- [ ] Flutter project scaffold (main.dart + main_admin.dart)
- [ ] Supabase project setup + local dev environment
- [ ] Drift local database with all tables
- [ ] GoRouter setup (learner routes + admin routes)
- [ ] Riverpod setup with ProviderScope
- [ ] Environment config (.env handling)
- [ ] Arabic RTL text rendering verified
- [ ] Theme system (Islamic color palette, both light/dark)

### Auth
- [ ] Anonymous login (learner can start without account)
- [ ] Email/password signup (optional, to save progress)
- [ ] Admin login (restricted email list)
- [ ] Auth state persistence across app restarts

### Learner App — Home
- [ ] Track selection screen (Conversational vs Quranic)
- [ ] Lesson path map (visual road through units)
- [ ] Daily streak counter with flame icon
- [ ] XP display and progress bar
- [ ] Today's review queue indicator

### Lesson Engine (core feature)
- [ ] ExerciseEngine widget (renders all 6 exercise types)
- [ ] TapToBuild exercise
- [ ] FillInBlank exercise
- [ ] MultipleChoice exercise
- [ ] DragDrop matching exercise
- [ ] WordScramble exercise
- [ ] TrueFalse swipe exercise
- [ ] Hearts/lives system (5 hearts per lesson)
- [ ] Correct/wrong feedback animation
- [ ] Bangla grammar note shown after each exercise
- [ ] Lesson completion screen (XP earned, accuracy %)
- [ ] Arabic audio playback (cached)

### SRS (Spaced Repetition)
- [ ] FSRS4Dart integration
- [ ] SRS card creation on vocabulary unlock
- [ ] Daily review session (separate from lessons)
- [ ] Rating buttons (Again / Hard / Good / Easy)
- [ ] Due card count shown on home screen

### Offline Support
- [ ] Drift sync on app start (background)
- [ ] PendingSync queue (actions saved while offline)
- [ ] Sync on reconnect
- [ ] Graceful offline indicators

### Admin Panel — Content Management
- [ ] Admin login screen (web-only route)
- [ ] File upload widget (PDF, image, text)
- [ ] Track selector (Conversational / Quranic)
- [ ] "Process with AI" button → triggers edge function
- [ ] Processing status indicator
- [ ] Draft lesson review list
- [ ] Inline exercise editor
- [ ] Vocabulary editor (per lesson)
- [ ] Publish / Unpublish toggle
- [ ] Unit reordering

### Supabase Edge Functions
- [ ] process-content: upload → Claude API → DB insert
- [ ] Text extraction from PDF uploads

---

## PHASE 2 — Growth

### Learner Features
- [ ] Onboarding placement quiz (5 questions)
- [ ] Streak freeze mechanic
- [ ] Weekly leaderboard (anonymous usernames)
- [ ] Push notifications (prayer-time aware via Adhan API)
- [ ] Du'aa shown on lesson completion (rotating collection)
- [ ] Sound settings (chime on/off, Takbeer on/off)
- [ ] Bangla/English toggle (UI language)
- [ ] Lesson bookmarking

### Quranic Track Specifics
- [ ] Word-by-word Quran reading mode
- [ ] I'rab (grammatical analysis) display toggle
- [ ] Root letter display for each word
- [ ] Quran frequency rank shown on vocabulary

### Admin Improvements
- [ ] Bulk upload (multiple files at once)
- [ ] AI regenerate single exercise
- [ ] Audio file upload per vocabulary item
- [ ] Preview mode (see lesson as learner would)
- [ ] Export unit as JSON backup

### Technical
- [ ] iOS app build + test
- [ ] Performance profiling (60fps on mid-range Android)
- [ ] Crash reporting (Sentry free tier)
- [ ] Analytics (PostHog free tier: 1M events/month)

---

## PHASE 3 — Full Product

### Conversational Track
- [ ] AI conversation practice (roleplay as Arab speaker)
- [ ] Speech recognition for pronunciation practice
- [ ] Hajj & Umrah scenario pack

### Quranic Track
- [ ] Tafsir passage reader (as-Sa'di text)
- [ ] Morphological analysis per word
- [ ] Memorization mode with spaced repetition

### Community
- [ ] Study circles (halaqah groups, max 10)
- [ ] Shared streak challenges
- [ ] Progress sharing (screenshot card)

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
