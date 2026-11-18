import 'package:flutter/material.dart';

/// Subtle architectural grid backdrop used in site photo and CAD viewers.
class BlueprintGridPainter extends CustomPainter {
  final Color gridColor;
  final double step;

  const BlueprintGridPainter({
    required this.gridColor,
    this.step = 18.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor || oldDelegate.step != step;
}
