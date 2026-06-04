import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'arabic_word_tooltip.dart';

/// "Complete the chat" exercise.
/// Shows speaker A's opening line and asks the learner to pick the correct reply.
class ExerciseChatComplete extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final Map<String, VocabularyModel> vocabMap;
  const ExerciseChatComplete({
    required this.exercise,
    required this.onAnswered,
    this.vocabMap = const {},
    super.key,
  });

  @override
  State<ExerciseChatComplete> createState() => _ExerciseChatCompleteState();
}

class _ExerciseChatCompleteState extends State<ExerciseChatComplete> {
  int? _selected;
  late final List<Map<String, dynamic>> _options;
  late final int _correctIdx;

  @override
  void initState() {
    super.initState();
    final ca = widget.exercise.correctAnswer;
    final rawOptions = List<Map<String, dynamic>>.from(
        (ca['options'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
    final correctAr = rawOptions[ca['correct_index'] as int]['ar'] as String;
    rawOptions.shuffle();
    _options = rawOptions;
    _correctIdx = rawOptions.indexWhere((o) => o['ar'] == correctAr);
  }

  bool get _canCheck => _selected != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = widget.exercise.correctAnswer;
    final speakerAAr = ca['speaker_a_ar'] as String? ?? '';
    final speakerABn = ca['speaker_a_bn'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Speaker A bubble (left, teal)
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 280),
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (speakerAAr.isNotEmpty)
                  ArabicSentenceWithTooltips(
                    sentence: speakerAAr,
                    vocabMap: widget.vocabMap,
                    style: const TextStyle(
                      fontFamily: 'NotoNaskhArabic',
                      fontSize: 22,
                      height: 1.8,
                    ),
                  ),
                if (speakerABn.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    speakerABn,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Blank reply bubble (right, dashed)
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 160),
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Text(
              '_ _ _',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Options
        ...List.generate(_options.length, (i) {
          final opt = _options[i];
          final ar = opt['ar'] as String? ?? '';
          final bn = opt['bn'] as String? ?? '';
          final selected = _selected == i;
          final correct = i == _correctIdx;
          Color? tileColor;
          Color? textColor;
          if (_selected != null) {
            if (correct) {
              tileColor = AppColors.correctTile.withValues(alpha: 0.15);
              textColor = AppColors.correctBg;
            } else if (selected) {
              tileColor = AppColors.wrongTile.withValues(alpha: 0.15);
              textColor = AppColors.wrongBg;
            }
          }
          return TweenAnimationBuilder<double>(
            key: ValueKey(i),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + i * 60),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 14 * (1 - value)),
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
                  onTap: _selected != null
                      ? null
                      : () => setState(() => _selected = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            ar,
                            style: TextStyle(
                              fontFamily: 'NotoNaskhArabic',
                              fontSize: 20,
                              height: 1.8,
                              color:
                                  textColor ?? theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        if (bn.isNotEmpty)
                          Text(
                            bn,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: (textColor ??
                                      theme.colorScheme.onSurfaceVariant)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _canCheck
              ? () => widget.onAnswered(_selected == _correctIdx)
              : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}
