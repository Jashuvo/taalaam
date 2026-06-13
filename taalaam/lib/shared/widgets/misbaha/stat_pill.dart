import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// A small completion-stat pill (`.cp` / `.cp.gold` in the demo): a big
/// number/value on top with a small uppercase label below.
class StatPill extends StatelessWidget {
  final Widget value;
  final String label;
  final bool gold;
  const StatPill({required this.value, required this.label, this.gold = false, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberColor = gold
        ? AppColors.goldDeep
        : (isDark ? AppColors.darkPrimary : AppColors.forestGreen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: gold
            ? const Color(0xFFFBF3DE)
            : (isDark ? AppColors.darkCard : Colors.white),
        border: Border.all(
            color: gold
                ? const Color(0xFFEAD9A8)
                : (isDark ? AppColors.darkOutlineVariant : AppColors.line)),
        borderRadius: AppRadius.mdBorder,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: numberColor,
            ),
            child: value,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 10,
              color: AppColors.ink2,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
