import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await Supabase.instance.client.functions.invoke('admin-analytics');
  if (res.data == null) throw Exception('No data returned');
  return Map<String, dynamic>.from(res.data as Map);
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(_analyticsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(_analyticsProvider),
          ),
        ],
      ),
      body: analytics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('Failed to load analytics', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('$e', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: () => ref.invalidate(_analyticsProvider),
              ),
            ],
          ),
        ),
        data: (data) => _DashboardBody(data: data),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final content  = data['content']  as Map<String, dynamic>? ?? {};
    final learners = data['learners'] as Map<String, dynamic>? ?? {};
    final topLessons = (data['top_lessons'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tracks   = (content['tracks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final tierDist = (content['tier_distribution'] as Map?)
        ?.map((k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, (v as num).toInt())) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Content overview ──────────────────────────────────────
            _SectionHeader(
              icon: Icons.library_books_outlined,
              title: 'Content',
            ),
            const SizedBox(height: 12),
            _StatGrid(stats: [
              _Stat('Published Units',   '${content['units_published'] ?? 0}',   Icons.check_circle_outline, Colors.green),
              _Stat('Draft Units',       '${content['units_draft'] ?? 0}',        Icons.edit_note_outlined,   Colors.orange),
              _Stat('Published Lessons', '${content['lessons_published'] ?? 0}', Icons.menu_book_outlined,   Colors.blue),
              _Stat('Draft Lessons',     '${content['lessons_draft'] ?? 0}',     Icons.drafts_outlined,      Colors.amber),
              _Stat('Exercises',         '${content['exercises_total'] ?? 0}',   Icons.quiz_outlined,        Colors.purple),
              _Stat('Vocabulary',        '${content['vocabulary_total'] ?? 0}',  Icons.translate_outlined,   Colors.teal),
            ]),
            const SizedBox(height: 28),

            // ── Learner overview ──────────────────────────────────────
            _SectionHeader(icon: Icons.people_outline, title: 'Learners'),
            const SizedBox(height: 12),
            _StatGrid(stats: [
              _Stat('Total Learners',    '${learners['total'] ?? 0}',            Icons.person_outline,        Colors.indigo),
              _Stat('Registered',        '${learners['registered'] ?? 0}',       Icons.how_to_reg_outlined,   Colors.green),
              _Stat('Anonymous',         '${learners['anonymous'] ?? 0}',        Icons.person_off_outlined,   Colors.grey),
              _Stat('Active (7 days)',   '${learners['active_7d'] ?? 0}',        Icons.trending_up,            Colors.blue),
              _Stat('Active (30 days)',  '${learners['active_30d'] ?? 0}',       Icons.calendar_month_outlined,Colors.cyan),
              _Stat('Lessons Done',      '${learners['total_completions'] ?? 0}',Icons.task_alt_outlined,      Colors.teal),
              _Stat('Avg Streak',        '${learners['avg_streak'] ?? 0} days',  Icons.local_fire_department_outlined, Colors.deepOrange),
              _Stat('Max Streak',        '${learners['max_streak'] ?? 0} days',  Icons.emoji_events_outlined, Colors.amber),
              _Stat('Total XP',          _formatXp(learners['total_xp']),        Icons.star_outline,          Colors.purple),
            ]),
            const SizedBox(height: 28),

            // ── Two-column lower section ──────────────────────────────
            LayoutBuilder(builder: (ctx, constraints) {
              final twoCol = constraints.maxWidth >= 600;
              final leftCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.alt_route_outlined, title: 'Track Breakdown'),
                  const SizedBox(height: 12),
                  _TrackTable(tracks: tracks),
                  const SizedBox(height: 28),
                  _SectionHeader(icon: Icons.stacked_bar_chart_outlined, title: 'Tier Distribution'),
                  const SizedBox(height: 12),
                  _TierBars(tierDist: tierDist),
                ],
              );
              final rightCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(icon: Icons.trending_up, title: 'Top Lessons'),
                  const SizedBox(height: 12),
                  _TopLessonsList(lessons: topLessons),
                ],
              );

              if (twoCol) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftCol),
                    const SizedBox(width: 24),
                    Expanded(child: rightCol),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [leftCol, const SizedBox(height: 24), rightCol],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatXp(dynamic xp) {
    final n = (xp as num?)?.toInt() ?? 0;
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Icon(icon, size: 18, color: theme.colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      )),
    ]);
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

class _StatGrid extends StatelessWidget {
  final List<_Stat> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = (constraints.maxWidth / 160).floor().clamp(2, 6);
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: stats.map((s) => SizedBox(
          width: (constraints.maxWidth - (cols - 1) * 10) / cols,
          child: _StatCard(stat: s),
        )).toList(),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: stat.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(stat.icon, size: 16, color: stat.color),
            const SizedBox(width: 6),
            Expanded(child: Text(stat.label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          Text(stat.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: stat.color)),
        ],
      ),
    );
  }
}

class _TrackTable extends StatelessWidget {
  final List<Map<String, dynamic>> tracks;
  const _TrackTable({required this.tracks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (tracks.isEmpty) return const Text('No tracks found.');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
            children: ['Track', 'Published', 'Draft'].map((h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(h, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
            )).toList(),
          ),
          ...tracks.map((t) {
            final isQuranic = t['slug'] == 'quranic';
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isQuranic ? Colors.green : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(t['name_bn'] ?? t['slug'] ?? '', style: theme.textTheme.bodySmall),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text('${t['units_published'] ?? 0}', style: theme.textTheme.bodySmall),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text('${t['units_draft'] ?? 0}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange)),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TierBars extends StatelessWidget {
  final Map<int, int> tierDist;
  const _TierBars({required this.tierDist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = {1: 'T1 — Foundational', 2: 'T2 — Structural', 3: 'T3 — Verbal', 4: 'T4 — Advanced'};
    final colors = {1: Colors.blue, 2: Colors.purple, 3: Colors.amber.shade700, 4: Colors.red};
    final maxVal = tierDist.values.fold(0, (a, b) => a > b ? a : b);

    return Column(
      children: [1, 2, 3, 4].map((t) {
        final count = tierDist[t] ?? 0;
        final frac = maxVal > 0 ? count / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            SizedBox(
              width: 110,
              child: Text(labels[t] ?? 'T$t',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac.toDouble(),
                  minHeight: 10,
                  backgroundColor: (colors[t] ?? Colors.grey).withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(colors[t] ?? Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              child: Text('$count',
                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

class _TopLessonsList extends StatelessWidget {
  final List<Map<String, dynamic>> lessons;
  const _TopLessonsList({required this.lessons});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (lessons.isEmpty) return Text('No completions yet.', style: theme.textTheme.bodySmall);
    final maxCount = lessons.first['completions'] as int? ?? 1;

    return Column(
      children: lessons.asMap().entries.map((entry) {
        final i = entry.key;
        final lesson = entry.value;
        final count = lesson['completions'] as int? ?? 0;
        final frac = maxCount > 0 ? count / maxCount : 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            Container(
              width: 24, height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i < 3
                    ? [Colors.amber, Colors.grey.shade400, Colors.brown.shade300][i]
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text('${i + 1}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                      color: i < 3 ? Colors.white : theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson['title_bn'] as String? ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: frac,
                      minHeight: 4,
                      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text('$count×', style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          ]),
        );
      }).toList(),
    );
  }
}
