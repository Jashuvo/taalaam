import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Renders a Bengali prompt string with smart formatting:
/// - Strips «» guillemet markers (used as Bengali quotes in tapToBuild prompts)
/// - Parses "(অর্থ: ...)" and renders the translation in a highlighted gold block
/// - Otherwise renders plain text
class PromptBn extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const PromptBn(this.text, {this.style, super.key});

  static final _meaningRe = RegExp(r'^(.*?)\s*\(অর্থ:\s*(.*?)\)\s*:?\s*$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.titleMedium;

    // Strip «» guillemets (Bengali translation quotes, not Arabic)
    final cleaned = text.replaceAll('«', '').replaceAll('»', '').trim();

    final match = _meaningRe.firstMatch(cleaned);
    if (match != null) {
      final instruction = match.group(1)!.trim();
      final meaning = match.group(2)!.trim();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (instruction.isNotEmpty)
            Text(
              instruction,
              style: baseStyle?.copyWith(
                fontSize: (baseStyle.fontSize ?? 16) - 1,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: Text(
              meaning,
              style: baseStyle?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Text(cleaned, style: baseStyle, textAlign: TextAlign.center);
  }
}
