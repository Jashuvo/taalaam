import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

class ExercisePatternMatch extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  const ExercisePatternMatch(
      {required this.exercise, required this.onAnswered, super.key});

  @override
  State<ExercisePatternMatch> createState() => _ExercisePatternMatchState();
}

class _ExercisePatternMatchState extends State<ExercisePatternMatch> {
  int? _selected;
  bool _checked = false;
  late final List<String> _options;
  late final int _correctIdx;

  String get _wordAr => widget.exercise.correctAnswer['word_ar'] as String? ?? '';
  String get _root => widget.exercise.correctAnswer['root'] as String? ?? '';
  String get _patternMeaningBn =>
      widget.exercise.correctAnswer['pattern_meaning_bn'] as String? ?? '';
  List<String> get _siblings {
    final raw = widget.exercise.correctAnswer['siblings'];
    return raw is List ? List<String>.from(raw) : <String>[];
  }

  @override
  void initState() {
    super.initState();
    final correctPattern =
        widget.exercise.correctAnswer['pattern'] as String? ?? '';
    final distractorsRaw = widget.exercise.distractors?['options'];
    final distractors =
        distractorsRaw is List ? List<String>.from(distractorsRaw) : <String>[];
    final raw = [correctPattern, ...distractors]..shuffle();
    _options = raw;
    _correctIdx = raw.indexOf(correctPattern);
  }

  bool get _canCheck => _selected != null && !_checked;

  void _check() {
    setState(() => _checked = true);
    widget.onAnswered(_selected == _correctIdx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rootLetters = _root.split('-').where((l) => l.trim().isNotEmpty).toList();
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
        // Word large on top
        Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              _wordAr,
              style: const TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 40,
                height: 1.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (rootLetters.isNotEmpty) ...[
          const SizedBox(height: 8),
          Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Wrap(
                spacing: 10,
                children: rootLetters
                    .map((l) => Text(
                          l,
                          style: TextStyle(
                            fontFamily: 'NotoNaskhArabic',
                            fontSize: 24,
                            height: 1.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        ...List.generate(_options.length, (i) {
          final isSelected = _selected == i;
          final isCorrect = i == _correctIdx;
          Color? tileColor;
          Color? textColor;
          if (_checked) {
            if (isCorrect) {
              tileColor = AppColors.correctTile.withValues(alpha: 0.15);
              textColor = AppColors.correctBg;
            } else if (isSelected) {
              tileColor = AppColors.wrongTile.withValues(alpha: 0.15);
              textColor = AppColors.wrongBg;
            }
          } else if (isSelected) {
            tileColor = theme.colorScheme.primaryContainer.withValues(alpha: 0.5);
            textColor = theme.colorScheme.primary;
          }
          return TweenAnimationBuilder<double>(
            key: ValueKey(i),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 180 + i * 60),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - value)),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: tileColor ?? theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _checked ? null : () => setState(() => _selected = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        _options[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 22,
                          height: 1.8,
                          color: textColor ?? theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        if (_checked) ...[
          const SizedBox(height: 8),
          if (_patternMeaningBn.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _patternMeaningBn,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (_siblings.isNotEmpty)
            Center(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'একই ছাঁচে: '),
                      TextSpan(
                        text: _siblings.join('، '),
                        style: const TextStyle(fontFamily: 'NotoNaskhArabic'),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    height: 1.8,
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _canCheck ? _check : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}
