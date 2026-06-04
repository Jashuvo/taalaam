import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import '../../../data/models/vocabulary_model.dart';
import '../data/lesson_local_source.dart';
import '../data/lesson_repository.dart';
import '../domain/exercise_model.dart';
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
  final List<dynamic> exercises;
  final int currentIndex;
  final int hearts;
  final bool showFeedback;
  final bool? lastCorrect;
  final bool completed;
  final int correctCount;
  // Gamification
  final int consecutiveCorrect;
  final bool showMilestone;
  // Previous-mistakes round
  final List<int> wrongIndices;
  final bool isMistakeRound;

  const LessonSessionState({
    required this.exercises,
    this.currentIndex = 0,
    this.hearts = 5,
    this.showFeedback = false,
    this.lastCorrect,
    this.completed = false,
    this.correctCount = 0,
    this.consecutiveCorrect = 0,
    this.showMilestone = false,
    this.wrongIndices = const [],
    this.isMistakeRound = false,
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
    int? consecutiveCorrect,
    bool? showMilestone,
    List<int>? wrongIndices,
    bool? isMistakeRound,
    List<dynamic>? exercises,
  }) =>
      LessonSessionState(
        exercises: exercises ?? this.exercises,
        currentIndex: currentIndex ?? this.currentIndex,
        hearts: hearts ?? this.hearts,
        showFeedback: showFeedback ?? this.showFeedback,
        lastCorrect: lastCorrect ?? this.lastCorrect,
        completed: completed ?? this.completed,
        correctCount: correctCount ?? this.correctCount,
        consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
        showMilestone: showMilestone ?? this.showMilestone,
        wrongIndices: wrongIndices ?? this.wrongIndices,
        isMistakeRound: isMistakeRound ?? this.isMistakeRound,
      );
}

class LessonSessionNotifier extends StateNotifier<LessonSessionState> {
  LessonSessionNotifier(List<dynamic> exercises)
      : super(LessonSessionState(exercises: _smartOrder(exercises)));

  static List<dynamic> _smartOrder(List<dynamic> raw) {
    if (raw.isEmpty) return raw;
    final rng = Random();
    final shuffled = [...raw]..shuffle(rng);

    const warmupTypes = {ExerciseType.trueFalse, ExerciseType.multipleChoice};
    final warmupIdx = shuffled.indexWhere(
        (ex) => warmupTypes.contains((ex as ExerciseModel).type));
    if (warmupIdx > 0) {
      final first = shuffled.removeAt(warmupIdx);
      shuffled.insert(0, first);
    }
    return shuffled;
  }

  void answer(bool correct) {
    final newConsecutive = correct ? state.consecutiveCorrect + 1 : 0;
    final newWrong = correct
        ? state.wrongIndices
        : [...state.wrongIndices, state.currentIndex];

    // Trigger full-screen milestone at 5 or 10 in a row
    final milestone = correct &&
        !state.isMistakeRound &&
        (newConsecutive == 5 || newConsecutive == 10);

    state = state.copyWith(
      showFeedback: !milestone,
      showMilestone: milestone,
      lastCorrect: correct,
      hearts: correct ? state.hearts : (state.hearts - 1).clamp(0, 5),
      correctCount: correct ? state.correctCount + 1 : state.correctCount,
      consecutiveCorrect: newConsecutive,
      wrongIndices: newWrong,
    );
  }

  void dismissMilestone() {
    // After milestone screen, show feedback sheet for the last answer
    state = state.copyWith(showMilestone: false, showFeedback: true);
  }

  void next() {
    if (state.isLastExercise) {
      // End of main exercises: append wrong ones for the mistake round
      if (state.wrongIndices.isNotEmpty && !state.isMistakeRound) {
        final mistakeExercises = state.wrongIndices
            .map((i) => state.exercises[i])
            .toList();
        state = state.copyWith(
          showFeedback: false,
          exercises: [...state.exercises, ...mistakeExercises],
          currentIndex: state.currentIndex + 1,
          isMistakeRound: true,
          consecutiveCorrect: 0,
        );
      } else {
        state = state.copyWith(showFeedback: false, completed: true);
      }
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
