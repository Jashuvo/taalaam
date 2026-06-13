import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import '../../../shared/widgets/misbaha/duaa_card.dart';
import '../../../shared/widgets/misbaha/ornament_stamp.dart';
import '../../../shared/widgets/misbaha/stat_pill.dart';
import '../../auth/presentation/auth_provider.dart';

// Returns true if the user has NOT yet set a streak goal (show goal screen once)
final _needsStreakGoalProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final db = ref.watch(appDatabaseProvider);
  final row = await (db.select(db.streaks)
        ..where((t) => t.userId.equals(user.id)))
      .getSingleOrNull();
  return row?.streakGoal == null;
});

// Finds the next lesson after the current one within the same unit,
// then falls back to the first lesson of the next unit.
final _nextLessonProvider =
    FutureProvider.family<Lesson?, _NextLessonArgs>((ref, args) async {
  final db = ref.watch(appDatabaseProvider);

  // Next lesson in same unit
  final siblings = await (db.select(db.lessons)
        ..where((t) => t.unitId.equals(args.unitId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)]))
      .get();

  final currentIdx = siblings.indexWhere((l) => l.id == args.lessonId);
  if (currentIdx != -1 && currentIdx + 1 < siblings.length) {
    return siblings[currentIdx + 1];
  }

  // First lesson of the next unit in same track
  final currentUnit = await (db.select(db.units)
        ..where((t) => t.id.equals(args.unitId)))
      .getSingleOrNull();
  if (currentUnit == null) return null;

  final nextUnits = await (db.select(db.units)
        ..where((t) =>
            t.trackId.equals(currentUnit.trackId) &
            t.sortOrder.isBiggerThanValue(currentUnit.sortOrder))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)])
        ..limit(1))
      .get();
  if (nextUnits.isEmpty) return null;

  final firstOfNext = await (db.select(db.lessons)
        ..where((t) => t.unitId.equals(nextUnits.first.id))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.sortOrder)])
        ..limit(1))
      .get();
  return firstOfNext.isEmpty ? null : firstOfNext.first;
});

// Title of the unit this lesson belongs to, shown under the heading.
final _unitTitleProvider =
    FutureProvider.family<String?, String>((ref, unitId) async {
  final db = ref.watch(appDatabaseProvider);
  final unit = await (db.select(db.units)
        ..where((t) => t.id.equals(unitId)))
      .getSingleOrNull();
  return unit?.titleBn;
});

class _NextLessonArgs {
  final String lessonId;
  final String unitId;
  const _NextLessonArgs(this.lessonId, this.unitId);
  @override
  bool operator ==(Object o) =>
      o is _NextLessonArgs && o.lessonId == lessonId && o.unitId == unitId;
  @override
  int get hashCode => Object.hash(lessonId, unitId);
}

class LessonCompleteScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String unitId;
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final int gemReward;
  final int perfectBonus;
  final int firstDayBonus;
  final int totalXpAfter;
  final String? weakHint;

  /// Test-only: fixes the du'aa shown instead of picking one at random.
  @visibleForTesting
  final int? duaaIndex;

  const LessonCompleteScreen({
    required this.lessonId,
    required this.unitId,
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    this.gemReward = 0,
    this.perfectBonus = 0,
    this.firstDayBonus = 0,
    this.totalXpAfter = 0,
    this.weakHint,
    this.duaaIndex,
    super.key,
  });

  @override
  ConsumerState<LessonCompleteScreen> createState() =>
      _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends ConsumerState<LessonCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _entranceCtrl;
  // Picked once in initState so the du'aa doesn't change when providers
  // resolve and trigger a rebuild mid-view.
  late final String _duaa;

  // Staggered reveal order: ring -> XP card -> du'aa card -> weak hint -> buttons.
  static const _staggerCount = 5;
  static final _entranceDuration = Duration(
    milliseconds: AppMotion.gentle.inMilliseconds +
        (_staggerCount - 1) * AppMotion.completionStagger.inMilliseconds,
  );

  @override
  void initState() {
    super.initState();
    _duaa = AppConstants.completionDuaas[widget.duaaIndex ??
        Random().nextInt(AppConstants.completionDuaas.length)];
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _entranceCtrl = AnimationController(vsync: this, duration: _entranceDuration);
    // Start confetti + entrance reveal after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      if (MediaQuery.of(context).disableAnimations) {
        _entranceCtrl.value = 1;
      } else {
        _entranceCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  /// Per-item entrance animation: fade + slide-up, staggered by
  /// `AppMotion.completionStagger` per index.
  Animation<double> _entranceFor(int index) {
    final staggerMs = AppMotion.completionStagger.inMilliseconds;
    final itemMs = AppMotion.gentle.inMilliseconds;
    final totalMs = _entranceDuration.inMilliseconds;
    final start = (index * staggerMs) / totalMs;
    final end = ((start * totalMs + itemMs) / totalMs).clamp(start, 1.0);
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Widget _staggered(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceCtrl,
      builder: (context, c) {
        final v = _entranceFor(index).value;
        if (MediaQuery.of(context).disableAnimations) return c!;
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: c),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final nextLesson = ref
        .watch(_nextLessonProvider(
            _NextLessonArgs(widget.lessonId, widget.unitId)))
        .valueOrNull;
    final needsStreakGoal =
        ref.watch(_needsStreakGoalProvider).valueOrNull ?? false;
    final unitTitle = ref.watch(_unitTitleProvider(widget.unitId)).valueOrNull;
    final pct =
        widget.totalCount > 0
            ? (widget.correctCount / widget.totalCount * 100).round()
            : 0;
    final parts = _duaa.split(' — ');

    return Scaffold(
      body: Stack(
        children: [
          // ── Confetti emitter centred at top ───────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                AppColors.brightGreen,
                AppColors.gold,
                AppColors.teal,
                Colors.white,
                Color(0xFF81C784),
              ],
            ),
          ),
          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: OrnamentStamp(size: 58)),
                      const SizedBox(height: 12),
                      Text(
                        'পাঠ সম্পন্ন!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontFamily: 'HindSiliguri',
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (unitTitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          unitTitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'HindSiliguri',
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 28),
                      // Accuracy ring
                      _staggered(
                        0,
                        Center(
                          child: Column(
                            children: [
                              _AccuracyRing(pct: pct),
                              const SizedBox(height: 8),
                              Text(
                                'নির্ভুলতা',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // XP / stats pills
                      _staggered(
                        1,
                        _PerfectShimmer(
                          active: pct == 100,
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 9,
                            runSpacing: 9,
                            children: [
                              StatPill(
                                value: _CountUpNumber(
                                  value: widget.xpEarned,
                                  prefix: '+',
                                  suffix: ' XP',
                                ),
                                label: 'XP অর্জিত',
                              ),
                              StatPill(
                                value: Text('$pct%'),
                                label: 'সঠিকতা',
                              ),
                              StatPill(
                                value: Text(
                                    '${widget.correctCount}/${widget.totalCount}'),
                                label: 'সঠিক উত্তর',
                              ),
                              if (pct == 100)
                                const StatPill(
                                  value: Text('✨'),
                                  label: 'পারফেক্ট রান',
                                  gold: true,
                                ),
                              if (widget.perfectBonus > 0)
                                StatPill(
                                  value: Text('+${widget.perfectBonus} XP'),
                                  label: 'পারফেক্ট বোনাস',
                                  gold: true,
                                ),
                              if (widget.firstDayBonus > 0)
                                StatPill(
                                  value: Text('+${widget.firstDayBonus} XP'),
                                  label: 'প্রথম পাঠ বোনাস',
                                  gold: true,
                                ),
                              if (widget.gemReward > 0)
                                StatPill(
                                  value: Text('+${widget.gemReward} XP'),
                                  label: 'বোনাস XP',
                                  gold: true,
                                ),
                              if (widget.totalXpAfter > 0)
                                StatPill(
                                  value: Text('${widget.totalXpAfter} XP'),
                                  label: 'মোট XP',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Du'aa — gold-tinted manuscript card
                      _staggered(
                        2,
                        Center(
                          child: DuaaCard(
                            arabic: parts.isNotEmpty ? parts[0] : '',
                            bangla: parts.length > 1 ? parts[1] : '',
                          ),
                        ),
                      ),
                      if (widget.weakHint != null) ...[
                        const SizedBox(height: 12),
                        _staggered(
                          3,
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: AppRadius.lgBorder,
                              border: Border.all(
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded,
                                    color: theme.colorScheme.error, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.weakHint!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _staggered(
                        4,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (nextLesson != null) ...[
                              FilledButton.icon(
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: Text('পরবর্তী: ${nextLesson.titleBn}',
                                    overflow: TextOverflow.ellipsis),
                                onPressed: () =>
                                    context.push('/lesson/${nextLesson.id}'),
                              ),
                              const SizedBox(height: 10),
                            ],
                            FilledButton.icon(
                              icon: const Icon(Icons.home_rounded),
                              label: const Text('হোমে ফিরুন'),
                              style: nextLesson != null
                                  ? FilledButton.styleFrom(
                                      backgroundColor: theme
                                          .colorScheme.surfaceContainerHighest,
                                      foregroundColor:
                                          theme.colorScheme.onSurface)
                                  : null,
                              onPressed: () => context.go(
                                  needsStreakGoal ? '/streak-goal' : '/home'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('আজকের রিভিউ করুন'),
                              onPressed: () => context.push('/review'),
                            ),
                          ],
                        ),
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

/// XP/stat value that counts up from 0 on first build.
class _CountUpNumber extends StatelessWidget {
  final int value;
  final String prefix;
  final String suffix;
  const _CountUpNumber({
    required this.value,
    this.prefix = '',
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: reduceMotion ? value : 0, end: value),
      duration: reduceMotion ? Duration.zero : AppMotion.countUp,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix$v$suffix'),
    );
  }
}

/// Animated accuracy ring: sweeps from 0 to [pct]% over [AppMotion.ringSweep].
/// Color is gold for >=80% and theme primary otherwise (never red).
class _AccuracyRing extends StatelessWidget {
  final int pct;
  const _AccuracyRing({required this.pct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = pct >= 80 ? AppColors.gold : theme.colorScheme.primary;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? pct / 100 : 0.0, end: pct / 100),
      duration: reduceMotion ? Duration.zero : AppMotion.ringSweep,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: 120,
        height: 120,
        child: CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            trackColor: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: Text(
              '${(value * 100).round()}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  const _RingPainter(
      {required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

/// One-shot gold shimmer sweep across [child], played once for a perfect run.
class _PerfectShimmer extends StatefulWidget {
  final bool active;
  final Widget child;
  const _PerfectShimmer({required this.active, required this.child});

  @override
  State<_PerfectShimmer> createState() => _PerfectShimmerState();
}

class _PerfectShimmerState extends State<_PerfectShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: AppMotion.ringSweep);

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (MediaQuery.of(context).disableAnimations) return;
        _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return ClipRRect(
      borderRadius: AppRadius.lgBorder,
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) => FractionalTranslation(
                  translation: Offset(-1.5 + 3.0 * _ctrl.value, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.35, 0.5, 0.65],
                        colors: [
                          Colors.transparent,
                          AppColors.gold.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
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
