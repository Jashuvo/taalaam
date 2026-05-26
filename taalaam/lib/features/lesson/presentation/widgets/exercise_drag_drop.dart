import 'package:flutter/material.dart';
import '../../domain/exercise_model.dart';

// On web/mobile: tap-to-match (drag not needed for Phase 1)
class ExerciseDragDrop extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExerciseDragDrop(
      {required this.exercise, required this.onAnswered, super.key});

  @override
  State<ExerciseDragDrop> createState() => _ExerciseDragDropState();
}

class _ExerciseDragDropState extends State<ExerciseDragDrop> {
  late final List<Map<String, String>> _pairs;
  late final List<String> _bnChoices;
  final Map<int, int> _matches = {}; // arIndex → bnIndex
  int? _selectedAr;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    final raw =
        List<Map<String, dynamic>>.from(widget.exercise.correctAnswer['pairs'] as List);
    _pairs = raw
        .map((p) => {'ar': p['ar'] as String, 'bn': p['bn'] as String})
        .toList();
    _bnChoices = _pairs.map((p) => p['bn']!).toList()..shuffle();
  }

  bool _checkAnswer() {
    for (var i = 0; i < _pairs.length; i++) {
      final matched = _matches[i];
      if (matched == null) return false;
      if (_bnChoices[matched] != _pairs[i]['bn']) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allMatched = _matches.length == _pairs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(widget.exercise.promptBn!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ),
        Text('আরবি শব্দের সাথে অর্থ মেলান:',
            style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arabic column
            Expanded(
              child: Column(
                children: List.generate(_pairs.length, (i) {
                  final selected = _selectedAr == i;
                  final matched = _matches.containsKey(i);
                  return GestureDetector(
                    onTap: _answered || matched
                        ? null
                        : () => setState(
                            () => _selectedAr = selected ? null : i),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: matched
                            ? Colors.green.shade100
                            : selected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          _pairs[i]['ar']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 20,
                              height: 1.6),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 12),
            // Bangla column
            Expanded(
              child: Column(
                children: List.generate(_bnChoices.length, (j) {
                  final alreadyUsed = _matches.values.contains(j);
                  return GestureDetector(
                    onTap: _answered || alreadyUsed || _selectedAr == null
                        ? null
                        : () {
                            setState(() {
                              _matches[_selectedAr!] = j;
                              _selectedAr = null;
                            });
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        color: alreadyUsed
                            ? Colors.green.shade100
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: theme.colorScheme.outline),
                      ),
                      child: Text(
                        _bnChoices[j],
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _answered || !allMatched
              ? null
              : () {
                  setState(() => _answered = true);
                  widget.onAnswered(_checkAnswer());
                },
          child: const Text('জমা দিন'),
        ),
      ],
    );
  }
}
