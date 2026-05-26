import 'package:flutter/material.dart';

class GrammarNoteSheet extends StatelessWidget {
  final bool correct;
  final String? grammarNote;
  final VoidCallback onNext;

  const GrammarNoteSheet({
    required this.correct,
    required this.onNext,
    this.grammarNote,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? Colors.green.shade700 : theme.colorScheme.error;
    final bgColor = correct ? Colors.green.shade50 : Colors.red.shade50;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
              const SizedBox(width: 8),
              Text(
                correct ? 'সঠিক! চমৎকার!' : 'ভুল হয়েছে',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (grammarNote != null && grammarNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              grammarNote!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: color.withValues(alpha: 0.85)),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(backgroundColor: color),
            child: const Text('পরবর্তী'),
          ),
        ],
      ),
    );
  }
}
