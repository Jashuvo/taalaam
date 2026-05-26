# Conventions — Ta'allam

## Naming
- Files: `snake_case.dart` — e.g. `exercise_engine.dart`
- Classes: `PascalCase` — e.g. `ExerciseEngine`
- Providers: `camelCaseProvider` — e.g. `currentLessonProvider`
- DB tables (Drift): `PascalCase` class, `snake_case` table name
- Supabase tables: always `snake_case`

## Feature Folder Structure (follow exactly)
```
features/lesson/
  data/
    lesson_repository.dart     # interface + impl merged (solo dev, no over-engineering)
    lesson_remote_source.dart  # Supabase queries
    lesson_local_source.dart   # Drift queries
  domain/
    lesson_model.dart          # Freezed model
    exercise_model.dart        # Freezed model
  presentation/
    lesson_screen.dart         # Screen widget
    lesson_provider.dart       # Riverpod providers
    widgets/
      exercise_engine.dart
      exercise_tap_to_build.dart
      exercise_fill_blank.dart
      # ... etc
```

## Arabic Text — ALWAYS DO THIS
```dart
// CORRECT: always wrap Arabic text in Directionality
Directionality(
  textDirection: TextDirection.rtl,
  child: Text(
    arabicText,
    style: TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 24,
      height: 1.8,  // Arabic needs more line height
    ),
  ),
)

// For mixed Bangla + Arabic in one screen
// Keep them in separate Text widgets with different directions
// NEVER mix directions in a single Text widget
```

## Freezed Models (always use this pattern)
```dart
// domain/lesson_model.dart
@freezed
class LessonModel with _$LessonModel {
  const factory LessonModel({
    required String id,
    required String titleBn,
    String? titleAr,
    required int sortOrder,
    @Default('draft') String status,
    @Default([]) List<ExerciseModel> exercises,
    @Default([]) List<VocabularyModel> vocabulary,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);
}
```

## Riverpod Providers (always annotate with @riverpod)
```dart
// presentation/lesson_provider.dart
@riverpod
class CurrentLesson extends _$CurrentLesson {
  @override
  Future<LessonModel?> build(String lessonId) async {
    return ref.watch(lessonRepositoryProvider).getLesson(lessonId);
  }
}

// Simple computed providers use riverpod annotation too
@riverpod
int streakCount(StreakCountRef ref) {
  return ref.watch(streakProvider).value?.current ?? 0;
}
```

## Repository Pattern (keep simple for solo dev)
```dart
// data/lesson_repository.dart
class LessonRepository {
  final LessonLocalSource _local;
  final LessonRemoteSource _remote;
  final ConnectivityService _connectivity;

  // Offline-first: always return local, sync remote in background
  Future<LessonModel?> getLesson(String id) async {
    final local = await _local.getLesson(id);
    if (local != null) {
      _syncInBackground(id);  // fire and forget
      return local;
    }
    // Not in cache: fetch remote and cache it
    final remote = await _remote.getLesson(id);
    if (remote != null) await _local.saveLesson(remote);
    return remote;
  }
}
```

## Exercise Engine Interface
```dart
// Every exercise implements this
abstract class ExerciseWidget extends StatelessWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  
  const ExerciseWidget({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });
}
```

## GoRouter Routes (all defined in one file)
```dart
// core/router/app_router.dart
// Learner routes: /home, /track/:trackId, /lesson/:lessonId, /review, /profile
// Admin routes: /admin, /admin/upload, /admin/review, /admin/review/:unitId
// Auth routes: /onboarding, /login
// Guard: redirect to /onboarding if no auth, redirect to /admin if admin user
```

## Performance Rules
- Use `const` constructors everywhere possible
- ListView.builder (never ListView with children for lesson lists)
- RepaintBoundary around exercise widgets (they animate frequently)
- Cache audio files (flutter_cache_manager), never re-download
- Lazy load lesson content (don't preload all units at startup)
- Profile with `flutter run --profile` before any PR

## Islamic Content Rules
- Grammar notes should reference Quran examples where possible
- Vocabulary examples should use Quranic or du'aa contexts
- Never use gender-mixed social scenarios in examples
- Use neutral names: أحمد، محمد، فاطمة، زينب، عبدالله
- All Bangla text must be grammatically correct (review with native speaker)
- Arabic text with harakat (diacritics) always preferred for learners

## Error Messages (in Bangla)
```dart
// Always show user-friendly Bangla errors, log English internally
const kNetworkErrorBn = 'ইন্টারনেট সংযোগ নেই। অফলাইনে শেখা চলবে।';
const kSyncErrorBn = 'ডেটা সংরক্ষণে সমস্যা হয়েছে। পুনরায় চেষ্টা করুন।';
const kLoadErrorBn = 'পাঠ লোড হচ্ছে না। অনুগ্রহ করে অপেক্ষা করুন।';
```
