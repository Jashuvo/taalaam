import 'dart:math' show cos, pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tap_scale.dart';
import '../../../data/local/database.dart';
import '../../../shared/utils/bn_digits.dart';
import '../../../shared/widgets/misbaha/misbaha_beads.dart';
import '../../../shared/widgets/misbaha/misbaha_cord_painter.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../track_quran/presentation/widgets/quran_coverage_ring.dart';
import '../../track_quran/presentation/widgets/tadabbur_card.dart';
import 'home_provider.dart';
import 'quranic_lesson_list.dart';

// ── Path geometry ─────────────────────────────────────────────────────────────
const _nodeSize   = 68.0;
const _rowHeight  = 122.0;
const _xFractions = [0.5, 0.80, 0.5, 0.20];

// ── Tier metadata — theme-aligned colours ─────────────────────────────────────
//  T1 teal  · T2 forest-green  · T3 amber-brown  · T4 deep-violet
const _tierGradients = <int, List<Color>>{
  1: [AppColors.teal,            AppColors.tealLight],
  2: [AppColors.forestGreen,     AppColors.midGreen],
  3: [Color(0xFF78350F),         Color(0xFFB45309)],
  4: [Color(0xFF3B0764),         Color(0xFF7C3AED)],
};

const _tierNames = <int, String>{
  1: 'মৌলিক শব্দ ও পরিচিতি',
  2: 'বাক্যরীতি ও যৌগিক পদ',
  3: 'ক্রিয়াপদ ও রূপান্তর',
  4: 'উচ্চতর শাস্ত্র ও তাফসির',
};

const _tierNamesAr = <int, String>{
  1: 'المُفْرَدَاتُ وَالتَّعَارُفُ',
  2: 'التَّرَاكِيبُ وَالنَّحْوُ',
  3: 'الأَفْعَالُ وَالصَّرْفُ',
  4: 'عُلُومُ اللُّغَةِ وَالتَّفْسِيرُ',
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

// ── Body ──────────────────────────────────────────────────────────────────────

class _TrackBody extends ConsumerStatefulWidget {
  final Track track;
  const _TrackBody({required this.track});

  @override
  ConsumerState<_TrackBody> createState() => _TrackBodyState();
}

class _TrackBodyState extends ConsumerState<_TrackBody> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQuranic = widget.track.slug == 'quranic';
    final unitsAsync      = ref.watch(unitsForTrackProvider(widget.track.id));
    final completedAsync  = ref.watch(completedLessonIdsProvider);
    final bookmarkedAsync = ref.watch(bookmarkedLessonIdsProvider);
    final trackGradient   =
        isQuranic ? AppColors.gradientQuranic : AppColors.gradientConversational;

    final allUnits = unitsAsync.valueOrNull;
    if (allUnits == null) {
      return Scaffold(
        backgroundColor: theme.brightness == Brightness.dark ? null : AppColors.paper,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: _TrackHeaderBanner(
              track: widget.track,
              isQuranic: isQuranic,
              gradient: trackGradient,
              allUnits: const [],
              completedIds: const {},
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: unitsAsync.hasError
                  ? Text('পাঠ লোড হচ্ছে না।',
                      style: TextStyle(color: theme.colorScheme.error))
                  : const TrackDetailSkeleton(),
            ),
          ),
        ]),
      );
    }

    final completedIds  = completedAsync.valueOrNull  ?? {};
    final bookmarkedIds = bookmarkedAsync.valueOrNull ?? {};

    // Group units by tier, sorted
    final tierGroups = <int, List<Unit>>{};
    for (final u in allUnits) {
      (tierGroups[u.tierLevel] ??= []).add(u);
    }
    final sortedTiers = tierGroups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark ? null : AppColors.paper,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _TrackHeaderBanner(
              track: widget.track,
              isQuranic: isQuranic,
              gradient: trackGradient,
              allUnits: allUnits,
              completedIds: completedIds,
            ),
          ),
          if (allUnits.isEmpty)
            const SliverToBoxAdapter(child: _EmptyTierPlaceholder())
          else if (isQuranic)
            SliverToBoxAdapter(
              child: Builder(builder: (_) {
                final items = <Widget>[];
                // Flat Quranic layout — no tier banners, no UpNext cards
                // All units open; sorted by sort_order
                final sortedUnits = [...allUnits]
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                final userId = ref.watch(currentUserProvider)?.id;
                if (userId != null) {
                  items.add(QuranCoverageRing(userId: userId));
                  items.add(TadabburCard(userId: userId));
                }
                items.add(const _QuranicCurriculumHeader());
                for (int ui = 0; ui < sortedUnits.length; ui++) {
                  items.add(_UnitSection(
                    unit: sortedUnits[ui],
                    unitNumber: ui + 1,
                    completedIds: completedIds,
                    bookmarkedIds: bookmarkedIds,
                    tierColors: const [Color(0xFF1B6B3A), Color(0xFF2E8B57)],
                    isQuranic: true,
                  ));
                }
                items.add(const SizedBox(height: 80));
                return Column(children: items);
              }),
            )
          else
            ..._buildConversationalSlivers(
                sortedTiers, tierGroups, completedIds, bookmarkedIds),
        ],
      ),
    );
  }

  /// Conversational (non-Quranic) layout: each unit's banner becomes a
  /// pinned [SliverPersistentHeader] that stacks/swaps natively as the
  /// user scrolls through that unit's lesson path.
  List<Widget> _buildConversationalSlivers(
    List<int> sortedTiers,
    Map<int, List<Unit>> tierGroups,
    Set<String> completedIds,
    Set<String> bookmarkedIds,
  ) {
    final slivers = <Widget>[];
    for (int ti = 0; ti < sortedTiers.length; ti++) {
      final tier  = sortedTiers[ti];
      final units = tierGroups[tier]!;
      final tierColors = _tierColors(tier);
      slivers.add(SliverToBoxAdapter(
        child: _TierSectionBanner(tier: tier, sectionIndex: ti + 1),
      ));
      for (int ui = 0; ui < units.length; ui++) {
        final unit = units[ui];
        final lessons =
            ref.watch(lessonsForUnitProvider(unit.id)).valueOrNull ?? [];
        final doneCount =
            lessons.where((l) => completedIds.contains(l.id)).length;
        slivers.add(SliverPersistentHeader(
          pinned: true,
          delegate: _UnitHeaderDelegate(
            unit: unit,
            unitNumber: ui + 1,
            tierColors: tierColors,
            doneCount: doneCount,
            totalCount: lessons.length,
          ),
        ));
        slivers.add(SliverToBoxAdapter(
          child: _UnitSection(
            unit: unit,
            unitNumber: ui + 1,
            completedIds: completedIds,
            bookmarkedIds: bookmarkedIds,
            tierColors: tierColors,
            isQuranic: false,
          ),
        ));
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 80)));
    return slivers;
  }

}

