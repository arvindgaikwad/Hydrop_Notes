import 'package:flutter/material.dart';

class ExportFramePainter extends CustomPainter {
  final Rect exportRect;

  ExportFramePainter({required this.exportRect});

  @override
  void paint(Canvas canvas, Size size) {
    // Dim the background outside the exportRect
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path clearPath = Path()..addRect(exportRect);

    final Path overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      clearPath,
    );

    final Paint overlayPaint = Paint()
      ..color = Colors.black.withAlpha(100)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw the crop box outline
    final Paint outlinePaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(exportRect, outlinePaint);

    // Draw corner handles
    final Paint handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final Paint handleBorderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    void drawHandle(Offset center) {
      canvas.drawCircle(center, 6.0, handlePaint);
      canvas.drawCircle(center, 6.0, handleBorderPaint);
    }

    drawHandle(exportRect.topLeft);
    drawHandle(exportRect.topRight);
    drawHandle(exportRect.bottomLeft);
    drawHandle(exportRect.bottomRight);
  }

  @override
  bool shouldRepaint(covariant ExportFramePainter oldDelegate) {
    return oldDelegate.exportRect != exportRect;
  }
}
