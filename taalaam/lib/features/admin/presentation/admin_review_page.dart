import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          if (_reordering)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit?'),
        content: Text(
            'Delete "${widget.unit['title_bn']}" and all its lessons and exercises?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDraft
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isDraft ? 'DRAFT' : 'PUBLISHED',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDraft
                            ? Colors.orange.shade800
                            : Colors.green.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titleBn,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
              ],
            ),
            if (titleAr != null && titleAr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  titleAr,
                  style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 16,
                      height: 1.6),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_busy)
              const Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    onPressed: () =>
                        context.go('/admin/review/${widget.unit['id']}'),
                  ),
                  if (isDraft)
                    FilledButton.icon(
                      icon: const Icon(Icons.publish, size: 16),
                      label: const Text('Publish'),
                      onPressed: _publish,
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700),
                    )
                  else
                    OutlinedButton.icon(
                      icon: const Icon(Icons.unpublished_outlined, size: 16),
                      label: const Text('Unpublish'),
                      onPressed: _unpublish,
                    ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
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
