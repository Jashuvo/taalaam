import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/confirm_dialog.dart';

final _allUnitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await Supabase.instance.client
      .from('units')
      .select('id, title_bn, title_ar, status, track_id, sort_order')
      .order('sort_order', ascending: true);
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
      final allDuplicates = <Map<String, dynamic>>[];
      for (final trackId in trackIds) {
        final res = await Supabase.instance.client.functions
            .invoke('sort-units', body: {'track_id': trackId});
        final dupes = (res.data?['duplicates'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        allDuplicates.addAll(dupes);
      }
      _refresh();
      if (!mounted) return;
      if (allDuplicates.isNotEmpty) {
        _showDuplicateWarning(allDuplicates, isUnits: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Units sorted successfully!'),
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

  void _showDuplicateWarning(
      List<Map<String, dynamic>> duplicates, {required bool isUnits}) {
    final label = isUnits ? 'units' : 'lessons';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Text('Duplicate ${isUnits ? "Units" : "Lessons"} Found'),
        ]),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sorted successfully, but Gemini detected $label that teach '
                  'the same content. Consider merging them in the editor:',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...duplicates.map((d) {
                  final ids = (d['ids'] as List?)?.join(', ') ?? '';
                  final reason = d['reason'] as String? ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reason,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('IDs: $ids',
                            style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.grey)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
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
            .update({'sort_order': i}).eq('id', reordered[i]['id']);
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

class _UnitCardState extends State<_UnitCard> {
  bool _busy = false;

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
            const SizedBox(height: 10),
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
