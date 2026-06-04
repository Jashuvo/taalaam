import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/confirm_dialog.dart';

final _allUnitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Join with tracks to get track name — shown as a badge on each unit card
  final rows = await Supabase.instance.client
      .from('units')
      .select('id, title_bn, title_ar, status, track_id, sort_order, tier_level, sequence_order, tracks(slug, name_bn)')
      .order('sequence_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows as List);
});

class AdminReviewPage extends ConsumerStatefulWidget {
  const AdminReviewPage({super.key});

  @override
  ConsumerState<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends ConsumerState<AdminReviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>>? _localOrder;
  bool _reordering = false;
  bool _sorting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _localOrder = null);
    ref.invalidate(_allUnitsProvider);
  }

  Future<void> _aiSortUnits() async {
    final units = (_localOrder ?? ref.read(_allUnitsProvider).valueOrNull ?? []);
    final trackIds = units.map((u) => u['track_id'] as String).toSet();
    if (trackIds.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'AI Sort All Units?',
      body: 'Gemini will reorder units across ${trackIds.length} track(s) into the optimal learning sequence.',
      confirmLabel: 'Sort',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    setState(() => _sorting = true);
    try {
      final allMerged = <String>[];
      for (final trackId in trackIds) {
        final res = await Supabase.instance.client.functions
            .invoke('sort-units', body: {'track_id': trackId});
        final merged = (res.data?['merged'] as List?)?.cast<String>() ?? [];
        allMerged.addAll(merged);
      }
      _refresh();
      if (!mounted) return;
      if (allMerged.isNotEmpty) {
        _showMergeSummary(allMerged);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Units sorted — no duplicates found.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sorting = false);
    }
  }

  void _showMergeSummary(List<String> merged) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.auto_awesome, color: Colors.green),
          SizedBox(width: 8),
          Text('Sort & Merge Complete'),
        ]),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${merged.length} duplicate group(s) were merged. '
                  'Their lessons have been moved into single parent modules:',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...merged.map((reason) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: Text(reason,
                          style: const TextStyle(fontSize: 13)),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _onReorder(
      List<Map<String, dynamic>> units, int oldIndex, int newIndex) async {
    final reordered = [...units];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    setState(() {
      _localOrder = reordered;
      _reordering = true;
    });
    try {
      for (int i = 0; i < reordered.length; i++) {
        await Supabase.instance.client
            .from('units')
            .update({'sort_order': i, 'sequence_order': i}).eq('id', reordered[i]['id']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUnits = ref.watch(_allUnitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          if (_reordering || _sorting)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: 'AI Sort Units',
              onPressed: _aiSortUnits,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Drafts'),
            Tab(text: 'Published'),
          ],
        ),
      ),
      body: allUnits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (fetched) {
          final all = _localOrder ?? fetched;
          final drafts =
              all.where((u) => u['status'] == 'draft').toList();
          final published =
              all.where((u) => u['status'] == 'published').toList();

          return TabBarView(
            controller: _tabs,
            children: [
              _UnitList(
                units: drafts,
                isDraft: true,
                onRefresh: _refresh,
                onReorder: (old, next) => _onReorder(drafts, old, next),
              ),
              _UnitList(
                units: published,
                isDraft: false,
                onRefresh: _refresh,
                onReorder: (old, next) => _onReorder(published, old, next),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnitList extends StatelessWidget {
  final List<Map<String, dynamic>> units;
  final bool isDraft;
  final VoidCallback onRefresh;
  final void Function(int, int) onReorder;

  const _UnitList({
    required this.units,
    required this.isDraft,
    required this.onRefresh,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return _EmptyState(
        isDraft: isDraft,
        onUpload: () => context.go('/admin/upload'),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: units.length,
      onReorderItem: onReorder,
      itemBuilder: (ctx, i) => _UnitCard(
        key: ValueKey(units[i]['id']),
        unit: units[i],
        isDraft: isDraft,
        onRefresh: onRefresh,
      ),
    );
  }
}

class _UnitCard extends StatefulWidget {
  final Map<String, dynamic> unit;
  final bool isDraft;
  final VoidCallback onRefresh;
  const _UnitCard(
      {required this.unit,
      required this.isDraft,
      required this.onRefresh,
      super.key});

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

// Tier labels for the override dropdown — aligned with Salafi Arabic curriculum
const _tierDropdownLabels = <int, String>{
  1: 'T1 — মৌলিক শব্দ ও ইশারা',
  2: 'T2 — বাক্য সম্প্রসারণ ও গুণাবলী',
  3: 'T3 — ক্রিয়ার প্রাথমিক রূপান্তর',
  4: 'T4 — উচ্চতর শাস্ত্রীয় বাক্য গঠন',
};

class _UnitCardState extends State<_UnitCard> {
  bool _busy = false;
  late int _currentTier;

  @override
  void initState() {
    super.initState();
    _currentTier = widget.unit['tier_level'] as int? ?? 1;
  }

  @override
  void didUpdateWidget(_UnitCard old) {
    super.didUpdateWidget(old);
    _currentTier = widget.unit['tier_level'] as int? ?? 1;
  }

  Future<void> _overrideTier(int newTier) async {
    if (newTier == _currentTier) return;
    setState(() {
      _currentTier = newTier;
      _busy = true;
    });
    try {
      await Supabase.instance.client
          .from('units')
          .update({'tier_level': newTier}).eq('id', widget.unit['id']);
      // Reposition in the sequence timeline
      await Supabase.instance.client.functions
          .invoke('sort-units', body: {'track_id': widget.unit['track_id']});
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _aiSort() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'AI Sort Lessons?',
      body: 'Gemini will analyse the lessons in this unit and reorder them in the optimal learning sequence.',
      confirmLabel: 'Sort',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await Supabase.instance.client.functions
          .invoke('sort-lessons', body: {'unit_id': widget.unit['id']});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lessons sorted successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client
          .from('units')
          .update({'status': 'published'}).eq('id', widget.unit['id']);
      await Supabase.instance.client
          .from('lessons')
          .update({'status': 'published'}).eq('unit_id', widget.unit['id']);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish() async {
    setState(() => _busy = true);
    try {
      await Supabase.instance.client
          .from('units')
          .update({'status': 'draft'}).eq('id', widget.unit['id']);
      await Supabase.instance.client
          .from('lessons')
          .update({'status': 'draft'}).eq('unit_id', widget.unit['id']);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Unit?',
      body: 'Delete "${widget.unit['title_bn']}" and all its lessons and exercises?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      danger: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final sb = Supabase.instance.client;
      // Delete children first, then unit
      final lessonRows = await sb
          .from('lessons')
          .select('id')
          .eq('unit_id', widget.unit['id']);
      for (final l in (lessonRows as List)) {
        await sb.from('exercises').delete().eq('lesson_id', l['id'] as String);
        await sb.from('vocabulary').delete().eq('lesson_id', l['id'] as String);
      }
      await sb.from('lessons').delete().eq('unit_id', widget.unit['id']);
      await sb.from('units').delete().eq('id', widget.unit['id']);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBn = widget.unit['title_bn'] as String? ?? 'Untitled';
    final titleAr = widget.unit['title_ar'] as String?;
    final isDraft = widget.isDraft;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ───────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titleBn,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (titleAr != null && titleAr.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            titleAr,
                            style: const TextStyle(
                                fontFamily: 'NotoNaskhArabic',
                                fontSize: 14,
                                height: 1.6),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TrackChip(slug: (widget.unit['tracks'] as Map?)?['slug'] as String? ?? ''),
                    const SizedBox(width: 4),
                    _TierChip(tier: _currentTier),
                    const SizedBox(width: 4),
                    _SeqChip(order: widget.unit['sequence_order'] as int? ?? 0),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDraft
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDraft ? 'DRAFT' : 'LIVE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDraft
                                ? Colors.orange.shade800
                                : Colors.green.shade800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.drag_handle,
                        color: Colors.grey, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── Tier override row ────────────────────────────────────────────
            Row(
              children: [
                Text('টিয়ার:',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _currentTier,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: [1, 2, 3, 4]
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              _tierDropdownLabels[t] ?? 'T$t',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                      .toList(),
                  onChanged: _busy ? null : (t) { if (t != null) _overrideTier(t); },
                ),
              ],
            ),
            const SizedBox(height: 6),
            // ── Action row ───────────────────────────────────────────────────
            if (_busy)
              const SizedBox(
                  height: 28,
                  child: Center(
                      child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))))
            else
              Row(
                children: [
                  // AI Sort — highlighted so it's always easy to find
                  FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('AI Sort'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          theme.colorScheme.secondaryContainer,
                      foregroundColor:
                          theme.colorScheme.onSecondaryContainer,
                    ),
                    onPressed: _aiSort,
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    onPressed: () =>
                        context.go('/admin/review/${widget.unit['id']}'),
                  ),
                  const Spacer(),
                  if (isDraft)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.publish, size: 14),
                      label: const Text('Publish'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Colors.green.shade700,
                        side: BorderSide(color: Colors.green.shade400),
                      ),
                      onPressed: _publish,
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.unpublished_outlined,
                          size: 14),
                      label: const Text('Unpublish'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: _unpublish,
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: theme.colorScheme.error),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                    onPressed: _delete,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SeqChip extends StatelessWidget {
  final int order;
  const _SeqChip({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$order',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final int tier;
  const _TierChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    final colors = switch (tier) {
      1 => (bg: Colors.blue.shade100,   fg: Colors.blue.shade800),
      2 => (bg: Colors.purple.shade100, fg: Colors.purple.shade800),
      3 => (bg: Colors.amber.shade100,  fg: Colors.amber.shade900),
      4 => (bg: Colors.red.shade100,    fg: Colors.red.shade800),
      _ => (bg: Colors.grey.shade100,   fg: Colors.grey.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'T$tier',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.fg),
      ),
    );
  }
}

class _TrackChip extends StatelessWidget {
  final String slug;
  const _TrackChip({required this.slug});

  @override
  Widget build(BuildContext context) {
    final isQuranic = slug == 'quranic';
    final bg = isQuranic ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD);
    final fg = isQuranic ? const Color(0xFF2E7D32) : const Color(0xFF1565C0);
    final label = isQuranic ? 'কুরআন' : 'কথা';
    final icon = isQuranic ? Icons.menu_book : Icons.record_voice_over;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDraft;
  final VoidCallback onUpload;
  const _EmptyState({required this.isDraft, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDraft ? Icons.rate_review_outlined : Icons.check_circle_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              isDraft ? 'No Draft Units' : 'No Published Units',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isDraft
                  ? 'Upload content first, then review AI-generated lessons here.'
                  : 'Publish a draft unit to make it visible to learners.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (isDraft) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Content'),
                onPressed: onUpload,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
