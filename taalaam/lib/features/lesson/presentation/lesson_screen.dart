import 'dart:math' show sin, pi;
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/local/database.dart';
import '../../../shared/services/gamification_service.dart';
import '../../../shared/widgets/arabic_audio_button.dart';
import '../../../shared/widgets/xp_toast.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../srs/data/srs_local_source.dart';
import '../domain/exercise_model.dart';
import 'lesson_complete_screen.dart';
import 'lesson_provider.dart';
import 'widgets/exercise_engine.dart';
import 'widgets/grammar_note_sheet.dart';

// ── Exercise type label metadata ──────────────────────────────────────────────

const _typeLabels = <ExerciseType, (String, Color)>{
  ExerciseType.multipleChoice:  ('সঠিক উত্তর বেছে নিন',     Color(0xFF4F46E5)),
  ExerciseType.tapToBuild:      ('বাক্য তৈরি করুন',          AppColors.teal),
  ExerciseType.fillInBlank:     ('শূন্যস্থান পূরণ করুন',    Color(0xFFB45309)),
  ExerciseType.trueFalse:       ('সত্য না মিথ্যা?',         Color(0xFF4338CA)),
  ExerciseType.dragDrop:        ('শব্দ মিলিয়ে দিন',         Color(0xFF7C3AED)),
  ExerciseType.wordScramble:    ('বাক্য সাজান',              Color(0xFFEA580C)),
  ExerciseType.chatComplete:    ('কথোপকথন সম্পন্ন করুন',    Color(0xFF0891B2)),
  ExerciseType.translateBuild:  ('বাংলায় অনুবাদ করুন',      Color(0xFF059669)),
  ExerciseType.listenSelect:    ('শুনুন ও বেছে নিন',         Color(0xFF0284C7)),
  // Quranic types
  ExerciseType.ayahRead:        ('আয়াত পড়ুন',               Color(0xFF1B6B3A)),
  ExerciseType.tafsirRead:      ('সূরা পরিচিতি',             Color(0xFF1B6B3A)),
  ExerciseType.ayahContext:     ('আয়াতে শব্দ চিহ্নিত করুন', Color(0xFF2E7D32)),
  ExerciseType.surahTheme:      ('বিষয় চিহ্নিত করুন',       Color(0xFF2E7D32)),
  ExerciseType.reflectionCard:  ('তাদাব্বুর',                Color(0xFF7B4F00)),
  ExerciseType.rootFamily:      ('ধাতু পরিবার',              Color(0xFF1B6B3A)),
  ExerciseType.aqeedahTrue:     ('আকীদাহ যাচাই',             Color(0xFF7B4F00)),
  ExerciseType.ayahCloze:       ('আয়াত পূরণ করুন',          Color(0xFF2E7D32)),
  ExerciseType.grammarSpot:     ('শব্দ-শ্রেণী চিহ্নিত করুন', Color(0xFF1565C0)),
};

/// Exercise types that render Quranic verse / tafsir content. The wrong-answer
/// shake (item 1c) is suppressed for these — shaking ayah text reads as
/// disrespectful, so only the feedback banner appears.
const _quranicVerseTypes = {
  ExerciseType.ayahRead,
  ExerciseType.tafsirRead,
  ExerciseType.ayahContext,
  ExerciseType.surahTheme,
  ExerciseType.reflectionCard,
  ExerciseType.rootFamily,
  ExerciseType.aqeedahTrue,
  ExerciseType.ayahCloze,
  ExerciseType.grammarSpot,
  ExerciseType.ayahComplete,
  ExerciseType.ayahOrder,
  ExerciseType.patternMatch,
};

