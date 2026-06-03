import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
import 'home_provider.dart';

// ── Path geometry ─────────────────────────────────────────────────────────────
const _nodeSize = 64.0;
const _rowHeight = 116.0;
const _xFractions = [0.5, 0.78, 0.5, 0.22];

// ── Tier metadata — Salafi Saudi Arabic curriculum ────────────────────────────
const _tierGradients = <int, List<Color>>{
  1: [Color(0xFF1565C0), Color(0xFF1E88E5)],
  2: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
  3: [Color(0xFFBF360C), Color(0xFFF4511E)],
  4: [Color(0xFFB71C1C), Color(0xFFE53935)],
};

// Tier 1: Core vocabulary — the most frequent Quranic nouns/pronouns
// Tier 2: Sentence construction — إضافة, na't, ḥurūf jarr (Quranic phrase patterns)
// Tier 3: Verbs — الماضي, المضارع, الأمر (essential for Quran and spoken Saudi)
// Tier 4: Classical mastery — abwāb, ishtiqāq, tafsīr-level text
const _tierNames = <int, String>{
  1: 'মৌলিক শব্দভাণ্ডার',
  2: 'বাক্য রচনা',
  3: 'ক্রিয়ার জগৎ',
  4: 'উচ্চতর শাস্ত্র',
};

const _tierNamesAr = <int, String>{
  1: 'الكلمات الأساسية',
  2: 'تركيب الجملة',
  3: 'عالم الأفعال',
  4: 'الفصحى المتقدمة',
};

const _tierDescriptions = <int, String>{
  1: 'কুরআনের সর্বাধিক ব্যবহৃত বিশেষ্য, সর্বনাম ও প্রাথমিক শব্দ',
  2: 'ইযাফা, নাত ও হরফে জার — কুরআনের বাক্যগঠনের মূলনীতি',
  3: 'মাযি, মুযারি ও আমর — কুরআন ও কথ্য আরবির অপরিহার্য ক্রিয়াপদ',
  4: 'অবওয়াব, ইশতিকাক ও তাফসিরের শাস্ত্রীয় আরবি',
};

List<Color> _tierColors(int tier) =>
    _tierGradients[tier] ?? _tierGradients[1]!;

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

// ── Body (stateful: owns the selected-tier world state) ───────────────────────

class _TrackBody extends ConsumerStatefulWidget {
  final Track track;
  const _TrackBody({required this.track});

  @override
  ConsumerState<_TrackBody> createState() => _TrackBodyState();
}

class _TrackBodyState extends ConsumerState<_TrackBody> {
  int _selectedTier = 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuranic = widget.track.slug == 'quranic';
    final unitsAsync = ref.watch(unitsForTrackProvider(widget.track.id));
    final completedAsync = ref.watch(completedLessonIdsProvider);
    final bookmarkedAsync = ref.watch(bookmarkedLessonIdsProvider);
    final gradientColors =
        isQuranic ? AppColors.gradientQuranic : AppColors.gradientConversational;

    final allUnits = unitsAsync.valueOrNull;

