import 'package:flutter/material.dart';
import '../../domain/exercise_model.dart';

class ExerciseWordScramble extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExerciseWordScramble(
      {required this.exercise, required this.onAnswered, super.key});

  @override
  State<ExerciseWordScramble> createState() => _ExerciseWordScrambleState();
}

class _ExerciseWordScrambleState extends State<ExerciseWordScramble> {
  late List<String> _bank;
  final List<String> _built = [];
  bool _answered = false;

  List<String> get _words =>
      List<String>.from(widget.exercise.correctAnswer['words'] as List);
  String get _correct => widget.exercise.correctAnswer['correct'] as String;

  @override
  void initState() {
    super.initState();
    _bank = List<String>.from(_words)..shuffle();
    // Ensure shuffled != correct order
    while (_bank.join(' ') == _correct && _bank.length > 1) {
      _bank.shuffle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        Text('সঠিক ক্রমে সাজান:',
            style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        // Built sentence area
        Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _built.map((w) {
                return GestureDetector(
                  onTap: _answered
                      ? null
                      : () => setState(() {
                            _built.remove(w);
                            _bank.add(w);
                          }),
                  child: _Chip(word: w, active: true, theme: theme),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Word bank
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _bank.map((w) {
              return GestureDetector(
                onTap: _answered
                    ? null
                    : () => setState(() {
                          _bank.remove(w);
                          _built.add(w);
                        }),
                child: _Chip(word: w, active: false, theme: theme),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _answered || _built.isEmpty
              ? null
              : () {
                  setState(() => _answered = true);
                  widget.onAnswered(_built.join(' ') == _correct);
                },
          child: const Text('জমা দিন'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String word;
  final bool active;
  final ThemeData theme;
  const _Chip({required this.word, required this.active, required this.theme});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline),
        ),
        child: Text(
          word,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 20,
            height: 1.6,
            color: active
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      );
}
