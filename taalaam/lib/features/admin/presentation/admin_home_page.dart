import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _clearing = false;

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Clear All Content?',
      body: 'This will permanently delete ALL units, lessons, exercises, '
          'vocabulary, and source materials from the database.\n\nThis cannot be undone.',
      confirmLabel: 'Delete Everything',
      cancelLabel: 'Cancel',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _clearing = true);
    try {
      // Security-definer RPC — bypasses RLS, guaranteed to wipe everything
      await Supabase.instance.client.rpc('admin_clear_all_content');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All content deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Ta'allam — لوحة التحكم"),
        backgroundColor: theme.colorScheme.primaryContainer,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _clearing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting all content…'),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.mosque_outlined,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Content Management',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Arabic learning material and manage lessons',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      _AdminActionCard(
                        icon: Icons.upload_file_outlined,
                        title: 'Upload Content',
                        subtitle: 'PDF, text, or image → AI lesson generation',
                        onTap: () => context.go('/admin/upload'),
                      ),
                      const SizedBox(height: 16),
                      _AdminActionCard(
                        icon: Icons.rate_review_outlined,
                        title: 'Review Drafts',
                        subtitle: 'Edit and publish AI-generated lessons',
                        onTap: () => context.go('/admin/review'),
                      ),
                      const SizedBox(height: 16),
                      _QuranCurationCard(),
                      const SizedBox(height: 16),
                      _AdminActionCard(
                        icon: Icons.delete_sweep_outlined,
                        title: 'Clear All Content',
                        subtitle: 'Delete all units, lessons, exercises & vocabulary',
                        onTap: _confirmAndClearAll,
                        danger: true,
                      ),
                      const SizedBox(height: 32),
                      // RTL verification widget
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Arabic rendering test:',
                              style: theme.textTheme.labelSmall,
                            ),
                            const SizedBox(height: 8),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                'هُوَ أُسْتَاذٌ جَدِيدٌ',
                                style: TextStyle(
                                  fontFamily: 'NotoNaskhArabic',
                                  fontSize: 22,
                                  height: 1.8,
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
              ),
            ),
    );
  }
}

// ── Quranic lesson curation card ─────────────────────────────────────────────

class _QuranCurationCard extends StatefulWidget {
  @override
  State<_QuranCurationCard> createState() => _QuranCurationCardState();
}

class _QuranCurationCardState extends State<_QuranCurationCard> {
  bool _loading = false;
  int? _selectedSurah;
  List<Map<String, dynamic>> _surahs = [];

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final rows = await Supabase.instance.client
          .from('quran_surahs')
          .select('number, name_bn')
          .order('number') as List;
      if (mounted) {
        setState(() {
          _surahs = rows.cast<Map<String, dynamic>>();
          if (_surahs.isNotEmpty) _selectedSurah = _surahs.first['number'] as int;
        });
      }
    } catch (_) {}
  }

  Future<void> _curate(BuildContext ctx) async {
    if (_selectedSurah == null) return;
    final surahName = _surahs
        .where((s) => s['number'] == _selectedSurah)
        .firstOrNull?['name_bn'] as String? ?? '$_selectedSurah';

    setState(() => _loading = true);
    try {
      final res = await Supabase.instance.client.functions
          .invoke('curate-quran-lesson', body: {'surah_number': _selectedSurah});
      final err = res.data?['error'] as String?;
      if (err != null) throw Exception(err);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('সূরা $surahName থেকে পাঠ তৈরি হয়েছে ✓'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('ত্রুটি: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPicker(BuildContext ctx) {
    if (_surahs.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('সূরা তালিকা লোড হয়নি। quran_surahs টেবিল পরীক্ষা করুন।'),
      ));
      return;
    }
    showDialog<void>(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDlgState) => AlertDialog(
          title: const Text('সূরা বেছে নিন'),
          content: SizedBox(
            width: 320,
            child: DropdownButton<int>(
              value: _selectedSurah,
              isExpanded: true,
              items: _surahs.map((s) {
                final n = s['number'] as int;
                final name = s['name_bn'] as String? ?? '$n';
                return DropdownMenuItem(value: n, child: Text('$n. $name'));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedSurah = v);
                  setDlgState(() {});
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: _loading
                  ? null
                  : () {
                      Navigator.pop(dCtx);
                      _curate(ctx);
                    },
              child: const Text('পাঠ তৈরি করুন'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.forestGreen.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.menu_book_rounded,
                  color: AppColors.forestGreen),
        ),
        title: Text(
          'কুরআনিক পাঠ তৈরি',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.forestGreen,
          ),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('যেকোনো সূরা থেকে স্বয়ংক্রিয় পাঠ'),
        ),
        trailing: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _loading ? null : () => _showPicker(context),
          child: const Text('সূরা বেছে নিন'),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconBg = danger ? theme.colorScheme.errorContainer : theme.colorScheme.primaryContainer;
    final iconColor = danger ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer;
    final borderColor = danger
        ? theme.colorScheme.error.withValues(alpha: 0.4)
        : theme.colorScheme.outline.withValues(alpha: 0.3);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: danger ? theme.colorScheme.error : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
