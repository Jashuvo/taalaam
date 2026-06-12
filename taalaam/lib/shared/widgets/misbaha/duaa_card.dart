import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// A rotating du'aa card shown on lesson completion (`.duaa` in the demo) —
/// white card, gold top border, Arabic + Bangla translation + source.
class DuaaCard extends StatelessWidget {
  final String arabic;
  final String bangla;
  final String source;

  const DuaaCard({
    required this.arabic,
    required this.bangla,
    required this.source,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(height: 3, color: AppColors.gold, margin: const EdgeInsets.only(bottom: 11)),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              arabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 25,
                height: 1.7,
                color: isDark ? AppColors.darkPrimary : AppColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            bangla,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 12,
              color: isDark ? AppColors.darkOnSurfaceVariant : AppColors.ink2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            source,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.goldDeep,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
