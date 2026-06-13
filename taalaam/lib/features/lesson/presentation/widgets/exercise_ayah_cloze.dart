import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Tested exercise: a full ayah is shown with one word blanked out (___).
/// Learner picks the missing word from 4 Arabic options.
/// Higher cognitive load than ayahContext — tests production/recall, not just recognition.
///
/// correct_answer shape:
/// {
///   "ayah_ar": "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
///   "surah_name": "সূরা আল-ফাতিহা",
///   "ayah_number": 2,
///   "blank_word": "الْعَالَمِينَ",
///   "blank_position": 5,
///   "options": ["الْعَالَمِينَ", "الرَّحِيمِ", "الْمُلْكِ", "الصِّرَاطَ"],
///   "correct_index": 0
/// }
class ExerciseAyahCloze extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseAyahCloze({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseAyahCloze> createState() => _ExerciseAyahClozeState();
}

class _ExerciseAyahClozeState extends State<ExerciseAyahCloze> {
  int? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca          = widget.exercise.correctAnswer;
    final ayahAr      = ca['ayah_ar']      as String? ?? '';
    final surahName   = ca['surah_name']   as String? ?? '';
    final ayahNumber  = ca['ayah_number']  as int?    ?? 0;
    final blankWord   = ca['blank_word']   as String? ?? '';
    final options     = (ca['options']     as List?)?.cast<String>() ?? [];
    final correctIdx  = ca['correct_index'] as int?   ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Surah + question label
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.35)),
              ),
              child: Text(
                '$surahName — আয়াত $ayahNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text(
          widget.exercise.promptBn ?? 'শূন্যস্থানে কোন শব্দটি বসবে?',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),

        // Ayah with blank
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.20)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _AyahWithBlank(
              ayah: ayahAr,
              blankWord: blankWord,
              filledWord: _answered ? options[correctIdx] : null,
              isCorrect: _answered ? (_selected == correctIdx) : null,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2×2 Arabic option grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: options.asMap().entries.map((e) {
            final idx  = e.key;
            final word = e.value;

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
                child: Center(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      word,
                      style: TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 18,
                        height: 1.7,
                        fontWeight: _selected == idx ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
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

/// Renders the ayah with the blank word replaced by a dashed gold box.
/// After answering, shows the correct word filled in (green or red).
class _AyahWithBlank extends StatelessWidget {
  final String ayah;
  final String blankWord;
  final String? filledWord;  // non-null after answering
  final bool? isCorrect;

  const _AyahWithBlank({
    required this.ayah,
    required this.blankWord,
    required this.filledWord,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    if (blankWord.isEmpty || !ayah.contains(blankWord)) {
      return Text(
        ayah,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'NotoNaskhArabic',
          fontSize: 22,
          height: 2.0,
        ),
      );
    }

    final parts = ayah.split(blankWord);
    final spans = <InlineSpan>[];
    final baseStyle = const TextStyle(
      fontFamily: 'NotoNaskhArabic',
      fontSize: 22,
      height: 2.0,
      color: AppColors.forestGreen,
    );

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i], style: baseStyle));
      if (i < parts.length - 1) {
        if (filledWord != null) {
          // Show filled word in green (correct) or red (wrong) after answering
          final fillColor = isCorrect == true ? AppColors.correctBg : AppColors.wrongBg;
          spans.add(TextSpan(
            text: filledWord,
            style: baseStyle.copyWith(
              color: fillColor,
              fontWeight: FontWeight.bold,
              backgroundColor: fillColor.withValues(alpha: 0.12),
            ),
          ));
        } else {
          // Show blank placeholder
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.gold, width: 2.5, style: BorderStyle.solid),
                ),
              ),
              child: Text(
                '  ؟  ',
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 22,
                  height: 1.4,
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ));
        }
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.center,
    );
  }
}
