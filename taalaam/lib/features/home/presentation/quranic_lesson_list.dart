import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import 'home_provider.dart';

// ── Layout constants ──────────────────────────────────────────────────────────
const _cardGap = 9.0;

// Vocabulary rows for a lesson — drives the "N শব্দ আয়ত্ত" subtitle and the
// representative Arabic word on completed cards.
final _lessonVocabProvider =
    StreamProvider.family<List<VocabEntry>, String>((ref, lessonId) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.vocabulary)
        ..where((t) => t.lessonId.equals(lessonId)))
      .watch();
});

// ── Unit header — flat scholarly panel ────────────────────────────────────────

class QuranicUnitPanel extends StatelessWidget {
  final Unit unit;
  final int unitNumber;
  final int doneCount;
  final int totalCount;
  final Color tierColor;

  const QuranicUnitPanel({
    required this.unit,
    required this.unitNumber,
    required this.doneCount,
    required this.totalCount,
    required this.tierColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unitDone = totalCount > 0 && doneCount == totalCount;

    return ClipRRect(
      borderRadius: AppRadius.smBorder,
      child: Container(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: tierColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ইউনিট $unitNumber',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: tierColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (unitDone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.brightGreen
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      size: 12, color: AppColors.brightGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    'সম্পন্ন',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.brightGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (totalCount > 0)
                            Text(
                              doneCount > 0
                                  ? '$doneCount/$totalCount পাঠ'
                                  : '$totalCount পাঠ',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        unit.titleBn,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      if (unit.titleAr != null &&
                          unit.titleAr!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            unit.titleAr!,
                            style: TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 14,
                              height: 1.7,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lesson list — serene manuscript cards ─────────────────────────────────────

class QuranicLessonList extends ConsumerStatefulWidget {
  final List<Lesson> lessons;
  final Lesson? examLesson;
  final Set<String> completedIds;
  final Color tierColor;

  const QuranicLessonList({
    required this.lessons,
    required this.examLesson,
    required this.completedIds,
    required this.tierColor,
    super.key,
  });

  @override
  ConsumerState<QuranicLessonList> createState() => _QuranicLessonListState();
}

class _QuranicLessonListState extends ConsumerState<QuranicLessonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    // +2 slots: exam banner + completion banner
    final slotCount = widget.lessons.length + 2;
    _entrance = AnimationController(
      vsync: this,
      duration: AppMotion.gentle + AppMotion.stagger * (slotCount - 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1.0;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Animation<double> _slot(int index) {
    final totalMs = _entrance.duration!.inMilliseconds;
    final startMs = AppMotion.stagger.inMilliseconds * index;
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        startMs / totalMs,
        ((startMs + AppMotion.gentle.inMilliseconds) / totalMs).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.lessons;
    final firstUndone =
        lessons.indexWhere((l) => !widget.completedIds.contains(l.id));
    final allDone = firstUndone == -1;
    final examLesson = widget.examLesson;
    final examDone =
        examLesson != null && widget.completedIds.contains(examLesson.id);

    var slot = 0;
    final children = <Widget>[const SizedBox(height: 12)];

    for (int i = 0; i < lessons.length; i++) {
      if (i > 0) children.add(const SizedBox(height: _cardGap));
      children.add(_EnterFade(
        animation: _slot(slot++),
        child: _QuranicLessonCard(
          lesson: lessons[i],
          isDone: widget.completedIds.contains(lessons[i].id),
          isCurrent: i == firstUndone,
        ),
      ));
    }

    if (examLesson != null) {
      children.add(const SizedBox(height: _cardGap));
      children.add(_EnterFade(
        animation: _slot(slot++),
        child: _QuranicExamBanner(
          examLesson: examLesson,
          isUnlocked: allDone,
          isDone: examDone,
        ),
      ));
    }

    if (allDone) {
      children.add(const SizedBox(height: _cardGap));
      children.add(_EnterFade(
        animation: _slot(slot++),
        child: const _QuranicCompletionBanner(),
      ));
    }

    children.add(const SizedBox(height: 16));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

// ── Staggered entrance (fade + slide-up, runs once) ───────────────────────────

class _EnterFade extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _EnterFade({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

// ── Individual lesson card ────────────────────────────────────────────────────

class _QuranicLessonCard extends ConsumerWidget {
  final Lesson lesson;
  final bool isDone;
  final bool isCurrent;

  const _QuranicLessonCard({
    required this.lesson,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget card;
    if (isDone) {
      final accuracy =
          (ref.watch(lessonAccuracyMapProvider).valueOrNull ?? {})[lesson.id];
      final vocab =
          ref.watch(_lessonVocabProvider(lesson.id)).valueOrNull ?? [];
      final parts = <String>[
        if (accuracy != null) '$accuracy% নির্ভুলতা',
        if (vocab.isNotEmpty) '${vocab.length} শব্দ আয়ত্ত',
      ];
      card = _CardShell(
        background: AppColors.quranicCardDone,
        border: Border.all(
            color: AppColors.brightGreen.withValues(alpha: 0.4)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brightGreen,
          ),
          child: const Icon(Icons.check_rounded,
              color: Colors.white, size: 20),
        ),
        title: lesson.titleBn,
        titleWeight: FontWeight.w600,
        subtitle: parts.isEmpty ? 'সম্পন্ন' : parts.join(' · '),
        trailing: vocab.isEmpty
            ? null
            : Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  vocab.first.arabic,
                  style: AppText.arabic(
                      fontSize: 20, color: AppColors.gold),
                ),
              ),
      );
    } else if (isCurrent) {
      final minutes =
          (lesson.xpReward / AppConstants.xpPerExercise).ceil().clamp(1, 30);
      card = _Breathing(
        child: _CardShell(
          background: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border.all(color: AppColors.gold, width: 2),
          shadows: const [
            BoxShadow(
              color: AppColors.quranicCardCurrentGlow,
              blurRadius: 14,
            ),
          ],
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.play_arrow_rounded,
                color: AppColors.gold, size: 24),
          ),
          title: lesson.titleBn,
          titleWeight: FontWeight.w700,
          subtitle: 'চালিয়ে যান · ~$minutes মিনিট · ${lesson.xpReward} XP',
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.gold, size: 24),
        ),
      );
    } else {
      card = _CardShell(
        background: theme.colorScheme.surfaceContainer,
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant
              : AppColors.quranicBorderSubtle,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Icon(Icons.menu_book_rounded,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.7),
              size: 20),
        ),
        title: lesson.titleBn,
        titleWeight: FontWeight.w600,
        subtitle: 'উন্মুক্ত — নিজের গতিতে শিখুন',
      );
    }

    return _TapScale(
      onTap: () => context.push('/lesson/${lesson.id}'),
      child: card,
    );
  }
}

// ── Shared card chrome ────────────────────────────────────────────────────────

class _CardShell extends StatelessWidget {
  final Color background;
  final BoxBorder border;
  final List<BoxShadow>? shadows;
  final Widget leading;
  final String title;
  final FontWeight titleWeight;
  final String subtitle;
  final Widget? trailing;

  const _CardShell({
    required this.background,
    required this.border,
    required this.leading,
    required this.title,
    required this.titleWeight,
    required this.subtitle,
    this.shadows,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.mdBorder,
        border: border,
        boxShadow: shadows,
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: titleWeight,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ── Exam banner — keeps existing unlock logic, calm gold styling ─────────────

class _QuranicExamBanner extends StatelessWidget {
  final Lesson examLesson;
  final bool isUnlocked;
  final bool isDone;

  const _QuranicExamBanner({
    required this.examLesson,
    required this.isUnlocked,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = isUnlocked || isDone;

    final String subtitle;
    if (isDone) {
      subtitle = 'সম্পন্ন — মাশাআল্লাহ';
    } else if (isUnlocked) {
      subtitle = 'শুরু করুন · ${examLesson.xpReward} XP';
    } else {
      subtitle = 'সব পাঠ শেষ হলে উন্মুক্ত';
    }

    return _TapScale(
      onTap: isUnlocked && !isDone
          ? () => context.push('/exam/${examLesson.id}')
          : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: active ? 0.10 : 0.06),
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: AppColors.gold.withValues(alpha: active ? 0.45 : 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isDone
                  ? Icons.emoji_events_rounded
                  : Icons.workspace_premium_rounded,
              color: AppColors.gold.withValues(alpha: active ? 1.0 : 0.5),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ইউনিট পরীক্ষা',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active
                          ? AppColors.gold
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnlocked && !isDone)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.gold, size: 24),
          ],
        ),
      ),
    );
  }
}

// ── Quiet unit-completion banner (replaces the bouncy trophy) ─────────────────

class _QuranicCompletionBanner extends StatelessWidget {
  const _QuranicCompletionBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(
            'ইউনিট সম্পন্ন — মাশাআল্লাহ',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breathing scale loop for the current-lesson card ──────────────────────────

class _Breathing extends StatefulWidget {
  final Widget child;
  const _Breathing({required this.child});

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: AppMotion.breathe);
  late final Animation<double> _scale = Tween(begin: 1.0, end: 1.015)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  bool _motionChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionChecked) return;
    _motionChecked = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Press feedback — gentle scale, no springs ─────────────────────────────────

class _TapScale extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _TapScale({required this.onTap, required this.child});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _pressed = false),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: disableAnimations ? Duration.zero : AppMotion.tap,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
