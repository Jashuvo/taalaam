import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/exercise_model.dart';

/// Tested exercise: a statement about a Divine Name is shown.
/// Learner decides if it conforms to the Salafi aqeedah position (صحيح / خطأ).
/// After answering, the correct Ibn Uthaymin / Ibn Sa'di explanation is shown.
///
/// correct_answer shape:
/// {
///   "statement_bn": "আল্লাহ الرَّحِيم মানে তিনি মানুষের মতো দয়া অনুভব করেন",
///   "is_correct": false,
///   "explanation_bn": "এটি ভুল। আল্লাহর রহমত সত্য (ইসবাত), তবে সৃষ্টির রহমতের মতো নয়..."
/// }
class ExerciseAqeedahTrue extends StatefulWidget {
  final ExerciseModel exercise;
  final void Function(bool) onAnswered;

  const ExerciseAqeedahTrue({
    required this.exercise,
    required this.onAnswered,
    super.key,
  });

  @override
  State<ExerciseAqeedahTrue> createState() => _ExerciseAqeedahTrueState();
}

class _ExerciseAqeedahTrueState extends State<ExerciseAqeedahTrue> {
  bool? _choice;    // true = learner said "সঠিক", false = learner said "ভুল"
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca           = widget.exercise.correctAnswer;
    final statementBn  = ca['statement_bn']   as String? ?? '';
    final isCorrect    = ca['is_correct']      as bool?  ?? false;
    final explanation  = ca['explanation_bn']  as String? ?? '';

    final bool? correct = _answered ? (_choice == isCorrect) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header badge
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_outlined, size: 13, color: AppColors.gold),
                  const SizedBox(width: 5),
                  Text(
                    'আকীদাহ যাচাই',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Statement card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.exercise.promptBn ?? 'এই বক্তব্যটি কি সঠিক?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                statementBn,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // True / False buttons
        Row(
          children: [
            Expanded(
              child: _ChoiceButton(
                label: 'সঠিক',
                arabicLabel: 'صَحِيحٌ',
                icon: Icons.check_rounded,
                color: AppColors.correctBg,
                selected: _choice == true,
                revealed: _answered,
                isThisCorrect: isCorrect == true,
                onTap: _answered ? null : () => setState(() => _choice = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceButton(
                label: 'ভুল',
                arabicLabel: 'خَطَأٌ',
                icon: Icons.close_rounded,
                color: AppColors.wrongBg,
                selected: _choice == false,
                revealed: _answered,
                isThisCorrect: isCorrect == false,
                onTap: _answered ? null : () => setState(() => _choice = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Explanation (shown after answering)
        if (_answered && explanation.isNotEmpty) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (correct! ? AppColors.correctBg : AppColors.wrongBg).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (correct ? AppColors.correctBg : AppColors.wrongBg).withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: 16,
                  color: correct ? AppColors.correctBg : AppColors.wrongBg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    explanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.65,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        FilledButton(
          onPressed: _choice == null || _answered
              ? null
              : () {
                  setState(() => _answered = true);
                  widget.onAnswered(_choice == isCorrect);
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

class _ChoiceButton extends StatelessWidget {
  final String label;
  final String arabicLabel;
  final IconData icon;
  final Color color;
  final bool selected;
  final bool revealed;
  final bool isThisCorrect;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.label,
    required this.arabicLabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.revealed,
    required this.isThisCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bgColor     = theme.colorScheme.surfaceContainerLow;
    Color borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
    Color textColor   = theme.colorScheme.onSurface;

    if (revealed) {
      if (isThisCorrect) {
        bgColor     = AppColors.correctBg.withValues(alpha: 0.12);
        borderColor = AppColors.correctBg;
        textColor   = AppColors.correctBg;
      } else if (selected) {
        bgColor     = AppColors.wrongBg.withValues(alpha: 0.12);
        borderColor = AppColors.wrongBg;
        textColor   = AppColors.wrongBg;
      }
    } else if (selected) {
      bgColor     = color.withValues(alpha: 0.12);
      borderColor = color;
      textColor   = color;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected || revealed ? 1.5 : 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: textColor, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                arabicLabel,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 16,
                  height: 1.7,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
