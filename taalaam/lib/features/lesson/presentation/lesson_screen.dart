import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/local/database.dart';
import '../../../shared/widgets/arabic_audio_button.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../srs/data/srs_local_source.dart';
import '../domain/exercise_model.dart';
import 'lesson_complete_screen.dart';
import 'lesson_provider.dart';
import 'widgets/exercise_engine.dart';
import 'widgets/grammar_note_sheet.dart';

class LessonScreen extends ConsumerWidget {
  final String lessonId;
  const LessonScreen({required this.lessonId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonProvider(lessonId));

    return lessonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(AppConstants.kLoadErrorBn,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
        ),
      ),
      data: (lesson) {
        if (lesson == null || lesson.exercises.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('পাঠ'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 20),
                    const Text(
                      'এই পাঠের অনুশীলন এখনো ডাউনলোড হয়নি।',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ইন্টারনেট সংযোগ নিশ্চিত করে পুনরায় চেষ্টা করুন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('পুনরায় চেষ্টা'),
                      onPressed: () =>
                          ref.invalidate(lessonProvider(lessonId)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _LessonBody(lesson: lesson);
      },
    );
  }
}

class _LessonBody extends ConsumerStatefulWidget {
  final dynamic lesson;
  const _LessonBody({required this.lesson});

  @override
  ConsumerState<_LessonBody> createState() => _LessonBodyState();
}

class _LessonBodyState extends ConsumerState<_LessonBody> {
  late final AutoDisposeStateNotifierProvider<LessonSessionNotifier,
      LessonSessionState> _sessionProvider;

  @override
  void initState() {
    super.initState();
    _sessionProvider =
        lessonSessionProvider(widget.lesson.exercises as List<ExerciseModel>);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(_sessionProvider);
    final vocab =
        ref.watch(lessonVocabProvider(widget.lesson.id as String)).valueOrNull ??
            const [];
    // Fallback words extracted from other exercises when vocabulary table is empty
    final exerciseWords = _arabicWordsFromExercises(
        session.exercises.cast<ExerciseModel>());

    // Create SRS cards for every vocab item the first time the lesson completes.
    ref.listen<LessonSessionState>(_sessionProvider, (prev, next) {
      if (next.completed && !(prev?.completed ?? false) && vocab.isNotEmpty) {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        final srs = SrsLocalSource(ref.read(appDatabaseProvider));
        for (final v in vocab) {
          srs.createCard(user.id, v.id);
        }
      }
    });

    if (session.completed) {
      final xp = (widget.lesson.xpReward as int? ?? 10) +
          session.correctCount * AppConstants.xpPerExercise;
      return LessonCompleteScreen(
        correctCount: session.correctCount,
        totalCount: session.exercises.length,
        xpEarned: xp,
      );
    }

    final exercise = session.exercises[session.currentIndex] as ExerciseModel;
    final theme = Theme.of(context);
    final progress =
        (session.currentIndex + 1) / session.exercises.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        title: LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: List.generate(
                AppConstants.heartsPerLesson,
                (i) => Icon(
                  Icons.favorite,
                  size: 20,
                  color: i < session.hearts
                      ? Colors.red
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (exercise.audioUrl != null &&
                      exercise.audioUrl!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ArabicAudioButton(audioUrl: exercise.audioUrl),
                    ),
                  RepaintBoundary(
                    child: ExerciseEngine(
                      key: ValueKey(session.currentIndex),
                      exercise: exercise,
                      vocab: vocab,
                      extraWords: exerciseWords,
                      onAnswered: (correct) =>
                          ref.read(_sessionProvider.notifier).answer(correct),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (session.showFeedback)
            GrammarNoteSheet(
              correct: session.lastCorrect ?? false,
              grammarNote: exercise.grammarNoteBn,
              exercise: exercise,
              vocab: vocab,
              onNext: () => ref.read(_sessionProvider.notifier).next(),
            ),
          if (session.hearts == 0 && !session.showFeedback)
            _OutOfHeartsBar(onQuit: () => context.go('/home')),
        ],
      ),
    );
  }
  /// Collects all Arabic words from exercises as fallback distractors
  /// for fill_in_blank when the vocabulary table has no entries for this lesson.
  static List<String> _arabicWordsFromExercises(List<ExerciseModel> exercises) {
    final words = <String>{};
    for (final ex in exercises) {
      final ca = ex.correctAnswer;
      switch (ex.type) {
        case ExerciseType.tapToBuild:
          final w = ca['words'];
          if (w is List) words.addAll(w.map((e) => e.toString()));
          final d = ca['distractor_words'];
          if (d is List) words.addAll(d.map((e) => e.toString()));
        case ExerciseType.wordScramble:
          final w = ca['words'];
          if (w is List) words.addAll(w.map((e) => e.toString()));
        case ExerciseType.fillInBlank:
          final a = ca['answer'];
          if (a is String && a.isNotEmpty) words.add(a);
        case ExerciseType.dragDrop:
          final pairs = ca['pairs'];
          if (pairs is List) {
            for (final p in pairs) {
              if (p is Map) {
                final ar = p['ar']?.toString() ?? '';
                if (ar.isNotEmpty) words.add(ar);
              }
            }
          }
        default:
          break;
      }
    }
    return words.toList();
  }
}

class _OutOfHeartsBar extends StatelessWidget {
  final VoidCallback onQuit;
  const _OutOfHeartsBar({required this.onQuit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          const Icon(Icons.heart_broken, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text('হৃদয় শেষ! পাঠ শেষ হয়েছে।',
                style: theme.textTheme.bodyMedium),
          ),
          TextButton(onPressed: onQuit, child: const Text('বের হন')),
        ],
      ),
    );
  }
}
