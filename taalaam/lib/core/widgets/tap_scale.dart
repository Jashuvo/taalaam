import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Wraps [child] with a subtle press-down scale (0.97) for tactile feedback.
/// Use on track cards, lesson cards, and primary CTAs only.
///
/// Uses a [Listener] (not [GestureDetector]) so it stays purely visual and
/// never competes with an inner [InkWell]/button for the tap gesture.
class TapScale extends StatefulWidget {
  final Widget child;

  const TapScale({required this.child, super.key});

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: !reduceMotion && _pressed ? 0.97 : 1.0,
        duration: AppMotion.tap,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
