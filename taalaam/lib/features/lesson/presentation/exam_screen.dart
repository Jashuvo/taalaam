import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/widgets/arabic_audio_button.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/exercise_model.dart';
import 'lesson_provider.dart';
import 'widgets/exercise_engine.dart';

// ── Exam question loader ───────────────────────────────────────────────────────

final _examQuestionsProvider =
    FutureProvider.family<List<ExerciseModel>, String>((ref, unitId) async {
  final res = await Supabase.instance.client.functions.invoke(
    'generate-exam',
    body: {'unit_id': unitId},
  );
  final data = res.data as Map<String, dynamic>?;
  if (data == null || data['error'] != null) {
    throw Exception(data?['error'] ?? 'Failed to generate exam');
  }
  final rawExercises = data['exercises'] as List;
  return rawExercises
      .map((e) => ExerciseModel.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});

// ── Entry widget ─────────────────────────────────────────────────────────────

class ExamScreen extends ConsumerWidget {
  /// The exam lesson's DB id (used for completion tracking & metadata).
  final String examLessonId;

  const ExamScreen({required this.examLessonId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Fetch the exam lesson to get unit_id and rewards
    final examLessonAsync = ref.watch(
      StreamProvider.autoDispose
          .family<Lesson?, String>((ref, id) {
        final db = ref.watch(appDatabaseProvider);
        return (db.select(db.lessons)..where((t) => t.id.equals(id)))
            .watchSingleOrNull();
      })(examLessonId),
    );

    return examLessonAsync.when(
      loading: () => _loadingScaffold(theme, 'পরীক্ষা প্রস্তুত হচ্ছে…'),
      error: (e, _) => _errorScaffold(context, theme, '$e'),
      data: (examLesson) {
        if (examLesson == null) {
          return _errorScaffold(context, theme, 'পরীক্ষা পাওয়া যায়নি');
        }
        final questionsAsync =
            ref.watch(_examQuestionsProvider(examLesson.unitId));
        return questionsAsync.when(
          loading: () => _loadingScaffold(theme, 'AI প্রশ্ন তৈরি করছে…'),
          error: (e, _) => _errorScaffold(context, theme, '$e'),
          data: (exercises) => _ExamBody(
            examLesson: examLesson,
            exercises: exercises,
          ),
        );
      },
    );
  }

  static Widget _loadingScaffold(ThemeData theme, String msg) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_rounded,
                  size: 64, color: AppColors.gold),
              const SizedBox(height: 20),
              Text(msg,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: AppColors.gold)),
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: AppColors.gold),
            ],
          ),
        ),
      );

  static Widget _errorScaffold(
          BuildContext ctx, ThemeData theme, String err) =>
      Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => ctx.go('/home'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('পরীক্ষা লোড হয়নি: $err',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ctx.go('/home'),
                  child: const Text('হোমে ফিরুন'),
                ),
              ],
            ),
          ),
        ),
      );
}

// ── Exam body (reuses exercise engine) ───────────────────────────────────────

class _ExamBody extends ConsumerStatefulWidget {
  final Lesson examLesson;
  final List<ExerciseModel> exercises;

  const _ExamBody({required this.examLesson, required this.exercises});

  @override
  ConsumerState<_ExamBody> createState() => _ExamBodyState();
}

class _ExamBodyState extends ConsumerState<_ExamBody> {
  late final AutoDisposeStateNotifierProvider<LessonSessionNotifier,
      LessonSessionState> _sessionProvider;

  @override
  void initState() {
    super.initState();
    _sessionProvider = lessonSessionProvider(widget.exercises);
  }

  Future<void> _saveCompletion(LessonSessionState session) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final db = ref.read(appDatabaseProvider);
    final lessonId = widget.examLesson.id;
    final xp = widget.examLesson.xpReward;
    final pct = session.exercises.isEmpty
        ? 0
        : (session.correctCount / session.exercises.length * 100).round();
    final now = DateTime.now();

    await db.into(db.userProgress).insertOnConflictUpdate(
      UserProgressCompanion(
        id: drift.Value('${user.id}_$lessonId'),
        userId: drift.Value(user.id),
        lessonId: drift.Value(lessonId),
        completedAt: drift.Value(now),
        xpEarned: drift.Value(xp),
        accuracyPct: drift.Value(pct),
      ),
    );

    Supabase.instance.client.from('user_progress').upsert({
      'user_id': user.id,
      'lesson_id': lessonId,
      'completed_at': now.toIso8601String(),
      'xp_earned': xp,
      'accuracy_pct': pct,
    }, onConflict: 'user_id,lesson_id').then((_) {}).catchError((_) {});

