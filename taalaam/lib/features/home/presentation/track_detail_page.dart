import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import 'home_provider.dart';

// ── Path geometry constants ───────────────────────────────────────────────────

const _nodeSize = 64.0;
const _rowHeight = 116.0;
// Horizontal positions as fractions of available width: centre → right → centre → left
const _xFractions = [0.5, 0.78, 0.5, 0.22];

// ── Page shell ────────────────────────────────────────────────────────────────

class TrackDetailPage extends ConsumerWidget {
  final String slug;
  const TrackDetailPage({required this.slug, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackAsync = ref.watch(trackBySlugProvider(slug));
    return trackAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('ত্রুটি: $e'))),
      data: (track) {
        if (track == null) {
          return Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('কোর্স পাওয়া যায়নি')));
        }
        return _TrackBody(track: track);
      },
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _TrackBody extends ConsumerWidget {
  final Track track;
  const _TrackBody({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isQuranic = track.slug == 'quranic';
    final unitsAsync = ref.watch(unitsForTrackProvider(track.id));
    final completedAsync = ref.watch(completedLessonIdsProvider);
    final bookmarkedAsync = ref.watch(bookmarkedLessonIdsProvider);

    final gradientColors = isQuranic
        ? AppColors.gradientQuranic
        : AppColors.gradientConversational;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsible gradient app bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: gradientColors[0],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          track.nameBn,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            track.nameAr,
                            style: const TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Units + lesson path ──────────────────────────────────────────
          unitsAsync.when(
            loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                  child: Text('পাঠ লোড হচ্ছে না।',
                      style:
                          TextStyle(color: theme.colorScheme.error))),
            ),
            data: (units) {
              if (units.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty,
                              size: 64,
                              color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'এই কোর্সে এখনও কোনো পাঠ নেই।\nশীঘ্রই আসছে ইনশাআল্লাহ!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final completedIds = completedAsync.valueOrNull ?? {};
              final bookmarkedIds = bookmarkedAsync.valueOrNull ?? {};
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _UnitSection(
                    unit: units[i],
                    unitNumber: i + 1,
                    completedIds: completedIds,
                    bookmarkedIds: bookmarkedIds,
                    gradientColors: gradientColors,
                  ),
                  childCount: units.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}

// ── Unit section ──────────────────────────────────────────────────────────────

class _UnitSection extends ConsumerWidget {
  final Unit unit;
  final int unitNumber;
  final Set<String> completedIds;
  final Set<String> bookmarkedIds;
  final List<Color> gradientColors;

  const _UnitSection({
    required this.unit,
    required this.unitNumber,
    required this.completedIds,
    required this.bookmarkedIds,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Unit banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$unitNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.titleBn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (unit.titleAr != null && unit.titleAr!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          unit.titleAr!,
                          style: const TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 13,
                            height: 1.4,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Winding lesson path
        lessonsAsync.when(
          loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
          data: (lessons) {
            if (lessons.isEmpty) return const SizedBox.shrink();
            return _LessonPath(
              lessons: lessons,
              completedIds: completedIds,
            );
          },
        ),
      ],
    );
  }
}

// ── Winding path ──────────────────────────────────────────────────────────────

class _LessonPath extends StatelessWidget {
  final List<Lesson> lessons;
  final Set<String> completedIds;

  const _LessonPath({
    required this.lessons,
    required this.completedIds,
  });

  @override
  Widget build(BuildContext context) {
    final firstUndone =
        lessons.indexWhere((l) => !completedIds.contains(l.id));

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final totalHeight = lessons.length * _rowHeight + 32;

      final positions = List.generate(lessons.length, (i) {
        final xFrac = _xFractions[i % _xFractions.length];
        final x = _nodeSize / 2 + xFrac * (width - _nodeSize);
        final y = 16 + i * _rowHeight + _rowHeight / 2;
        return Offset(x, y);
      });

      return SizedBox(
        height: totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Path lines
            CustomPaint(
              size: Size(width, totalHeight),
              painter: _PathPainter(
                positions: positions,
                isDoneList: lessons
                    .map((l) => completedIds.contains(l.id))
                    .toList(),
              ),
            ),
            // Nodes
            ...List.generate(lessons.length, (i) {
              final pos = positions[i];
              return Positioned(
                left: pos.dx - _nodeSize / 2,
                top: pos.dy - _nodeSize / 2,
                child: _LessonNode(
                  lesson: lessons[i],
                  isDone: completedIds.contains(lessons[i].id),
                  isCurrent: i == firstUndone,
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

// ── Path line painter ─────────────────────────────────────────────────────────

class _PathPainter extends CustomPainter {
  final List<Offset> positions;
  final List<bool> isDoneList;

  const _PathPainter({required this.positions, required this.isDoneList});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length - 1; i++) {
      final done = isDoneList[i];
      final paint = Paint()
        ..color = done ? AppColors.correctTile : Colors.grey.shade400
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final from = positions[i];
      final to = positions[i + 1];

      // Trim start/end so the line connects node edges, not centres
      final delta = to - from;
      final dist = delta.distance;
      final unitV = Offset(delta.dx / dist, delta.dy / dist);
      const gap = _nodeSize / 2 + 3;
      final start = from + unitV * gap;
      final end = to - unitV * gap;

      // Smooth S-curve between the two node edges
      final mid = (end.dy - start.dy) * 0.45;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx, start.dy + mid,
          end.dx, end.dy - mid,
          end.dx, end.dy,
        );

      if (done) {
        canvas.drawPath(path, paint);
      } else {
        _drawDashed(canvas, path, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 8.0;
    const gap = 5.5;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final seg = draw ? dash : gap;
        final next = (dist + seg).clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(dist, next), paint);
        dist += seg;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => true;
}

// ── Individual lesson node ────────────────────────────────────────────────────

class _LessonNode extends StatelessWidget {
  final Lesson lesson;
  final bool isDone;
  final bool isCurrent;

  const _LessonNode({
    required this.lesson,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color bg;
    final Color border;
    final Widget nodeIcon;

    if (isDone) {
      bg = AppColors.correctTile;
      border = AppColors.correctBg;
      nodeIcon = const Icon(Icons.star_rounded, color: Colors.white, size: 28);
    } else if (isCurrent) {
      bg = theme.colorScheme.primary;
      border = Colors.white.withValues(alpha: 0.8);
      nodeIcon =
          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32);
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      border = theme.colorScheme.outline.withValues(alpha: 0.6);
      nodeIcon = Icon(Icons.lock_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant, size: 24);
    }

    return GestureDetector(
      onTap: () => context.go('/lesson/${lesson.id}'),
      child: SizedBox(
        width: _nodeSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle node
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _nodeSize,
              height: _nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(
                  color: border,
                  width: isCurrent ? 3.5 : 2,
                ),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 3,
                    )
                  else if (isDone)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.28),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(child: nodeIcon),
            ),
            const SizedBox(height: 5),
            // XP badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.correctTile.withValues(alpha: 0.15)
                    : isCurrent
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${lesson.xpReward} XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDone
                      ? AppColors.correctBg
                      : isCurrent
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Short title
            Text(
              lesson.titleBn,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.3,
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: isDone ? 0.6 : 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
