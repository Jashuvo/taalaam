import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/database.dart';
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
        body: CustomScrollView(slivers: [
          _buildAppBar(trackGradient),
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(trackGradient),
          SliverToBoxAdapter(
            child: allUnits.isEmpty
                ? const _EmptyTierPlaceholder()
                : Builder(builder: (_) {
                    final items = <Widget>[];
                    if (isQuranic) {
                      // Flat Quranic layout — no tier banners, no UpNext cards
                      // All units open; sorted by sort_order
                      final sortedUnits = [...allUnits]
                        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
                      final userId =
                          ref.watch(currentUserProvider)?.id;
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
                    } else {
                      for (int ti = 0; ti < sortedTiers.length; ti++) {
                        final tier  = sortedTiers[ti];
                        final units = tierGroups[tier]!;
                        items.add(_TierSectionBanner(
                            tier: tier, sectionIndex: ti + 1));
                        for (int ui = 0; ui < units.length; ui++) {
                          items.add(_UnitSection(
                            unit: units[ui],
                            unitNumber: ui + 1,
                            completedIds: completedIds,
                            bookmarkedIds: bookmarkedIds,
                            tierColors: _tierColors(tier),
                            isQuranic: false,
                          ));
                        }
                        if (ti < sortedTiers.length - 1) {
                          items.add(_UpNextCard(nextTier: sortedTiers[ti + 1]));
                        }
                      }
                    }
                    items.add(const SizedBox(height: 80));
                    return Column(children: items);
                  }),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(List<Color> gradient) {
    return SliverAppBar(
      expandedHeight: 88.0,
      collapsedHeight: 56.0,
      pinned: true,
      stretch: true,
      backgroundColor: gradient[0],
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).canPop()
            ? Navigator.of(context).pop()
            : context.go('/home'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(56, 6, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.track.nameBn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      widget.track.nameAr,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.white60,
                      ),
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

// ── Sticky section bar ────────────────────────────────────────────────────────

class _SectionBarDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTier;
  final List<int> availableTiers;
  final List<Unit> allUnits;
  final ValueChanged<int> onSelectTier;

  static const double _h = 60.0;

  const _SectionBarDelegate({
    required this.selectedTier,
    required this.availableTiers,
    required this.allUnits,
    required this.onSelectTier,
  });

  @override double get minExtent => _h;
  @override double get maxExtent => _h;

  @override
  bool shouldRebuild(_SectionBarDelegate old) =>
      selectedTier != old.selectedTier ||
      availableTiers.length != old.availableTiers.length;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors   = _tierColors(selectedTier);
    final name     = _tierNames[selectedTier]   ?? 'বিভাগ $selectedTier';
    final nameAr   = _tierNamesAr[selectedTier] ?? '';
    final unitCount = allUnits.where((u) => u.tierLevel == selectedTier).length;
    final idx      = availableTiers.indexOf(selectedTier);
    final hasPrev  = idx > 0;
    final hasNext  = idx < availableTiers.length - 1;

    return Material(
      elevation: overlapsContent ? 6 : 0,
      shadowColor: colors[0].withValues(alpha: 0.4),
      child: Container(
        height: _h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              colors[0],
              Color.lerp(colors[0], colors[1], 0.7)!,
              colors[1],
            ],
          ),
        ),
        child: Row(
          children: [
            // ← prev
            _NavArrow(
              icon: Icons.chevron_left_rounded,
              enabled: hasPrev,
              onTap: hasPrev ? () => onSelectTier(availableTiers[idx - 1]) : null,
            ),

            // Centre: name + tap to pick
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
                          'বিভাগ ${idx + 1}  ·  $name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54, size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$unitCount ইউনিট',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10.5),
                        ),
                        const SizedBox(width: 8),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            nameAr,
                            style: const TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 11,
                              height: 1.6,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // → next
            _NavArrow(
              icon: Icons.chevron_right_rounded,
              enabled: hasNext,
              onTap: hasNext ? () => onSelectTier(availableTiers[idx + 1]) : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  const _NavArrow({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: double.infinity,
          child: Icon(
            icon,
            color: enabled ? Colors.white : Colors.white24,
            size: 26,
          ),
        ),
      );
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.xxlBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Icon(Icons.layers_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text('বিভাগ নির্বাচন',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...availableTiers.map((tier) {
            final colors    = _tierColors(tier);
            final name      = _tierNames[tier]   ?? 'বিভাগ $tier';
            final nameAr    = _tierNamesAr[tier]  ?? '';
            final desc      = _tierDescriptions[tier] ?? '';
            final count     = allUnits.where((u) => u.tierLevel == tier).length;
            final isSelected = tier == selectedTier;
            final tierIdx   = availableTiers.indexOf(tier);

            return InkWell(
              onTap: () => onSelect(tier),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: isSelected
                    ? BoxDecoration(
                        color: colors[0].withValues(alpha: 0.07),
                        border: Border(
                          left: BorderSide(color: colors[0], width: 3),
                        ),
                      )
                    : null,
                child: Row(
                  children: [
                    // Tier badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: AppRadius.lgBorder,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colors[0].withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${tierIdx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected ? colors[0] : null,
                                    )),
                              ),
                              const SizedBox(width: 8),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(nameAr,
                                    style: const TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 12,
                                      height: 1.6,
                                      color: Colors.grey,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$desc  •  $count ইউনিট',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: colors[0], size: 20)
                    else
                      const SizedBox(width: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
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
                    tierColors: tierColors,
                    isQuranic: isQuranic,
                  ),
                  if (showChest) ...[
                    _ChestNode(isOpen: chestOpen, tierColors: tierColors),
                    _LessonPath(
                      lessons: secondHalf,
                      completedIds: completedIds,
                      tierColors: tierColors,
                      isQuranic: isQuranic,
                    ),
                  ],
                  if (examLesson != null)
                    _ExamNode(
                      examLesson: examLesson,
                      isUnlocked: allDone,
                      isDone: examDone,
                    ),
                  _TrophyNode(isComplete: allDone),
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

class _LessonPath extends StatelessWidget {
  final List<Lesson> lessons;
  final Set<String> completedIds;
  final List<Color> tierColors;
  final bool isQuranic;

  const _LessonPath({
    required this.lessons,
    required this.completedIds,
    required this.tierColors,
    required this.isQuranic,
  });

  @override
  Widget build(BuildContext context) {
    final firstUndone =
        lessons.indexWhere((l) => !completedIds.contains(l.id));

    return LayoutBuilder(builder: (context, constraints) {
      final width       = constraints.maxWidth;
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
                isDoneList: lessons.map((l) => completedIds.contains(l.id)).toList(),
                tierColor: tierColors[0],
              ),
            ),
            ...List.generate(lessons.length, (i) {
              final pos = positions[i];
              return Positioned(
                left: pos.dx - _nodeSize / 2,
                top:  pos.dy - _nodeSize / 2,
                child: _LessonNode(
                  lesson: lessons[i],
                  isDone: completedIds.contains(lessons[i].id),
                  isCurrent: i == firstUndone,
                  tierColors: tierColors,
                  isQuranic: isQuranic,
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
  final Color tierColor;

  const _PathPainter({
    required this.positions,
    required this.isDoneList,
    required this.tierColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < positions.length - 1; i++) {
      final done = isDoneList[i];
      final paint = Paint()
        ..color = done ? tierColor.withValues(alpha: 0.7) : Colors.grey.shade300
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final from = positions[i];
      final to   = positions[i + 1];
      final delta = to - from;
      final dist  = delta.distance;
      final unitV = Offset(delta.dx / dist, delta.dy / dist);
      const gap   = _nodeSize / 2 + 4;
      final start = from + unitV * gap;
      final end   = to   - unitV * gap;
      final mid   = (end.dy - start.dy) * 0.4;
      final path  = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx, start.dy + mid,
          end.dx,   end.dy   - mid,
          end.dx,   end.dy,
        );

      if (done) {
        canvas.drawPath(path, paint);
      } else {
        _drawDashed(canvas, path, paint);
      }
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 7.0;
    const gap  = 5.0;
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw   = true;
      while (dist < metric.length) {
        final seg  = draw ? dash : gap;
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

class _LessonNode extends ConsumerWidget {
  final Lesson lesson;
  final bool isDone;
  final bool isCurrent;
  final List<Color> tierColors;
  final bool isQuranic;

  const _LessonNode({
    required this.lesson,
    required this.isDone,
    required this.isCurrent,
    required this.tierColors,
    required this.isQuranic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accuracyMap =
        ref.watch(lessonAccuracyMapProvider).valueOrNull ?? {};
    final accuracy = isDone ? accuracyMap[lesson.id] : null;
    final isDark = theme.brightness == Brightness.dark;

    final Color bg;
    final Color borderColor;
    final Widget nodeIcon;
    final List<BoxShadow> shadows;

    if (isDone) {
      bg          = AppColors.brightGreen;
      borderColor = AppColors.correctBg;
      nodeIcon    = const Icon(Icons.check_rounded, color: Colors.white, size: 28);
      shadows     = [
        BoxShadow(
          color: AppColors.brightGreen.withValues(alpha: 0.3),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (isCurrent) {
      bg          = tierColors[0];
      borderColor = Colors.white.withValues(alpha: 0.9);
      nodeIcon    = const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32);
      shadows     = [
        BoxShadow(
          color: tierColors[0].withValues(alpha: 0.5),
          blurRadius: 18,
          spreadRadius: 4,
        ),
      ];
    } else if (isQuranic) {
      // Quranic: all undone lessons are open — no lock, show open book
      bg          = tierColors[0].withValues(alpha: 0.10);
      borderColor = tierColors[0].withValues(alpha: 0.45);
      nodeIcon    = Icon(Icons.menu_book_rounded,
          color: tierColors[0].withValues(alpha: 0.75), size: 22);
      shadows     = [];
    } else {
      bg          = isDark
          ? AppColors.darkSurfaceHigh
          : AppColors.lightSurfaceHighest;
      borderColor = theme.colorScheme.outlineVariant;
      nodeIcon    = Icon(Icons.lock_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 22);
      shadows     = [];
    }

    return GestureDetector(
      onTap:      () => context.push('/lesson/${lesson.id}'),
      onLongPress: () => _showTooltip(context, theme),
      child: SizedBox(
        width: _nodeSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                if (isCurrent) _PulsingGlow(glowColor: tierColors[0]),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width:  _nodeSize,
                  height: _nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bg,
                    border: Border.all(
                      color: borderColor,
                      width: isCurrent ? 3.0 : 1.8,
                    ),
                    boxShadow: shadows,
                  ),
                  child: Center(child: nodeIcon),
                ),
                if (accuracy != null)
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: accuracy >= 80
                            ? AppColors.brightGreen
                            : theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        '$accuracy%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: _nodeSize + 18,
              child: Text(
                lesson.titleBn,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? tierColors[0]
                      : theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: isDone ? 0.5 : 0.8),
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.brightGreen.withValues(alpha: 0.12)
                    : isCurrent
                        ? tierColors[0].withValues(alpha: 0.12)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${lesson.xpReward} XP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDone
                      ? AppColors.brightGreen
                      : isCurrent
                          ? tierColors[0]
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
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
                    isDone: isDone, isCurrent: isCurrent, tierColor: tierColors[0], isQuranic: isQuranic),
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
                style: FilledButton.styleFrom(
                  backgroundColor: tierColors[0],
                ),
                child: const Text('শুরু করুন'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;
  final Color tierColor;
  final bool isQuranic;
  const _StatusChip(
      {required this.isDone,
      required this.isCurrent,
      required this.tierColor,
      required this.isQuranic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isDone
        ? '✓ সম্পন্ন'
        : isCurrent
            ? '▶ পরবর্তী'
            : isQuranic
                ? '📖 পড়ুন'
                : '🔒 লক';
    final color = isDone
        ? AppColors.brightGreen
        : isCurrent
            ? tierColor
            : isQuranic
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
    const gold     = AppColors.gold;
    const goldDark = Color(0xFFB8860B);

    final Color bg;
    final Color borderColor;
    final Widget icon;

    if (widget.isDone) {
      bg          = gold;
      borderColor = goldDark;
      icon = const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36);
    } else if (widget.isUnlocked) {
      bg          = gold;
      borderColor = Colors.white.withValues(alpha: 0.8);
      icon = const Icon(Icons.shield_rounded, color: Colors.white, size: 36);
    } else {
      bg          = theme.colorScheme.surfaceContainerHighest;
      borderColor = theme.colorScheme.outlineVariant;
      icon = Icon(Icons.lock_outline_rounded,
          color: theme.colorScheme.onSurfaceVariant, size: 28);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: GestureDetector(
          onTap: widget.isUnlocked
              ? () => context.push('/exam/${widget.examLesson.id}')
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
                  fontWeight: FontWeight.w700,
                  color: widget.isUnlocked
                      ? gold
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isUnlocked
                      ? gold.withValues(alpha: 0.12)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: widget.isUnlocked
                      ? Border.all(color: gold.withValues(alpha: 0.35))
                      : null,
                ),
                child: Text(
                  widget.isUnlocked
                      ? '${widget.examLesson.xpReward} XP  ·  ${widget.examLesson.gemReward} 💎'
                      : 'সব পাঠ শেষ করুন',
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

// ── UP NEXT card (transition between tiers) ───────────────────────────────────

class _UpNextCard extends StatelessWidget {
  final int nextTier;
  const _UpNextCard({required this.nextTier});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final colors = _tierColors(nextTier);
    final name   = _tierNames[nextTier] ?? 'পরবর্তী বিভাগ';
    final desc   = _tierDescriptions[nextTier] ?? '';
    final idx    = nextTier;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 32, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'পরবর্তী বিভাগ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors,
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$idx',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    if (desc.isNotEmpty)
                      Text(desc,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chest node (mid-unit reward marker) ──────────────────────────────────────

class _ChestNode extends StatelessWidget {
  final bool isOpen;
  final List<Color> tierColors;
  const _ChestNode({required this.isOpen, required this.tierColors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isOpen
                    ? 'পরবর্তী অর্ধেক শেষ করলে রত্ন অর্জন করুন!'
                    : 'অর্ধেক পাঠ সম্পন্ন — চমৎকার!'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isOpen
                  ? AppColors.gold.withValues(alpha: 0.18)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOpen
                    ? AppColors.gold
                    : theme.colorScheme.outlineVariant,
                width: 2,
              ),
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              isOpen ? Icons.redeem_rounded : Icons.lock_outline_rounded,
              size: 26,
              color: isOpen
                  ? AppColors.gold
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Trophy node (unit-end completion marker) ──────────────────────────────────

class _TrophyNode extends StatelessWidget {
  final bool isComplete;
  const _TrophyNode({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete
                ? AppColors.brightGreen.withValues(alpha: 0.15)
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isComplete
                  ? AppColors.brightGreen
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
            boxShadow: isComplete
                ? [
                    BoxShadow(
                      color: AppColors.brightGreen.withValues(alpha: 0.25),
                      blurRadius: 12,
                    )
                  ]
                : null,
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 28,
            color: isComplete
                ? AppColors.brightGreen
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

// ── Pulsing glow ring for the current lesson node ─────────────────────────────

class _PulsingGlow extends StatefulWidget {
  final Color glowColor;
  const _PulsingGlow({required this.glowColor});

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          width: _nodeSize,
          height: _nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: 0.5),
                blurRadius: 14.0 + _ctrl.value * 14.0,
                spreadRadius: 2.0 + _ctrl.value * 4.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
