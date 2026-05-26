import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/local/database.dart';
import 'home_provider.dart';

class TrackDetailPage extends ConsumerWidget {
  final String slug;
  const TrackDetailPage({required this.slug, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackAsync = ref.watch(trackBySlugProvider(slug));

    return trackAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('পাঠ পথ')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('পাঠ পথ')),
        body: Center(child: Text('ত্রুটি: $e')),
      ),
      data: (track) {
        if (track == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('পাঠ পথ')),
            body: const Center(child: Text('কোর্স পাওয়া যায়নি')),
          );
        }
        return _TrackBody(track: track);
      },
    );
  }
}

class _TrackBody extends ConsumerWidget {
  final Track track;
  const _TrackBody({required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unitsAsync = ref.watch(unitsForTrackProvider(track.id));
    final completedAsync = ref.watch(completedLessonIdsProvider);

    final bookmarkedAsync = ref.watch(bookmarkedLessonIdsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(track.nameBn,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                track.nameAr,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 13,
                  height: 1.4,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
      body: unitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('পাঠ লোড হচ্ছে না।',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
        data: (units) {
          if (units.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_empty,
                        size: 64, color: theme.colorScheme.outline),
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
            );
          }
          final completedIds = completedAsync.valueOrNull ?? {};
          final bookmarkedIds = bookmarkedAsync.valueOrNull ?? {};
          return _UnitList(
            units: units,
            completedIds: completedIds,
            bookmarkedIds: bookmarkedIds,
          );
        },
      ),
    );
  }
}

class _UnitList extends StatelessWidget {
  final List<Unit> units;
  final Set<String> completedIds;
  final Set<String> bookmarkedIds;
  const _UnitList({
    required this.units,
    required this.completedIds,
    required this.bookmarkedIds,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: units.length,
      itemBuilder: (ctx, i) => _UnitSection(
        unit: units[i],
        unitNumber: i + 1,
        completedIds: completedIds,
        bookmarkedIds: bookmarkedIds,
        isLast: i == units.length - 1,
      ),
    );
  }
}

class _UnitSection extends ConsumerWidget {
  final Unit unit;
  final int unitNumber;
  final Set<String> completedIds;
  final Set<String> bookmarkedIds;
  final bool isLast;
  const _UnitSection({
    required this.unit,
    required this.unitNumber,
    required this.completedIds,
    required this.bookmarkedIds,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lessonsAsync = ref.watch(lessonsForUnitProvider(unit.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$unitNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.titleBn,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (unit.titleAr != null && unit.titleAr!.isNotEmpty)
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          unit.titleAr!,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 14,
                            height: 1.4,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        lessonsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(left: 46, bottom: 16),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (lessons) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Column(
              children: lessons
                  .asMap()
                  .entries
                  .map((e) => _LessonTile(
                        lesson: e.value,
                        lessonNumber: e.key + 1,
                        isDone: completedIds.contains(e.value.id),
                        isBookmarked: bookmarkedIds.contains(e.value.id),
                      ))
                  .toList(),
            ),
          ),
        ),
        if (!isLast) const Divider(height: 8),
      ],
    );
  }
}

class _LessonTile extends ConsumerWidget {
  final Lesson lesson;
  final int lessonNumber;
  final bool isDone;
  final bool isBookmarked;
  const _LessonTile({
    required this.lesson,
    required this.lessonNumber,
    required this.isDone,
    required this.isBookmarked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDone
              ? Colors.green.withValues(alpha: 0.35)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      color: isDone
          ? Colors.green.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/lesson/${lesson.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      isDone ? Colors.green : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check : Icons.play_arrow_rounded,
                  color: isDone
                      ? Colors.white
                      : theme.colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.titleBn,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDone
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.65)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          '${lesson.xpReward} XP',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LevelChip(level: lesson.level),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDone)
                Text(
                  'সম্পন্ন',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: isBookmarked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () => ref
                    .read(bookmarkNotifierProvider.notifier)
                    .toggle(lesson.id, isBookmarked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;
  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    const labels = {
      'beginner': 'সহজ',
      'intermediate': 'মধ্যম',
      'advanced': 'কঠিন',
    };
    final colors = {
      'beginner': Colors.green.shade600,
      'intermediate': Colors.orange.shade600,
      'advanced': Colors.red.shade600,
    };
    final color = colors[level] ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        labels[level] ?? level,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
