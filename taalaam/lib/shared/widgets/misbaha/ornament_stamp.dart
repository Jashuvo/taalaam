import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

/// The ۞ ornament stamp used for correct/wrong answer feedback and
/// lesson/SRS completion screens. Pops in with an overshoot scale + rotation.
class OrnamentStamp extends StatefulWidget {
  /// 30 for the feedback sheet, 58 for completion/SRS-done screens.
  final double size;
  final Color? color;

  const OrnamentStamp({super.key, this.size = 30, this.color});

  @override
  State<OrnamentStamp> createState() => _OrnamentStampState();
}

class _OrnamentStampState extends State<OrnamentStamp>
    with SingleTickerProviderStateMixin {
  // Mirrors the demo's `cubic-bezier(.3,1.4,.5,1)` overshoot easing.
  static const _overshoot = Cubic(0.3, 1.4, 0.5, 1.0);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.stampIn);

    final startScale = widget.size <= 30 ? 2.0 : 2.2;
    final startRotationDeg = widget.size <= 30 ? -18.0 : -20.0;

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: startScale, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: _overshoot));
    _rotation = Tween<double>(begin: startRotationDeg * (3.14159265 / 180), end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: _overshoot));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.rotate(
          angle: _rotation.value,
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
      child: Text(
        '۞',
        style: GoogleFonts.amiri(
          fontSize: widget.size,
          color: widget.color ?? AppColors.goldDeep,
          height: 1,
        ),
      ),
    );
  }
}
