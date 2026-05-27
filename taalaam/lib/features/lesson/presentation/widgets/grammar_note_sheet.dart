import 'package:flutter/material.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';

class GrammarNoteSheet extends StatelessWidget {
  final bool correct;
  final String? grammarNote;
  final VoidCallback onNext;
  final ExerciseModel? exercise;
  final List<VocabularyModel> vocab;

  const GrammarNoteSheet({
    required this.correct,
    required this.onNext,
    this.grammarNote,
    this.exercise,
    this.vocab = const [],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct ? Colors.green.shade700 : theme.colorScheme.error;
    final bgColor = correct ? Colors.green.shade50 : Colors.red.shade50;

    final vocabMap = {for (final v in vocab) v.arabic: v};

    final correctWords = _resolveCorrectWords();

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
          if (!correct && correctWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'সঠিক উত্তর:',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: correctWords.map((word) {
                  final entry = vocabMap[word];
                  return _CorrectWordTile(
                    word: word,
                    meaningBn: entry?.meaningBn,
                    color: color,
                  );
                }).toList(),
              ),
            ),
          ],
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

  List<String> _resolveCorrectWords() {
    if (correct || exercise == null) return [];
    final ca = exercise!.correctAnswer;
    switch (exercise!.type) {
      case ExerciseType.tapToBuild:
        final words = ca['words'];
        if (words is List) return List<String>.from(words);
      case ExerciseType.wordScramble:
        final sentence = ca['correct'];
        if (sentence is String && sentence.isNotEmpty) {
          return sentence.split(' ').where((w) => w.isNotEmpty).toList();
        }
      default:
        break;
    }
    return [];
  }
}

class _CorrectWordTile extends StatelessWidget {
  final String word;
  final String? meaningBn;
  final Color color;

  const _CorrectWordTile({
    required this.word,
    required this.color,
    this.meaningBn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            word,
            style: TextStyle(
              fontFamily: 'NotoNaskhArabic',
              fontSize: 20,
              height: 1.6,
              color: color,
            ),
          ),
        ),
        if (meaningBn != null && meaningBn!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            meaningBn!,
            textDirection: TextDirection.ltr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
