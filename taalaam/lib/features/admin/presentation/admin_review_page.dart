import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _draftUnitsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final rows = await Supabase.instance.client
      .from('units')
      .select('id, title_bn, title_ar, status, track_id, sort_order, created_at')
      .eq('status', 'draft')
      .order('sort_order', ascending: true);
  return List<Map<String, dynamic>>.from(rows as List);
});

class AdminReviewPage extends ConsumerStatefulWidget {
  const AdminReviewPage({super.key});

  @override
  ConsumerState<AdminReviewPage> createState() => _AdminReviewPageState();
}

class _AdminReviewPageState extends ConsumerState<AdminReviewPage> {
  List<Map<String, dynamic>>? _localOrder;
  bool _reordering = false;

  Future<void> _onReorder(
      List<Map<String, dynamic>> units, int oldIndex, int newIndex) async {
    // onReorderItem already adjusts newIndex for the removed item
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
            .update({'sort_order': i})
            .eq('id', reordered[i]['id']);
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
    final drafts = ref.watch(_draftUnitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Drafts'),
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
            onPressed: () {
              setState(() => _localOrder = null);
              ref.invalidate(_draftUnitsProvider);
            },
          ),
        ],
      ),
      body: drafts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (fetched) {
          final units = _localOrder ?? fetched;
          if (units.isEmpty) {
            return _EmptyState(onUpload: () => context.go('/admin/upload'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            onReorderItem: (oldIndex, newIndex) =>
                _onReorder(units, oldIndex, newIndex),
            itemBuilder: (ctx, i) => _DraftUnitCard(
              key: ValueKey(units[i]['id']),
              unit: units[i],
              onRefresh: () {
                setState(() => _localOrder = null);
                ref.invalidate(_draftUnitsProvider);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DraftUnitCard extends StatefulWidget {
  final Map<String, dynamic> unit;
  final VoidCallback onRefresh;
  const _DraftUnitCard({required this.unit, required this.onRefresh, super.key});

  @override
  State<_DraftUnitCard> createState() => _DraftUnitCardState();
}

class _DraftUnitCardState extends State<_DraftUnitCard> {
  bool _publishing = false;

  Future<void> _publish() async {
    setState(() => _publishing = true);
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
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleBn = widget.unit['title_bn'] as String? ?? 'Untitled';
    final titleAr = widget.unit['title_ar'] as String?;

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
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('DRAFT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titleBn,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.drag_handle,
                    color: Colors.grey, size: 20),
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
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  onPressed: () =>
                      context.go('/admin/review/${widget.unit['id']}'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: _publishing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.publish, size: 16),
                  label: const Text('Publish'),
                  onPressed: _publishing ? null : _publish,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700),
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
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined,
                size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 24),
            Text('No Draft Lessons', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Upload content first, then review AI-generated lessons here.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Content'),
              onPressed: onUpload,
            ),
          ],
        ),
      ),
    );
  }
}
