import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/vocabulary_model.dart';
import '../../domain/exercise_model.dart';
import 'arabic_word_tooltip.dart' show ArabicSentenceWithTooltips, ArabicWordTooltip;

class ExerciseMultipleChoice extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool isCorrect) onAnswered;
  final Map<String, VocabularyModel> vocabMap;
  const ExerciseMultipleChoice(
      {required this.exercise, required this.onAnswered,
       this.vocabMap = const {}, super.key});

  @override
  State<ExerciseMultipleChoice> createState() =>
      _ExerciseMultipleChoiceState();
}

class _ExerciseMultipleChoiceState extends State<ExerciseMultipleChoice> {
  int? _selected;
  bool _checked = false;
  late final List<String> _options;
  late final int _correctIdx;

  @override
  void initState() {
    super.initState();
    final raw = List<String>.from(
        widget.exercise.correctAnswer['options'] as List);
    final correctAnswer =
        raw[widget.exercise.correctAnswer['correct_index'] as int];
    raw.shuffle();
    _options = raw;
    _correctIdx = raw.indexOf(correctAnswer);
  }

  bool get _canCheck => _selected != null && !_checked;

  void _check() {
    setState(() => _checked = true);
    widget.onAnswered(_selected == _correctIdx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.exercise.promptBn != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _PromptWithArabicWord(
              widget.exercise.promptBn!,
              baseStyle: theme.textTheme.titleMedium,
              vocabMap: widget.vocabMap,
            ),
          ),
        // Only show promptAr if promptBn doesn't already embed the Arabic word via «»
        if (widget.exercise.promptAr != null &&
            !RegExp(r'«[^»]+»').hasMatch(widget.exercise.promptBn ?? ''))
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ArabicSentenceWithTooltips(
                sentence: widget.exercise.promptAr!,
                vocabMap: widget.vocabMap,
                style: const TextStyle(
                    fontFamily: 'NotoNaskhArabic', fontSize: 26, height: 1.8),
              ),
            ),
          ),
        ...List.generate(_options.length, (i) {
          final isSelected = _selected == i;
          final isCorrect = i == _correctIdx;
          Color? tileColor;
          Color? textColor;
          if (_checked) {
            // Only reveal correct/wrong AFTER check is pressed
            if (isCorrect) {
              tileColor = AppColors.correctTile.withValues(alpha: 0.15);
              textColor = AppColors.correctBg;
            } else if (isSelected) {
              tileColor = AppColors.wrongTile.withValues(alpha: 0.15);
              textColor = AppColors.wrongBg;
            }
          } else if (isSelected) {
            // Selection highlight only — no spoiler
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
                  // Allow changing selection until Check is pressed
                  onTap: _checked ? null : () => setState(() => _selected = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: _OptionText(
                      _options[i],
                      color: textColor ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _canCheck ? _check : null,
          child: const Text('যাচাই করুন'),
        ),
      ],
    );
  }
}

/// Renders Bengali prompt text that may contain «Arabic word» markers.
/// The Arabic portion is extracted and displayed as a prominent styled block.
/// Renders a single option tile text, auto-detecting Arabic vs Bengali script.
class _OptionText extends StatelessWidget {
  final String text;
  final Color color;
  const _OptionText(this.text, {required this.color});

  static final _arabicRe = RegExp(r'[؀-ۿ]');

  @override
  Widget build(BuildContext context) {
    final isAr = _arabicRe.hasMatch(text);
    return Text(
      text,
      textAlign: TextAlign.center,
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        fontFamily: isAr ? 'NotoNaskhArabic' : null,
        fontSize: isAr ? 20 : 17,
        height: 1.8,
        color: color,
      ),
    );
  }
}

class _PromptWithArabicWord extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Map<String, VocabularyModel> vocabMap;
  const _PromptWithArabicWord(this.text, {this.baseStyle, this.vocabMap = const {}});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = baseStyle ?? theme.textTheme.titleMedium;
    final match = RegExp(r'«([^»]+)»').firstMatch(text);
    if (match == null) {
      return Text(text, style: style, textAlign: TextAlign.center);
    }
    final arabicWord = match.group(1)!.trim();
    // Only render gold block when the content is actually Arabic
    if (!RegExp(r'[؀-ۿ]').hasMatch(arabicWord)) {
      final stripped = text.replaceAll('«', '').replaceAll('»', '').trim();
      return Text(stripped, style: style, textAlign: TextAlign.center);
    }
    final before = text.substring(0, match.start).trim();
    final after = text.substring(match.end).trim();
    const arabicStyle = TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 28,
      height: 1.8,
      fontWeight: FontWeight.bold,
      color: AppColors.gold,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (before.isNotEmpty)
          Text(before, style: style, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
          ),
          child: ArabicWordTooltip(
            word: arabicWord,
            vocabMap: vocabMap,
            style: arabicStyle,
          ),
        ),
        if (after.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(after, style: style, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
