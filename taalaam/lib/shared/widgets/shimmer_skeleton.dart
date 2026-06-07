import 'package:flutter/material.dart';

/// Animated shimmer wrapper. Wrap any shape widget to give it a sweep effect.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.surfaceContainerHighest;
    final highlight = cs.onSurface.withValues(alpha: 0.05);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              (_ctrl.value - 0.3).clamp(0.0, 1.0),
              _ctrl.value.clamp(0.0, 1.0),
              (_ctrl.value + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for the track detail loading state — 3 nodes + 3 label bars.
class TrackDetailSkeleton extends StatelessWidget {
  const TrackDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          _row(left: 0.20),
          const SizedBox(height: 28),
          _row(left: 0.60),
          const SizedBox(height: 28),
          _row(left: 0.20),
        ],
      ),
    );
  }

  Widget _row({required double left}) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final x = constraints.maxWidth * left;
      return SizedBox(
        height: 80,
        child: Stack(
          children: [
            Positioned(
              left: x,
              top: 0,
              child: const ShimmerBox(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
            Positioned(
              left: x + 4,
              top: 52,
              child: const ShimmerBox(width: 60, height: 10),
            ),
          ],
        ),
      );
    });
  }
}

/// Skeleton for the review screen loading state — 2 card rects.
class ReviewSkeleton extends StatelessWidget {
  const ReviewSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ShimmerBox(
            width: 200,
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          const SizedBox(height: 20),
          const ShimmerBox(
            width: 200,
            height: 120,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      ),
    );
  }
}