// ── Page ──────────────────────────────────────────────────────────────────────

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
  List<Map<String, String>>? _lastWrongPairs;
  int _perfectBonus = 0;
  int _firstBonus = 0;
  int _totalXpAfter = 0;
  String? _weakHint;

  @override
  void initState() {
    super.initState();
    _sessionProvider =
        lessonSessionProvider(widget.lesson.exercises as List<ExerciseModel>);
  }

  @override
  Widget build(BuildContext context) {
    final completed = ref.watch(_sessionProvider.select((s) => s.completed));
    return PageTransitionSwitcher(
      duration: AppMotion.route,
      transitionBuilder: (child, animation, secondaryAnimation) {
        if (MediaQuery.of(context).disableAnimations) return child;
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.vertical,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(completed),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final session = ref.watch(_sessionProvider);
    final vocab =
        ref.watch(lessonVocabProvider(widget.lesson.id as String)).valueOrNull ??
            const [];
    final exerciseWords = _arabicWordsFromExercises(
        session.exercises.cast<ExerciseModel>());

    // SRS cards + haptic on answer
    ref.listen<LessonSessionState>(_sessionProvider, (prev, next) {
      if ((next.showFeedback || next.showMilestone) &&
          !(prev?.showFeedback ?? false) &&
          !(prev?.showMilestone ?? false)) {
        if (next.lastCorrect == true) {
          HapticFeedback.lightImpact();
          if (!next.showFeedback) {
            final earnedBonus = next.bonusXp - (prev?.bonusXp ?? 0);
            XpToast.show(
                context, AppConstants.xpPerExercise + earnedBonus);
          }
        } else {
          HapticFeedback.mediumImpact();
        }
      }
      if (next.completed && !(prev?.completed ?? false)) {
        final user = ref.read(currentUserProvider);
        if (user == null) return;
        final db = ref.read(appDatabaseProvider);
        final lessonId = widget.lesson.id as String;
        final xp = (widget.lesson.xpReward as int? ?? 10) +
            next.correctCount * AppConstants.xpPerExercise +
            next.bonusXp;
        final pct = next.exercises.isEmpty
            ? 0
            : (next.correctCount / next.exercises.length * 100).round();
        final now = DateTime.now();

        db.into(db.userProgress).insertOnConflictUpdate(
          UserProgressCompanion(
            id: drift.Value('${user.id}_$lessonId'),
            userId: drift.Value(user.id),
            lessonId: drift.Value(lessonId),
            completedAt: drift.Value(now),
            xpEarned: drift.Value(xp),
            accuracyPct: drift.Value(pct),
            heartsRemaining: drift.Value(next.hearts),
          ),
        );

        Supabase.instance.client.from('user_progress').upsert({
          'user_id': user.id,
          'lesson_id': lessonId,
          'completed_at': now.toIso8601String(),
          'xp_earned': xp,
          'accuracy_pct': pct,
          'hearts_remaining': next.hearts,
        }, onConflict: 'user_id,lesson_id').then((_) {}).catchError((_) {});

        _updateStreak(db, user.id, xp, now);

        // Compute gamification bonuses asynchronously so they're ready
        // before the user interacts with the complete screen.
        () async {
          int perfectBonus = 0;
          int firstBonus = 0;

          if (pct == 100) {
            perfectBonus = GamificationService.perfectBonusXp;
          }
          final isFirst =
              await GamificationService.claimFirstLessonBonus(user.id);
          if (isFirst) firstBonus = GamificationService.firstLessonBonusXp;

          await GamificationService.addWeeklyXp(
              user.id, xp + perfectBonus + firstBonus);

          final streakRow = await (db.select(db.streaks)
                ..where((t) => t.userId.equals(user.id)))
              .getSingleOrNull();
          final totalXpAfter =
              (streakRow?.totalXp ?? 0) + xp + perfectBonus + firstBonus;

          final String? weakHint =
              pct < 70 ? 'নির্ভুলতা বাড়াতে এই পাঠটি আবার চেষ্টা করুন।' : null;

          if (mounted) {
            setState(() {
              _perfectBonus = perfectBonus;
              _firstBonus = firstBonus;
              _totalXpAfter = totalXpAfter;
              _weakHint = weakHint;
            });
          }
        }();

        final srs = SrsLocalSource(db);
        if (vocab.isNotEmpty) {
          for (final v in vocab) {
            srs.createCard(user.id, v.id);
          }
        } else {
          _createSrsFromExercisePairs(
              db, srs, user.id, lessonId,
              next.exercises.cast<ExerciseModel>());
        }
      }
    });

    // ── Lesson complete ────────────────────────────────────────────────────
    if (session.completed) {
      final xp = (widget.lesson.xpReward as int? ?? 10) +
          session.correctCount * AppConstants.xpPerExercise +
          session.bonusXp;
      return LessonCompleteScreen(
        lessonId: widget.lesson.id as String,
        unitId: widget.lesson.unitId as String,
        correctCount: session.correctCount,
        totalCount: session.exercises.length,
        xpEarned: xp,
        gemReward: widget.lesson.gemReward as int? ?? 0,
        perfectBonus: _perfectBonus,
        firstDayBonus: _firstBonus,
        totalXpAfter: _totalXpAfter,
        weakHint: _weakHint,
      );
    }

    // ── Milestone interstitial ─────────────────────────────────────────────
    if (session.showMilestone) {
      return _MilestoneScreen(
        count: session.consecutiveCorrect,
        onContinue: () => ref.read(_sessionProvider.notifier).dismissMilestone(),
      );
    }

    final exercise = session.exercises[session.currentIndex] as ExerciseModel;
    final theme = Theme.of(context);
    final progress = (session.currentIndex + 1) / session.exercises.length;

    // Exercise label
    final labelData = session.isMistakeRound
        ? ('আগের ভুল', theme.colorScheme.error)
        : (_typeLabels[exercise.type] ?? ('অনুশীলন', theme.colorScheme.primary));
    final isNewWord = exercise.promptBn?.startsWith('নতুন শব্দ:') ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: ClipRRect(
          borderRadius: AppRadius.xxlBorder,
          child: Container(
            height: 11,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppRadius.xxlBorder,
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: AppMotion.progress,
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: val.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.xxlBorder,
                    gradient: const LinearGradient(
                      colors: [AppColors.midGreen, AppColors.brightGreen],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: List.generate(
                AppConstants.heartsPerLesson,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: TweenSequence<double>([
                        TweenSequenceItem(
                          tween: Tween(begin: 1.0, end: 0.6)
                              .chain(CurveTween(curve: Curves.easeIn)),
                          weight: 50,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 0.6, end: 1.0)
                              .chain(CurveTween(curve: Curves.easeOut)),
                          weight: 50,
                        ),
                      ]).animate(anim),
                      child: child,
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      key: ValueKey('heart_${i}_${i < session.hearts}'),
                      size: 20,
                      color: i < session.hearts
                          ? Colors.red
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Exercise type label + NEW WORD badge ─────────────────
                  Row(
                    children: [
                      if (isNewWord)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            '⭐ নতুন শব্দ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: labelData.$2.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: labelData.$2.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          labelData.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: labelData.$2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (exercise.audioUrl != null &&
                      exercise.audioUrl!.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ArabicAudioButton(audioUrl: exercise.audioUrl),
                    ),
                  RepaintBoundary(
                    child: _ShakeOnWrong(
                      shake: session.showFeedback &&
                          session.lastCorrect == false &&
                          !_quranicVerseTypes.contains(exercise.type),
                      child: PageTransitionSwitcher(
                        duration: AppMotion.route,
                        transitionBuilder:
                            (child, animation, secondaryAnimation) {
                          if (MediaQuery.of(context).disableAnimations) {
                            return child;
                          }
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType:
                                SharedAxisTransitionType.horizontal,
                            child: child,
                          );
                        },
                        child: ExerciseEngine(
                          key: ValueKey(session.currentIndex),
                          exercise: exercise,
                          vocab: vocab,
                          extraWords: exerciseWords,
                          onAnswered: (correct) =>
                              ref.read(_sessionProvider.notifier).answer(correct),
                          onWrongPairs: (pairs) =>
                              setState(() => _lastWrongPairs = pairs),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Feedback sheet ───────────────────────────────────────────────
          AnimatedSlide(
            offset: session.showFeedback
                ? Offset.zero
                : const Offset(0, 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: session.showFeedback ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: session.showFeedback
                  ? GrammarNoteSheet(
                      correct: session.lastCorrect ?? false,
                      grammarNote: exercise.grammarNoteBn,
                      exercise: exercise,
                      vocab: vocab,
                      wrongPairs: _lastWrongPairs,
                      onNext: () {
                        setState(() => _lastWrongPairs = null);
                        ref.read(_sessionProvider.notifier).next();
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          if (session.hearts == 0 && !session.showFeedback)
            _OutOfHeartsBar(onQuit: () => context.go('/home')),
        ],
      ),
    );
  }

  static Future<void> _createSrsFromExercisePairs(
    AppDatabase db,
    SrsLocalSource srs,
    String userId,
    String lessonId,
    List<ExerciseModel> exercises,
  ) async {
    for (final ex in exercises) {
      if (ex.type != ExerciseType.dragDrop) continue;
      final pairs = ex.correctAnswer['pairs'];
      if (pairs is! List) continue;
      for (final p in pairs) {
        if (p is! Map) continue;
        final ar = p['ar']?.toString() ?? '';
        final bn = p['bn']?.toString() ?? '';
        if (ar.isEmpty || bn.isEmpty) continue;
        final vocabId = 'syn_${lessonId}_${ar.hashCode.abs()}';
        await db.into(db.vocabulary).insertOnConflictUpdate(
          VocabularyCompanion(
            id: drift.Value(vocabId),
            arabic: drift.Value(ar),
            meaningBn: drift.Value(bn),
            lessonId: drift.Value(lessonId),
          ),
        );
        await srs.createCard(userId, vocabId);
      }
    }
  }

  Future<void> _updateStreak(
      AppDatabase db, String userId, int xpEarned, DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final existing = await (db.select(db.streaks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    int newStreak;
    int newLongest;
    int newTotalXp;

    if (existing == null) {
      newStreak = 1;
      newLongest = 1;
      newTotalXp = xpEarned;
    } else {
      newTotalXp = existing.totalXp + xpEarned;
      final lastDate = existing.lastActivityDate;
      if (lastDate == null) {
        newStreak = 1;
      } else {
        final lastDay =
            DateTime(lastDate.year, lastDate.month, lastDate.day);
        final diff = today.difference(lastDay).inDays;
        if (diff == 0) {
          newStreak = existing.currentStreak;
        } else if (diff == 1) {
          newStreak = existing.currentStreak + 1;
        } else {
          newStreak = 1;
        }
      }
      newLongest = newStreak > existing.longestStreak
          ? newStreak
          : existing.longestStreak;
    }

    await db.into(db.streaks).insertOnConflictUpdate(StreaksCompanion(
          userId: drift.Value(userId),
          currentStreak: drift.Value(newStreak),
          longestStreak: drift.Value(newLongest),
          lastActivityDate: drift.Value(today),
          totalXp: drift.Value(newTotalXp),
          updatedAt: drift.Value(now),
        ));

    Supabase.instance.client.from('streaks').upsert({
      'user_id': userId,
      'current_streak': newStreak,
      'longest_streak': newLongest,
      'last_activity_date': today.toIso8601String().substring(0, 10),
      'total_xp': newTotalXp,
    }).then((_) {}).catchError((_) {});
  }

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

// ── Milestone interstitial ────────────────────────────────────────────────────

class _MilestoneScreen extends StatelessWidget {
  final int count;
  final VoidCallback onContinue;
  const _MilestoneScreen({required this.count, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 24),
                Text(
                  'অসাধারণ!',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$count সারিতে সঠিক!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Text('চালিয়ে যান'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wrong-answer shake ────────────────────────────────────────────────────────

/// Wraps the answer area and gives it a gentle horizontal shake (3 oscillations
/// over `AppMotion.gentle`) when [shake] flips to true. Suppressed for Quranic
/// verse content by the caller and for `MediaQuery.disableAnimations`.
class _ShakeOnWrong extends StatefulWidget {
  final bool shake;
  final Widget child;
  const _ShakeOnWrong({required this.shake, required this.child});

  @override
  State<_ShakeOnWrong> createState() => _ShakeOnWrongState();
}

class _ShakeOnWrongState extends State<_ShakeOnWrong>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: AppMotion.gentle);

  @override
  void didUpdateWidget(covariant _ShakeOnWrong oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake &&
        !oldWidget.shake &&
        !MediaQuery.of(context).disableAnimations) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final dx = sin(t * 3 * 2 * pi) * (1 - t) * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ── Out of hearts bar ─────────────────────────────────────────────────────────

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
