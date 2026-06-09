import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Tested exercise: 4 words are shown, learner identifies which one is a
/// verb (فعل), noun (اسم), or particle (حرف).
/// Uses the `pos` (part-of-speech) data from quran_words.
///
/// correct_answer shape:
/// {
///   "target_pos_ar": "فِعْلٌ",
///   "target_pos_bn": "ক্রিয়াপদ",
///   "words": [
///     {"arabic": "يَعْلَمُ", "meaning_bn": "তিনি জানেন", "pos": "verb"},
///     {"arabic": "رَبِّ",    "meaning_bn": "প্রতিপালক",  "pos": "noun"},
///     {"arabic": "الرَّحِيمِ","meaning_bn": "অতিশয় দয়ালু","pos": "noun"},
///     {"arabic": "فِي",      "meaning_bn": "এর মধ্যে",  "pos": "particle"}
///   ],
///   "correct_index": 0
/// }
class ExerciseGrammarSpot extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseGrammarSpot({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseGrammarSpot> createState() => _ExerciseGrammarSpotState();
}

class _ExerciseGrammarSpotState extends State<ExerciseGrammarSpot> {
  int? _selected;
  bool _answered = false;

  static const _posColors = {
    'verb':     Color(0xFF1565C0), // blue
    'noun':     Color(0xFF2E7D32), // green
    'particle': Color(0xFF6A1B9A), // purple
  };

  static const _posIcons = {
    'verb':     Icons.play_arrow_rounded,
    'noun':     Icons.label_rounded,
    'particle': Icons.link_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca         = widget.exercise.correctAnswer;
    final posAr      = ca['target_pos_ar'] as String? ?? 'فِعْلٌ';
    final posBn      = ca['target_pos_bn'] as String? ?? 'ক্রিয়াপদ';
    final wordsList  = (ca['words'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final correctIdx = ca['correct_index'] as int? ?? 0;

    final targetPos  = (wordsList.isNotEmpty
        ? wordsList[correctIdx]['pos'] as String?
        : null) ?? 'verb';
    final targetColor = _posColors[targetPos] ?? AppColors.teal;
    final targetIcon  = _posIcons[targetPos]  ?? Icons.help_outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Target POS hero display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                targetColor.withValues(alpha: 0.12),
                targetColor.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: targetColor.withValues(alpha: 0.30)),
          ),
          child: Column(
            children: [
              Icon(targetIcon, size: 32, color: targetColor),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  posAr,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 26,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                    color: targetColor,
                  ),
                ),
              ),
              Text(
                posBn,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: targetColor.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.exercise.promptBn ?? 'কোনটি $posBn?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2×2 word grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: wordsList.asMap().entries.map((e) {
            final idx  = e.key;
            final word = e.value;
            final ar   = word['arabic']     as String? ?? '';
            final bn   = word['meaning_bn'] as String? ?? '';
            final pos  = word['pos']        as String? ?? '';

            final wordColor = _posColors[pos] ?? theme.colorScheme.onSurface;

            Color bgColor     = theme.colorScheme.surfaceContainerLow;
            Color borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);

            if (_answered) {
              if (idx == correctIdx) {
                bgColor     = AppColors.correctBg.withValues(alpha: 0.12);
                borderColor = AppColors.correctBg;
              } else if (idx == _selected) {
                bgColor     = AppColors.wrongBg.withValues(alpha: 0.12);
                borderColor = AppColors.wrongBg;
              }
            } else if (_selected == idx) {
              bgColor     = theme.colorScheme.primaryContainer;
              borderColor = theme.colorScheme.primary;
            }

            return GestureDetector(
              onTap: _answered ? null : () => setState(() => _selected = idx),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: _selected == idx || _answered ? 1.5 : 1.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        ar,
                        style: TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 20,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
                          // After answering, tint each word by its actual POS color
                          color: _answered ? wordColor : null,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      bn,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        FilledButton(
          onPressed: _selected == null || _answered
              ? null
              : () {
                  setState(() => _answered = true);
                  widget.onAnswered(_selected == correctIdx);
                },
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('উত্তর দিন', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
