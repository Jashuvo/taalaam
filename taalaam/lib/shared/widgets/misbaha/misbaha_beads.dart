import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

const _labelStyle = TextStyle(
  fontFamily: 'HindSiliguri',
  fontSize: 12.5,
  fontWeight: FontWeight.w600,
  color: AppColors.ink,
);

const _subStyle = TextStyle(
  fontFamily: 'HindSiliguri',
  fontSize: 10.5,
  color: AppColors.ink2,
);

/// A completed lesson bead — filled circle in the track colour with a
/// gold ✦ glyph, label below, and optional accuracy stars.
class DoneBead extends StatelessWidget {
  final String label;
  final Color fill;

  /// 0-3 stars earned for this lesson's accuracy, or null to hide the row.
  final int? accuracyStars;
  final VoidCallback? onTap;

  const DoneBead({
    required this.label,
    required this.fill,
    this.accuracyStars,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final stars = accuracyStars?.clamp(0, 3);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
                ),
                Positioned(
                  left: 5,
                  top: 5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '✦',
                    style: GoogleFonts.amiri(
                        fontSize: 14, color: AppColors.goldLight, height: 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: _labelStyle),
          if (stars != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '★' * stars + '☆' * (3 - stars),
                style: const TextStyle(fontSize: 9, color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

/// The current/next-up lesson bead: a pulsing gold ring around a
/// radial-gradient bead showing the first Arabic letter of the lesson title,
/// with the lesson label + sub-label beside it.
class CurrentBead extends StatefulWidget {
  final String label;
  final String sub;

  /// First Arabic letter of the lesson title; falls back to ✦.
  final String? arabicLetter;
  final VoidCallback? onTap;

  const CurrentBead({
    required this.label,
    required this.sub,
    this.arabicLetter,
    this.onTap,
    super.key,
  });

  @override
  State<CurrentBead> createState() => _CurrentBeadState();
}

class _CurrentBeadState extends State<CurrentBead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.beadPulse);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final opacity = reduceMotion
                        ? 0.3
                        : 0.08 + (0.55 - 0.08) * (0.5 + 0.5 * cos(_pulse.value * 2 * pi));
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: opacity),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.3, -0.4),
                      radius: 0.9,
                      colors: [AppColors.goldLight, Color(0xFFC9920E)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .3),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          widget.arabicLetter ?? '✦',
                          style: GoogleFonts.amiri(
                              fontSize: 18, color: AppColors.deepGreen, height: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label,
                    style: _labelStyle.copyWith(fontWeight: FontWeight.w700)),
                Text(widget.sub, style: _subStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A locked, not-yet-reachable lesson bead.
class LockedBead extends StatelessWidget {
  final String label;
  const LockedBead({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, textAlign: TextAlign.center, style: _subStyle),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEFEADE),
            border: Border.all(color: const Color(0xFFD8D0BD), width: 1.5),
          ),
          child: const Center(child: Text('🔒', style: TextStyle(fontSize: 11))),
        ),
      ],
    );
  }
}

/// The unit-exam node on the misbaha path. Dashed gold outline while locked,
/// filled gold with a ★ once completed.
class ExamNode extends StatelessWidget {
  final bool completed;
  final VoidCallback? onTap;
  const ExamNode({this.completed = false, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
              child: const Center(
                child: Text('★', style: TextStyle(fontSize: 15, color: Colors.white)),
              ),
            )
          else
            CustomPaint(
              size: const Size(38, 38),
              painter: const _DashedCirclePainter(color: AppColors.gold),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFBF3DE)),
                child: const Center(
                  child: Text('★', style: TextStyle(fontSize: 15, color: AppColors.goldDeep)),
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Text('ইউনিট পরীক্ষা', textAlign: TextAlign.center, style: _subStyle),
        ],
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addOval(Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}

/// The conversational-track midpoint bonus node ("বোনাস XP" — never framed
/// as in-app currency, just bonus XP).
class ChestNode extends StatelessWidget {
  final VoidCallback? onTap;
  const ChestNode({this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 32,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                        color: AppColors.goldLight, borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 2,
                  child: Container(
                    width: 36,
                    height: 20,
                    decoration: BoxDecoration(
                        color: const Color(0xFFC9920E), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 17,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF7A5500)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text('বোনাস XP', style: _subStyle),
        ],
      ),
    );
  }
}

/// Decorative tassel hanging from the final bead on a misbaha path.
class TasselOrnament extends StatelessWidget {
  const TasselOrnament({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(40, 65), painter: _TasselPainter());
}

class _TasselPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cordPaint = Paint()
      ..color = AppColors.misbahaCord
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, const Offset(20, 22), cordPaint);

    final bodyPaint = Paint()..color = const Color(0xFFD4A017);
    final body = Path()
      ..moveTo(14, 20)
      ..lineTo(26, 20)
      ..lineTo(30, 46)
      ..lineTo(10, 46)
      ..close();
    canvas.drawPath(body, bodyPaint);

    final fringePaint = Paint()
      ..color = const Color(0xFFA87B0A)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(14, 46), const Offset(12, 60), fringePaint);
    canvas.drawLine(const Offset(20, 46), const Offset(20, 62), fringePaint);
    canvas.drawLine(const Offset(26, 46), const Offset(28, 60), fringePaint);
  }

  @override
  bool shouldRepaint(covariant _TasselPainter oldDelegate) => false;
}