    // Update streak/XP
    final streakRows = await (db.select(db.streaks)
          ..where((t) => t.userId.equals(user.id)))
        .get();
    final existing = streakRows.firstOrNull;
    final newXp = (existing?.totalXp ?? 0) + xp;
    await db.into(db.streaks).insertOnConflictUpdate(StreaksCompanion(
      userId: drift.Value(user.id),
      totalXp: drift.Value(newXp),
      currentStreak: drift.Value((existing?.currentStreak ?? 0)),
      longestStreak: drift.Value((existing?.longestStreak ?? 0)),
      lastActivityDate: drift.Value(now),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(_sessionProvider);

    ref.listen<LessonSessionState>(_sessionProvider, (prev, next) {
      if (next.showFeedback && !(prev?.showFeedback ?? false)) {
        if (next.lastCorrect == true) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      }
      if (next.completed && !(prev?.completed ?? false)) {
        _saveCompletion(next);
      }
    });

    if (session.completed) {
      return ExamCompleteScreen(
        examLesson: widget.examLesson,
        correctCount: session.correctCount,
        totalCount: session.exercises.length,
      );
    }

    final exercise = session.exercises[session.currentIndex] as ExerciseModel;
    final progress = (session.currentIndex + 1) / session.exercises.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1200),
        foregroundColor: AppColors.gold,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: AppColors.gold, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.xxlBorder,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  builder: (_, val, __) => LinearProgressIndicator(
                    value: val,
                    minHeight: 10,
                    backgroundColor:
                        AppColors.gold.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: List.generate(
                AppConstants.heartsPerLesson,
                (i) => Icon(
                  Icons.favorite_rounded,
                  size: 18,
                  color: i < session.hearts
                      ? Colors.red
                      : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Gold exam banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.gold.withValues(alpha: 0.1),
            child: Text(
              '📜 মডিউল পরীক্ষা  •  প্রশ্ন ${session.currentIndex + 1}/${session.exercises.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
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
          // Feedback bar
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: session.showFeedback
                ? Offset.zero
                : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: session.showFeedback ? 1 : 0,
              child: _FeedbackBar(
                isCorrect: session.lastCorrect ?? false,
                onNext: () =>
                    ref.read(_sessionProvider.notifier).next(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBar extends StatelessWidget {
  final bool isCorrect;
  final VoidCallback onNext;
  const _FeedbackBar({required this.isCorrect, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final bg =
        isCorrect ? AppColors.correctBg : AppColors.wrongBg;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      color: bg,
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCorrect ? 'সঠিক!' : 'ভুল হয়েছে',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: bg,
              minimumSize: const Size(100, 44),
            ),
            onPressed: onNext,
            child: const Text('পরের',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Module Mastered! completion screen ───────────────────────────────────────

class ExamCompleteScreen extends ConsumerStatefulWidget {
  final Lesson examLesson;
  final int correctCount;
  final int totalCount;

  const ExamCompleteScreen({
    required this.examLesson,
    required this.correctCount,
    required this.totalCount,
    super.key,
  });

  @override
  ConsumerState<ExamCompleteScreen> createState() =>
      _ExamCompleteScreenState();
}

class _ExamCompleteScreenState extends ConsumerState<ExamCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scale;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    _scale = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _scale, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _scale.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = widget.totalCount > 0
        ? (widget.correctCount / widget.totalCount * 100).round()
        : 0;
    final xp = widget.examLesson.xpReward;
    final gem = widget.examLesson.gemReward;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1A00),
      body: Stack(
        children: [
          // Gold confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              gravity: 0.15,
              emissionFrequency: 0.04,
              colors: const [
                AppColors.gold,
                Color(0xFFFFF176),
                Color(0xFFFFD54F),
                Colors.white,
                AppColors.brightGreen,
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trophy bounce-in
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: const Center(
                          child: Text('🏆',
                              style: TextStyle(fontSize: 80)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'মডিউল সম্পন্ন!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'আপনি এই মডিউলের পরীক্ষায় উত্তীর্ণ হয়েছেন!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Reward card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(
                              color:
                                  AppColors.gold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            _RewardRow(
                              icon: '⭐',
                              label: 'XP অর্জিত',
                              value: '+$xp XP',
                              color: AppColors.gold,
                              big: true,
                            ),
                            if (gem > 0) ...[
                              const Divider(
                                  color: AppColors.gold, height: 20),
                              _RewardRow(
                                icon: '💎',
                                label: 'রত্ন',
                                value: '+$gem',
                                color: Colors.lightBlueAccent,
                              ),
                            ],
                            const Divider(
                                color: AppColors.gold, height: 20),
                            _RewardRow(
                              icon: '🎯',
                              label: 'নির্ভুলতা',
                              value: '$pct%',
                              color: pct >= 70
                                  ? AppColors.brightGreen
                                  : Colors.orangeAccent,
                            ),
                            const Divider(
                                color: AppColors.gold, height: 20),
                            _RewardRow(
                              icon: '✅',
                              label: 'সঠিক উত্তর',
                              value:
                                  '${widget.correctCount} / ${widget.totalCount}',
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      FilledButton.icon(
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('হোমে ফিরুন'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => context.go('/home'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('আবার পরীক্ষা দিন'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold),
                        ),
                        onPressed: () {
                          // Pop back so ExamScreen rebuilds with fresh questions
                          context.go('/exam/${widget.examLesson.id}');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final bool big;

  const _RewardRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(icon, style: TextStyle(fontSize: big ? 22 : 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: big ? 15 : 13)),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: big ? 20 : 15,
            ),
          ),
        ],
      );
}
