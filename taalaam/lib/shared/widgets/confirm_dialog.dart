import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Single source of truth for all yes/no confirm dialogs.
/// Buttons always appear in a right-aligned row — never stacked.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  String cancelLabel = 'না',
  String confirmLabel = 'হ্যাঁ',
  bool danger = false,
}) async {
  final cs = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: cs.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      title: Text(title),
      content: Text(body),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 44),
                backgroundColor: danger ? cs.error : null,
                foregroundColor: danger ? cs.onError : null,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