// ── Track header banner — gradient card with progress + unit chips ────────────

class _TrackHeaderBanner extends ConsumerWidget {
  final Track track;
  final bool isQuranic;
  final List<Color> gradient;
  final List<Unit> allUnits;
  final Set<String> completedIds;

  const _TrackHeaderBanner({
    required this.track,
    required this.isQuranic,
    required this.gradient,
    required this.allUnits,
    required this.completedIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(trackProgressProvider(track.id)).valueOrNull;
    final total = progress?.total ?? 0;
    final completed = progress?.completed ?? 0;
    final fraction = total == 0 ? 0.0 : completed / total;
    final eyebrow = isQuranic ? 'কুরআনিক ট্র্যাক' : 'কথোপকথন ট্র্যাক';
    final bigGlyph = track.nameAr.isNotEmpty ? track.nameAr.substring(0, 1) : '';

    String? activeUnitId;
    final sortedUnits = [...allUnits]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (isQuranic) {
      for (final u in sortedUnits) {
        final lessons = ref.watch(lessonsForUnitProvider(u.id)).valueOrNull ?? [];
        if (lessons.isEmpty) continue;
        final done = lessons.where((l) => completedIds.contains(l.id)).length;
        if (done < lessons.length) {
          activeUnitId = u.id;
          break;
        }
      }
      activeUnitId ??= sortedUnits.isNotEmpty ? sortedUnits.last.id : null;
    }

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 11, 18, 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(26),
            bottomRight: Radius.circular(26),
          ),
        ),
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (bigGlyph.isNotEmpty)
                Positioned(
                  right: -10,
                  bottom: -26,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      bigGlyph,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 92,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).canPop()
                            ? Navigator.of(context).pop()
                            : context.go('/home'),
                        child: Container(
                          width: 31,
                          height: 31,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    track.nameBn,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cream,
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      track.nameAr,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 14.5,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 7,
                            backgroundColor: Colors.white.withValues(alpha: 0.22),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${bnDigits(completed)}/${bnDigits(total)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ],
                  ),
                  if (isQuranic && sortedUnits.isNotEmpty) ...[
                    const SizedBox(height: 11),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final u in sortedUnits)
                          _UnitChip(label: u.titleBn, active: u.id == activeUnitId),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  final String label;
  final bool active;
  const _UnitChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}

