import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/arabic_audio_button.dart';
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
            appBar: AppBar(title: const Text('পাঠ')),
            body: const Center(
                child: Text('কোনো অনুশীলন পাওয়া যায়নি।')),
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
              onNext: () => ref.read(_sessionProvider.notifier).next(),
            ),
          if (session.hearts == 0 && !session.showFeedback)
            _OutOfHeartsBar(onQuit: () => context.go('/home')),
        ],
      ),
    );
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
