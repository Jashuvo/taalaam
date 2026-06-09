import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Tested exercise: 4 Arabic words are shown — 3 share a root, 1 is an outsider.
/// Learner picks the word that does NOT belong to the given root family.
///
/// correct_answer shape:
/// {
///   "root_ar": "ر-ح-م",
///   "root_meaning_bn": "দয়া করা — ব্যাপক অনুগ্রহ",
///   "words": [
///     {"arabic": "رَحِيمٌ", "meaning_bn": "অতিশয় দয়ালু"},
///     {"arabic": "رَحْمَةٌ", "meaning_bn": "দয়া"},
///     {"arabic": "يَرْحَمُ", "meaning_bn": "তিনি দয়া করেন"},
///     {"arabic": "كَرِيمٌ", "meaning_bn": "মহামান্য"}
///   ],
///   "odd_index": 3
/// }
class ExerciseRootFamily extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseRootFamily({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseRootFamily> createState() => _ExerciseRootFamilyState();
}

class _ExerciseRootFamilyState extends State<ExerciseRootFamily> {
  int? _selected;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = widget.exercise.correctAnswer;
    final rootAr       = ca['root_ar']        as String? ?? '';
    final rootMeaning  = ca['root_meaning_bn'] as String? ?? '';
    final wordsList    = (ca['words'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final oddIndex     = ca['odd_index']       as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header chip
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_tree_outlined, size: 13, color: AppColors.forestGreen),
                  const SizedBox(width: 5),
                  Text(
                    'ধাতু পরিবার',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Root display card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.forestGreen.withValues(alpha: 0.10),
                AppColors.forestGreen.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                widget.exercise.promptBn ?? 'কোন শব্দটি এই ধাতুর নয়?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  rootAr,
                  style: TextStyle(
                    fontFamily: 'NotoNaskhArabic',
                    fontSize: 28,
                    height: 1.8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (rootMeaning.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  rootMeaning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
            final ar   = word['arabic']    as String? ?? '';
            final bn   = word['meaning_bn'] as String? ?? '';

            Color borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
            Color bgColor     = theme.colorScheme.surfaceContainerLow;

            if (_answered) {
              if (idx == oddIndex) {
                borderColor = AppColors.correctBg;
                bgColor     = AppColors.correctBg.withValues(alpha: 0.10);
              } else if (idx == _selected && idx != oddIndex) {
                borderColor = AppColors.wrongBg;
                bgColor     = AppColors.wrongBg.withValues(alpha: 0.10);
              }
            } else if (_selected == idx) {
              borderColor = theme.colorScheme.primary;
              bgColor     = theme.colorScheme.primaryContainer;
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
                        style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 20,
                          height: 1.7,
                          fontWeight: FontWeight.w600,
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
                  widget.onAnswered(_selected == oddIndex);
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