// ── Sticky unit header ───────────────────────────────────────────────────────

/// Compact pinned header for the conversational path: shows the active
/// unit's number/title + progress, pinning below the AppBar while its
/// lessons scroll past, then swapping for the next unit's header.
class _UnitHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Unit unit;
  final int unitNumber;
  final List<Color> tierColors;
  final int doneCount;
  final int totalCount;

  const _UnitHeaderDelegate({
    required this.unit,
    required this.unitNumber,
    required this.tierColors,
    required this.doneCount,
    required this.totalCount,
  });

  static const double _height = 52.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unitDone = totalCount > 0 && doneCount == totalCount;

    return Material(
      elevation: overlapsContent ? 4 : 0,
      shadowColor: tierColors[0].withValues(alpha: 0.3),
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: tierColors[0], width: 4),
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ইউনিট $unitNumber · ${unit.titleBn}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            if (totalCount > 0)
              Text(
                unitDone ? 'সম্পন্ন' : '$doneCount/$totalCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: unitDone ? AppColors.brightGreen : tierColors[0],
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _UnitHeaderDelegate oldDelegate) {
    return unit.id != oldDelegate.unit.id ||
        unitNumber != oldDelegate.unitNumber ||
        doneCount != oldDelegate.doneCount ||
        totalCount != oldDelegate.totalCount ||
        tierColors != oldDelegate.tierColors;
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyTierPlaceholder extends StatelessWidget {
  const _EmptyTierPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 340,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty_rounded,
                size: 56, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'এই বিভাগে এখনও কোনো পাঠ নেই',
              style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'শীঘ্রই আসছে ইনশাআল্লাহ!',
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outlineVariant),
            ),
          ],
        ),
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
  final bool isQuranic;

  const _UnitSection({
    required this.unit,
    required this.unitNumber,
    required this.completedIds,
    required this.bookmarkedIds,
    required this.tierColors,
    required this.isQuranic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));
    final examAsync    = ref.watch(examLessonForUnitProvider(unit.id));

    // Compute unit progress
    final lessons     = lessonsAsync.valueOrNull ?? [];
    final doneCount   = lessons.where((l) => completedIds.contains(l.id)).length;
    final totalCount  = lessons.length;
    final unitDone    = totalCount > 0 && doneCount == totalCount;
    final unitStarted = doneCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Unit banner card ──────────────────────────────────────────────
          if (isQuranic)
            QuranicUnitPanel(
              unit: unit,
              unitNumber: unitNumber,
              doneCount: doneCount,
              totalCount: totalCount,
              tierColor: tierColors[0],
            )
          else
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCard
                  : AppColors.lightCard,
              borderRadius: AppRadius.lgBorder,
              boxShadow: [
                BoxShadow(
                  color: tierColors[0].withValues(alpha: isDark ? 0.25 : 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: tierColors[0].withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: AppRadius.lgBorder,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Coloured left accent strip
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: tierColors,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Unit number pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: tierColors[0].withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: tierColors[0].withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'ইউনিট $unitNumber',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: tierColors[0],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Lesson count / completion badge
                                if (unitDone)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.brightGreen
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            size: 12,
                                            color: AppColors.brightGreen),
                                        const SizedBox(width: 4),
                                        Text(
                                          'সম্পন্ন',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                  color: AppColors.brightGreen,
                                                  fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (totalCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tierColors[0].withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      unitStarted
                                          ? '$doneCount/$totalCount পাঠ'
                                          : '$totalCount পাঠ',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: tierColors[0],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                            // Thin progress bar at bottom
                            if (totalCount > 0) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalCount > 0
                                      ? doneCount / totalCount
                                      : 0,
                                  minHeight: 5,
                                  backgroundColor:
                                      tierColors[0].withValues(alpha: 0.18),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      unitDone
                                          ? AppColors.brightGreen
                                          : tierColors[0]),
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
          ),

          // ── Winding lesson path ───────────────────────────────────────────
          lessonsAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
            data: (lessonList) {
              if (lessonList.isEmpty) return const SizedBox.shrink();
              if (isQuranic) {
                return QuranicLessonList(
                  lessons: lessonList,
                  examLesson: examAsync.valueOrNull,
                  completedIds: completedIds,
                  tierColor: tierColors[0],
                );
              }
              final allDone =
                  lessonList.every((l) => completedIds.contains(l.id));
              final examLesson = examAsync.valueOrNull;
              final examDone   = examLesson != null &&
                  completedIds.contains(examLesson.id);

              // Split at midpoint to inject chest node
              final showChest = lessonList.length >= 4;
              final mid        = lessonList.length ~/ 2;
              final firstHalf  = showChest ? lessonList.sublist(0, mid) : lessonList;
              final secondHalf = showChest ? lessonList.sublist(mid) : <Lesson>[];
              final chestOpen  = showChest &&
                  firstHalf.every((l) => completedIds.contains(l.id));

              return Column(
                children: [
                  _LessonPath(
                    lessons: firstHalf,
                    completedIds: completedIds,
                    tierColor: tierColors[0],
                  ),
                  if (showChest) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: ChestNode(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(chestOpen
                                    ? 'পরবর্তী অর্ধেক শেষ করলে বোনাস XP অর্জন করুন!'
                                    : 'অর্ধেক পাঠ সম্পন্ন — চমৎকার!'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    _LessonPath(
                      lessons: secondHalf,
                      completedIds: completedIds,
                      tierColor: tierColors[0],
                    ),
                  ],
                  if (examLesson != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: ExamNode(
                          completed: examDone,
                          onTap: allDone
                              ? () => context.push('/exam/${examLesson.id}')
                              : null,
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 12, 0, 24),
                    child: Center(child: TasselOrnament()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Winding path ──────────────────────────────────────────────────────────────

class _LessonPath extends StatefulWidget {
  final List<Lesson> lessons;
  final Set<String> completedIds;
  final Color tierColor;

  const _LessonPath({
    required this.lessons,
    required this.completedIds,
    required this.tierColor,
  });

  @override
  State<_LessonPath> createState() => _LessonPathState();
}

class _LessonPathState extends State<_LessonPath>
    with SingleTickerProviderStateMixin {
  static const _stagger = Duration(milliseconds: 40);
  static const _itemDuration = Duration(milliseconds: 300);
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    final n = widget.lessons.length;
    final totalMs = _itemDuration.inMilliseconds +
        (n > 1 ? (n - 1) * _stagger.inMilliseconds : 0);
    _entranceCtrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: totalMs));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _entranceCtrl.value = 1;
      } else {
        _entranceCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  Animation<double> _entranceFor(int index) {
    final totalMs = _entranceCtrl.duration!.inMilliseconds;
    final start = (index * _stagger.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final end =
        (start + _itemDuration.inMilliseconds / totalMs).clamp(start, 1.0);
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.lessons;
    final completedIds = widget.completedIds;
    final tierColor = widget.tierColor;
    final firstUndone =
        lessons.indexWhere((l) => !completedIds.contains(l.id));

    return LayoutBuilder(builder: (context, constraints) {
      final width       = constraints.maxWidth;
      final totalHeight = lessons.length * _rowHeight + 32;
      const nodeWidth   = _nodeSize + 24;
      const nodeHeight  = _rowHeight - 8;

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
            RepaintBoundary(
              child: CustomPaint(
                size: Size(width, totalHeight),
                painter: MisbahaCordPainter(
                  nodes: positions,
                  color: AppColors.misbahaCord,
                ),
              ),
            ),
            ...List.generate(lessons.length, (i) {
              final pos = positions[i];
              final entrance = _entranceFor(i);
              return Positioned(
                left: pos.dx - nodeWidth / 2,
                top:  pos.dy - nodeHeight / 2,
                child: AnimatedBuilder(
                  animation: entrance,
                  builder: (context, child) => Opacity(
                    opacity: entrance.value,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * entrance.value,
                      child: child,
                    ),
                  ),
                  child: SizedBox(
                    width: nodeWidth,
                    height: nodeHeight,
                    child: Center(
                      child: _LessonNode(
                        lesson: lessons[i],
                        isDone: completedIds.contains(lessons[i].id),
                        isCurrent: i == firstUndone,
                        tierColor: tierColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

// ── Individual lesson node ────────────────────────────────────────────────────

class _LessonNode extends ConsumerWidget {
  final Lesson lesson;
  final bool isDone;
  final bool isCurrent;
  final Color tierColor;

  const _LessonNode({
    required this.lesson,
    required this.isDone,
    required this.isCurrent,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accuracyMap =
        ref.watch(lessonAccuracyMapProvider).valueOrNull ?? {};
    final accuracy = isDone ? accuracyMap[lesson.id] : null;

    final Widget bead = isDone
        ? DoneBead(
            label: lesson.titleBn,
            fill: tierColor,
            accuracyStars:
                accuracy == null ? null : _accuracyToStars(accuracy),
          )
        : isCurrent
            ? _CurrentLessonBead(lesson: lesson)
            : LockedBead(label: lesson.titleBn);

    return TapScale(
      child: GestureDetector(
        onTap: () => context.push('/lesson/${lesson.id}'),
        onLongPress: () => _showTooltip(context, theme),
        child: bead,
      ),
    );
  }

  void _showTooltip(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: AppRadius.xxlBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(
                    isDone: isDone, isCurrent: isCurrent, tierColor: tierColor),
                const Spacer(),
                Text('${lesson.xpReward} XP',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.gold, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(lesson.titleBn,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/lesson/${lesson.id}');
                },
                style: FilledButton.styleFrom(backgroundColor: tierColor),
                child: const Text('শুরু করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps an accuracy percentage to a 0-3 misbaha star rating.
int _accuracyToStars(int accuracy) {
  if (accuracy >= 90) return 3;
  if (accuracy >= 70) return 2;
  if (accuracy >= 50) return 1;
  return 0;
}

// ── Current lesson bead (pulsing gold ring, label below) ───────────────────────

class _CurrentLessonBead extends StatefulWidget {
  final Lesson lesson;
  const _CurrentLessonBead({required this.lesson});

  @override
  State<_CurrentLessonBead> createState() => _CurrentLessonBeadState();
}

class _CurrentLessonBeadState extends State<_CurrentLessonBead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.beadPulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final titleAr = widget.lesson.titleAr;
    final letter =
        (titleAr != null && titleAr.isNotEmpty) ? titleAr.substring(0, 1) : '✦';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  final opacity = reduceMotion
                      ? 0.3
                      : 0.08 +
                          (0.55 - 0.08) *
                              (0.5 + 0.5 * cos(_pulse.value * 2 * pi));
                  return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: opacity),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    radius: 0.9,
                    colors: [AppColors.goldLight, Color(0xFFC9920E)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .3),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        letter,
                        style: GoogleFonts.amiri(
                            fontSize: 18,
                            color: AppColors.deepGreen,
                            height: 1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: _nodeSize + 18,
          child: Text(
            widget.lesson.titleBn,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${widget.lesson.xpReward} XP',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.goldDeep,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status chip (lesson tooltip) ────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final Color tierColor;
  const _StatusChip({
    required this.isDone,
    required this.isCurrent,
    required this.tierColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isDone
        ? '✓ সম্পন্ন'
        : isCurrent
            ? '▶ পরবর্তী'
            : '🔒 লক';
    final color = isDone
        ? AppColors.brightGreen
        : isCurrent
            ? tierColor
            : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// ── Quranic open-access banner ────────────────────────────────────────────────

class _QuranicCurriculumHeader extends StatelessWidget {
  const _QuranicCurriculumHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFF1B6B3A);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_open_rounded, size: 16, color: green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'সকল ইউনিট উন্মুক্ত — নিজের গতিতে শিখুন',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                'تَعَلَّمْ',
                style: const TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 14,
                  height: 1.6,
                  color: green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tier section banner ───────────────────────────────────────────────────────

class _TierSectionBanner extends StatelessWidget {
  final int tier;
  final int sectionIndex;
  const _TierSectionBanner({required this.tier, required this.sectionIndex});

  @override
  Widget build(BuildContext context) {
    final colors = _tierColors(tier);
    final name   = _tierNames[tier]   ?? 'বিভাগ $sectionIndex';
    final nameAr = _tierNamesAr[tier] ?? '';
    final desc   = _tierDescriptions[tier] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'বিভাগ $sectionIndex',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (nameAr.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    nameAr,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.white54,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