    // Show app bar + loader/error before units are ready
    if (allUnits == null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            _buildAppBar(gradientColors),
            SliverFillRemaining(
              child: Center(
                child: unitsAsync.hasError
                    ? Text('পাঠ লোড হচ্ছে না।',
                        style: TextStyle(color: theme.colorScheme.error))
                    : const CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      );
    }

    // Determine which tiers have content
    final availableTiers =
        allUnits.map((u) => u.tierLevel).toSet().toList()..sort();

    // If the saved tier has no units (e.g. first load or content deleted), snap to lowest
    int effectiveTier = _selectedTier;
    if (availableTiers.isNotEmpty && !availableTiers.contains(_selectedTier)) {
      effectiveTier = availableTiers.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedTier = availableTiers.first);
      });
    }

    final filteredUnits =
        allUnits.where((u) => u.tierLevel == effectiveTier).toList();
    final completedIds = completedAsync.valueOrNull ?? {};
    final bookmarkedIds = bookmarkedAsync.valueOrNull ?? {};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Collapsible track app bar ──────────────────────────────────
          _buildAppBar(gradientColors),

          // ── Sticky Duolingo-style world/section selector ───────────────
          if (availableTiers.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SectionBarDelegate(
                selectedTier: effectiveTier,
                availableTiers: availableTiers,
                allUnits: allUnits,
                onSelectTier: (t) => setState(() => _selectedTier = t),
              ),
            ),

          // ── Filtered units for the selected section ────────────────────
          filteredUnits.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty,
                              size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text(
                            'এই বিভাগে এখনও কোনো পাঠ নেই।\nশীঘ্রই আসছে ইনশাআল্লাহ!',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _UnitSection(
                      unit: filteredUnits[i],
                      unitNumber: i + 1,
                      completedIds: completedIds,
                      bookmarkedIds: bookmarkedIds,
                      tierColors: _tierColors(filteredUnits[i].tierLevel),
                    ),
                    childCount: filteredUnits.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(List<Color> gradientColors) {
    return SliverAppBar(
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
                    widget.track.nameBn,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      widget.track.nameAr,
                      style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 16,
                          height: 1.4,
                          color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sticky section bar ────────────────────────────────────────────────────────

class _SectionBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTier;
  final List<int> availableTiers;
  final List<Unit> allUnits;
  final ValueChanged<int> onSelectTier;

  static const double _h = 62.0;

  const _SectionBarDelegate({
    required this.selectedTier,
    required this.availableTiers,
    required this.allUnits,
    required this.onSelectTier,
  });

  @override
  double get minExtent => _h;
  @override
  double get maxExtent => _h;

  @override
  bool shouldRebuild(_SectionBarDelegate old) =>
      selectedTier != old.selectedTier ||
      availableTiers.length != old.availableTiers.length;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = _tierColors(selectedTier);
    final name = _tierNames[selectedTier] ?? 'বিভাগ $selectedTier';
    final nameAr = _tierNamesAr[selectedTier] ?? '';
    final unitCount =
        allUnits.where((u) => u.tierLevel == selectedTier).length;
    final idx = availableTiers.indexOf(selectedTier);
    final hasPrev = idx > 0;
    final hasNext = idx < availableTiers.length - 1;

    return Material(
      elevation: overlapsContent ? 4 : 0,
      color: colors[0],
      child: Row(
        children: [
          // ← prev section
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 28),
            onPressed: hasPrev
                ? () => onSelectTier(availableTiers[idx - 1])
                : null,
            disabledColor: Colors.white24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Center: section name + tap to pick
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showPicker(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'বিভাগ ${idx + 1} — $name',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70, size: 18),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$unitCount টি ইউনিট',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          nameAr,
                          style: const TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 12,
                              height: 1.4,
                              color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // → next section
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 28),
            onPressed: hasNext
                ? () => onSelectTier(availableTiers[idx + 1])
                : null,
            disabledColor: Colors.white24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SectionPickerSheet(
        availableTiers: availableTiers,
        selectedTier: selectedTier,
        allUnits: allUnits,
        onSelect: (tier) {
          onSelectTier(tier);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Section picker bottom sheet ───────────────────────────────────────────────

class _SectionPickerSheet extends StatelessWidget {
  final List<int> availableTiers;
  final int selectedTier;
  final List<Unit> allUnits;
  final ValueChanged<int> onSelect;

  const _SectionPickerSheet({
    required this.availableTiers,
    required this.selectedTier,
    required this.allUnits,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppRadius.xlBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined),
                const SizedBox(width: 10),
                Text('বিভাগ নির্বাচন করুন',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...availableTiers.map((tier) {
            final colors = _tierColors(tier);
            final name = _tierNames[tier] ?? 'বিভাগ $tier';
            final nameAr = _tierNamesAr[tier] ?? '';
            final desc = _tierDescriptions[tier] ?? '';
            final count = allUnits.where((u) => u.tierLevel == tier).length;
            final isSelected = tier == selectedTier;
            final tierIdx = availableTiers.indexOf(tier);

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${tierIdx + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  const SizedBox(width: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      nameAr,
                      style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '$desc • $count ইউনিট',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: colors[0])
                  : null,
              onTap: () => onSelect(tier),
            );
          }),
          const SizedBox(height: 12),
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
  final List<Color> tierColors;

  const _UnitSection({
    required this.unit,
    required this.unitNumber,
    required this.completedIds,
    required this.bookmarkedIds,
    required this.tierColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));
    final examAsync = ref.watch(examLessonForUnitProvider(unit.id));

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
              colors: tierColors,
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
            final allDone =
                lessons.every((l) => completedIds.contains(l.id));
            final examLesson = examAsync.valueOrNull;
            final examDone = examLesson != null &&
                completedIds.contains(examLesson.id);
            return Column(
              children: [
                _LessonPath(lessons: lessons, completedIds: completedIds),
                if (examLesson != null)
                  _ExamNode(
                    examLesson: examLesson,
                    isUnlocked: allDone,
                    isDone: examDone,
                  ),
              ],
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
            CustomPaint(
              size: Size(width, totalHeight),
              painter: _PathPainter(
                positions: positions,
                isDoneList:
                    lessons.map((l) => completedIds.contains(l.id)).toList(),
              ),
            ),
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
      final delta = to - from;
      final dist = delta.distance;
      final unitV = Offset(delta.dx / dist, delta.dy / dist);
      const gap = _nodeSize / 2 + 3;
      final start = from + unitV * gap;
      final end = to - unitV * gap;
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
      onLongPress: () => _showLessonTooltip(context, theme),
      child: SizedBox(
        width: _nodeSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _nodeSize,
              height: _nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(color: border, width: isCurrent ? 3.5 : 2),
                boxShadow: [
                  if (isCurrent)
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 3,
                    )
                  else if (isDone)
                    BoxShadow(
                      color: AppColors.correctTile.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Center(child: nodeIcon),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: _nodeSize + 16,
              child: Text(
                lesson.titleBn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: isDone ? 0.55 : 0.85),
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.correctTile.withValues(alpha: 0.15)
                    : isCurrent
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
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
          ],
        ),
      ),
    );
  }

  void _showLessonTooltip(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: AppRadius.xlBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.correctTile.withValues(alpha: 0.2)
                        : isCurrent
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isDone
                        ? '✓ সম্পন্ন'
                        : isCurrent
                            ? '▶ পরবর্তী'
                            : '🔒 লক',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? AppColors.correctBg
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${lesson.xpReward} XP',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lesson.titleBn,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/lesson/${lesson.id}');
                },
                child: const Text('শুরু করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exam node ─────────────────────────────────────────────────────────────────

class _ExamNode extends StatefulWidget {
  final Lesson examLesson;
  final bool isUnlocked;
  final bool isDone;

  const _ExamNode({
    required this.examLesson,
    required this.isUnlocked,
    required this.isDone,
  });

  @override
  State<_ExamNode> createState() => _ExamNodeState();
}

class _ExamNodeState extends State<_ExamNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    if (widget.isUnlocked && !widget.isDone) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_ExamNode old) {
    super.didUpdateWidget(old);
    if (widget.isUnlocked && !widget.isDone) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const examSize = 80.0;
    const gold = AppColors.gold;
    const goldDark = Color(0xFFB8860B);

    final Color bg;
    final Color borderColor;
    final Widget icon;

    if (widget.isDone) {
      bg = gold;
      borderColor = goldDark;
      icon = const Icon(Icons.emoji_events_rounded,
          color: Colors.white, size: 36);
    } else if (widget.isUnlocked) {
      bg = gold;
      borderColor = Colors.white.withValues(alpha: 0.8);
      icon =
          const Icon(Icons.shield_rounded, color: Colors.white, size: 36);
    } else {
      bg = theme.colorScheme.surfaceContainerHighest;
      borderColor = theme.colorScheme.outline.withValues(alpha: 0.4);
      icon = Icon(Icons.lock_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant, size: 28);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: GestureDetector(
          onTap: widget.isUnlocked
              ? () => context.go('/exam/${widget.examLesson.id}')
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) {
                  final glow = widget.isUnlocked && !widget.isDone
                      ? 0.3 + 0.25 * sin(_pulse.value * 2 * pi)
                      : 0.0;
                  return Container(
                    width: examSize + 24,
                    height: examSize + 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (glow > 0)
                          BoxShadow(
                            color: gold.withValues(alpha: glow),
                            blurRadius: 28,
                            spreadRadius: 8,
                          ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Center(
                  child: Container(
                    width: examSize,
                    height: examSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bg,
                      border: Border.all(color: borderColor, width: 3),
                      boxShadow: widget.isUnlocked
                          ? [
                              BoxShadow(
                                color: gold.withValues(alpha: 0.4),
                                blurRadius: 16,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: icon,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'মডিউল পরীক্ষা',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isUnlocked
                      ? gold
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isUnlocked
                      ? gold.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                  border: widget.isUnlocked
                      ? Border.all(color: gold.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  widget.isUnlocked
                      ? '${widget.examLesson.xpReward} XP • ${widget.examLesson.gemReward} 💎'
                      : 'পাঠ শেষ করুন',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: widget.isUnlocked
                        ? gold
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
