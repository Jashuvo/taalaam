import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Paints a dotted gold cord through a sequence of bead centers, mirroring
/// the demo's `<path stroke-dasharray="1 7">` tasbih cord.
class MisbahaCordPainter extends CustomPainter {
  final List<Offset> nodes;
  final Color color;
  const MisbahaCordPainter({required this.nodes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.length < 2) return;
    final path = Path()..moveTo(nodes.first.dx, nodes.first.dy);
    for (var i = 0; i < nodes.length - 1; i++) {
      final a = nodes[i], b = nodes[i + 1];
      path.cubicTo(
        lerpDouble(a.dx, b.dx, .55)!, a.dy,
        lerpDouble(a.dx, b.dx, .45)!, b.dy,
        b.dx, b.dy,
      );
    }
    final paint = Paint()
      ..color = color.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 1), paint);
        d += 8;
      }
    }
  }

  @override
  bool shouldRepaint(covariant MisbahaCordPainter old) =>
      old.nodes != nodes || old.color != color;
}
