import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import '../../../data/models/vocabulary_model.dart';
import '../data/lesson_local_source.dart';
import '../data/lesson_repository.dart';
import '../domain/lesson_model.dart';

final lessonLocalSourceProvider = Provider<LessonLocalSource>((ref) {
  return LessonLocalSource(ref.watch(appDatabaseProvider));
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  return LessonRepository(
    ref.watch(lessonLocalSourceProvider),
    Supabase.instance.client,
  );
});

final lessonProvider =
    FutureProvider.family<LessonModel?, String>((ref, lessonId) async {
  return ref.read(lessonRepositoryProvider).getLesson(lessonId);
});

final lessonVocabProvider =
    FutureProvider.family<List<VocabularyModel>, String>((ref, lessonId) async {
  return ref.read(lessonRepositoryProvider).getVocabForLesson(lessonId);
});

// ── Session state ─────────────────────────────────────────────────────────────

class LessonSessionState {
  final List<dynamic> exercises; // ExerciseModel list
  final int currentIndex;
  final int hearts;
  final bool showFeedback;
  final bool? lastCorrect;
  final bool completed;
  final int correctCount;

  const LessonSessionState({
    required this.exercises,
    this.currentIndex = 0,
    this.hearts = 5,
    this.showFeedback = false,
    this.lastCorrect,
    this.completed = false,
    this.correctCount = 0,
  });

  bool get isLastExercise => currentIndex >= exercises.length - 1;
  double get accuracy =>
      exercises.isEmpty ? 0 : correctCount / exercises.length;

  LessonSessionState copyWith({
    int? currentIndex,
    int? hearts,
    bool? showFeedback,
    bool? lastCorrect,
    bool? completed,
    int? correctCount,
  }) =>
      LessonSessionState(
        exercises: exercises,
        currentIndex: currentIndex ?? this.currentIndex,
        hearts: hearts ?? this.hearts,
        showFeedback: showFeedback ?? this.showFeedback,
        lastCorrect: lastCorrect ?? this.lastCorrect,
        completed: completed ?? this.completed,
        correctCount: correctCount ?? this.correctCount,
      );
}

class LessonSessionNotifier extends StateNotifier<LessonSessionState> {
  LessonSessionNotifier(List<dynamic> exercises)
      : super(LessonSessionState(exercises: exercises));

  void answer(bool correct) {
    state = state.copyWith(
      showFeedback: true,
      lastCorrect: correct,
      hearts: correct ? state.hearts : (state.hearts - 1).clamp(0, 5),
      correctCount: correct ? state.correctCount + 1 : state.correctCount,
    );
  }

  void next() {
    if (state.isLastExercise) {
      state = state.copyWith(showFeedback: false, completed: true);
    } else {
      state = state.copyWith(
        showFeedback: false,
        currentIndex: state.currentIndex + 1,
      );
    }
  }
}

final lessonSessionProvider = StateNotifierProvider.autoDispose
    .family<LessonSessionNotifier, LessonSessionState, List<dynamic>>(
  (ref, exercises) => LessonSessionNotifier(exercises),
);
