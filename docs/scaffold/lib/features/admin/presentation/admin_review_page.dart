import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminReviewPage extends StatelessWidget {
  const AdminReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Drafts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Draft Lessons',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload content first, then review AI-generated lessons here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Content'),
              onPressed: () => context.go('/admin/upload'),
            ),
          ],
        ),
      ),
    );
  }
}
