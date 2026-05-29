import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class LessonCompleteScreen extends StatefulWidget {
  final int correctCount;
  final int totalCount;
  final int xpEarned;

  const LessonCompleteScreen({
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    super.key,
  });

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _fadeIn;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut);
    // Start confetti + fade in after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _fadeIn.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct =
        widget.totalCount > 0
            ? (widget.correctCount / widget.totalCount * 100).round()
            : 0;
    final duaa = AppConstants
        .completionDuaas[Random().nextInt(AppConstants.completionDuaas.length)];
    final parts = duaa.split(' — ');

    return Scaffold(
      body: Stack(
        children: [
          // ── Confetti emitter centred at top ───────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              gravity: 0.2,
              emissionFrequency: 0.05,
              colors: const [
                AppColors.brightGreen,
                AppColors.gold,
                AppColors.teal,
                Colors.white,
                Color(0xFF81C784),
              ],
            ),
          ),
          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            isDark
                                ? 'assets/logo_dark-removebg-preview.png'
                                : 'assets/logo_light-removebg-preview.png',
                            height: 130,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'পাঠ সম্পন্ন!',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Stats card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                                color: theme.colorScheme.outlineVariant),
                          ),
                          child: Column(
                            children: [
                              _StatRow(
                                icon: Icons.stars_rounded,
                                label: 'XP অর্জিত',
                                value: '+${widget.xpEarned} XP',
                                color: AppColors.gold,
                              ),
                              const Divider(height: 20),
                              _StatRow(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'নির্ভুলতা',
                                value: '$pct%',
                                color: pct >= 80
                                    ? AppColors.correctBg
                                    : theme.colorScheme.error,
                              ),
                              const Divider(height: 20),
                              _StatRow(
                                icon: Icons.quiz_outlined,
                                label: 'সঠিক উত্তর',
                                value:
                                    '${widget.correctCount} / ${widget.totalCount}',
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Du'aa
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.25),
                            borderRadius: AppRadius.lgBorder,
                            border: Border.all(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: [
                              if (parts.isNotEmpty)
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    parts[0],
                                    style: const TextStyle(
                                      fontFamily: 'NotoNaskhArabic',
                                      fontSize: 22,
                                      height: 1.8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              if (parts.length > 1) ...[
                                const SizedBox(height: 4),
                                Text(
                                  parts[1],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('হোমে ফিরুন'),
                          onPressed: () => context.go('/home'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('আজকের রিভিউ করুন'),
                          onPressed: () => context.go('/review'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(label, style: theme.textTheme.bodyLarge),
        const Spacer(),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
