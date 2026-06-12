import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Full-width primary CTA — forest→mid gradient, gold-tinted green shadow,
/// matches `.bigbtn` in the demo.
class BigButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const BigButton({required this.label, this.onPressed, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lgBorder,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.lgBorder,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.forestGreen, AppColors.midGreen],
              ),
              borderRadius: AppRadius.lgBorder,
              boxShadow: [
                BoxShadow(
                  color: AppColors.forestGreen.withValues(alpha: 0.5),
                  offset: const Offset(0, 8),
                  blurRadius: 20,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.cream, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small pill stat (`.chip`) — white card, line border, icon + label.
class StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color? iconColor;

  const StatChip({required this.icon, required this.label, this.iconColor, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: 13, color: iconColor)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkOnSurface : AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase gold section header (`.sh2`).
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 7),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'HindSiliguri',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.goldDeep,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Settings row with a label/subtitle and a custom 42x25 pill switch
/// (`.srow` + switch in the demo). The knob is 19dp; "on" uses [AppColors.midGreen].
class SettingsToggleRow extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: isDark ? AppColors.darkOutlineVariant : AppColors.line),
        borderRadius: AppRadius.mdBorder,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(icon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'HindSiliguri',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkOnSurface : AppColors.ink,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                          fontFamily: 'HindSiliguri', fontSize: 10.5, color: AppColors.ink2),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              width: 42,
              height: 25,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: value
                    ? AppColors.midGreen
                    : (isDark ? AppColors.darkOutlineVariant : AppColors.line),
              ),
              child: AnimatedAlign(
                duration: AppMotion.fast,
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
