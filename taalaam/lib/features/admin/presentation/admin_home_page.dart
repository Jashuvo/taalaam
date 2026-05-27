import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _clearing = false;

  Future<void> _confirmAndClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
        title: const Text('Clear All Content?'),
        content: const Text(
          'This will permanently delete ALL units, lessons, exercises, '
          'vocabulary, and source materials from the database.\n\n'
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
