import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class XpToast {
  XpToast._();

  static void show(BuildContext context, int xp) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _XpToastWidget(
        xp: xp,
        onDone: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _XpToastWidget extends StatefulWidget {
  final int xp;
  final VoidCallback onDone;
  const _XpToastWidget({required this.xp, required this.onDone});

  @override
  State<_XpToastWidget> createState() => _XpToastWidgetState();
}

class _XpToastWidgetState extends State<_XpToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide;  // 0 → -40px (upward)
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    // Slide up 40px over 400ms
    _slide = Tween<double>(begin: 0, end: -40).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.31, curve: Curves.easeOut),
      ),
    );

    // Fade in 0→1 over first 200ms, hold, fade out over last 300ms
    _fade = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 30),
    ]).animate(_ctrl);

    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topBase = mq.size.height * 0.30;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Positioned(
        top: topBase + _slide.value,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: _fade.value,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Text(
                  '+${widget.xp} XP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
