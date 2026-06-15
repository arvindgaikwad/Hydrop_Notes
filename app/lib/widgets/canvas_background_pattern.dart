import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum CanvasBackgroundVariant {
  none,
  dots,
  diagonalStripes,
  grid,
  horizontalLines,
  verticalLines,
  checkerboard,
}

enum CanvasBackgroundMask {
  fadeCenter,
  fadeEdges,
  fadeTop,
  fadeBottom,
  fadeLeft,
  fadeRight,
  fadeX,
  fadeY,
  none,
}

class CanvasBackgroundPattern extends StatelessWidget {
  final CanvasBackgroundVariant variant;
  final CanvasBackgroundMask mask;
  final double size;
  final Color fill;
  final TransformationController transformationController;
  final bool isLimitedBounds;

  const CanvasBackgroundPattern({
    super.key,
    required this.transformationController,
    this.variant = CanvasBackgroundVariant.grid,
    this.mask = CanvasBackgroundMask.none,
    this.size = 40.0,
    this.fill = const Color(0xFF252525),
    this.isLimitedBounds = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget pattern = CustomPaint(
      size: Size.infinite,
      painter: CanvasBackgroundPainter(
        variant: variant,
        size: size,
        fill: fill,
        transform: transformationController,
        isLimitedBounds: isLimitedBounds,
      ),
    );

    if (mask != CanvasBackgroundMask.none) {
      pattern = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (Rect bounds) {
          return _getMaskGradient(mask).createShader(bounds);
        },
        child: pattern,
      );
    }

    return pattern;
  }

  Gradient _getMaskGradient(CanvasBackgroundMask maskType) {
    const transparent = Colors.transparent;
    const opaque = Colors.white;

    switch (maskType) {
      case CanvasBackgroundMask.fadeEdges:
        return const RadialGradient(
          center: Alignment.center,
          colors: [opaque, transparent],
        );
      case CanvasBackgroundMask.fadeCenter:
        return const RadialGradient(
          center: Alignment.center,
          colors: [transparent, opaque],
        );
      case CanvasBackgroundMask.fadeTop:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [transparent, opaque],
        );
      case CanvasBackgroundMask.fadeBottom:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [opaque, transparent],
        );
      case CanvasBackgroundMask.fadeLeft:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [transparent, opaque],
        );
      case CanvasBackgroundMask.fadeRight:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [opaque, transparent],
        );
      case CanvasBackgroundMask.fadeX:
        return const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [transparent, opaque, transparent],
        );
      case CanvasBackgroundMask.fadeY:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [transparent, opaque, transparent],
        );
      case CanvasBackgroundMask.none:
        return const LinearGradient(colors: [opaque, opaque]);
    }
  }
}

class CanvasBackgroundPainter extends CustomPainter {
  final CanvasBackgroundVariant variant;
  final double size;
  final Color fill;
  final TransformationController transform;
  final bool isLimitedBounds;

  CanvasBackgroundPainter({
    required this.variant,
    required this.size,
    required this.fill,
    required this.transform,
    required this.isLimitedBounds,
  }) : super(repaint: transform);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final matrix = transform.value;
    canvas.save();
    canvas.transform(matrix.storage);

    // Calculate the visible rectangle in scene coordinates
    final Matrix4 inverse = Matrix4.tryInvert(matrix) ?? Matrix4.identity();
    final Rect visibleRect = MatrixUtils.transformRect(inverse, Offset.zero & canvasSize);

    // Expand the visible rect slightly to avoid edge pop-in
    final double startX = ((visibleRect.left - size) / size).floor() * size;
    final double endX = ((visibleRect.right + size) / size).ceil() * size;
    final double startY = ((visibleRect.top - size) / size).floor() * size;
    final double endY = ((visibleRect.bottom + size) / size).ceil() * size;

    if (isLimitedBounds) {
      canvas.clipRect(Rect.fromLTRB(0, 0, 1000000, 1000000));
    }

    final paint = Paint()
      ..color = fill
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.fill;

    switch (variant) {
      case CanvasBackgroundVariant.dots:
        List<Offset> points = [];
        for (double x = startX; x <= endX; x += size) {
          for (double y = startY; y <= endY; y += size) {
            points.add(Offset(x, y));
          }
        }
        canvas.drawPoints(ui.PointMode.points, points, fillPaint..strokeWidth = 2.0);
        break;

      case CanvasBackgroundVariant.grid:
        for (double x = startX; x <= endX; x += size) {
          canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
        }
        for (double y = startY; y <= endY; y += size) {
          canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
        }
        break;

      case CanvasBackgroundVariant.horizontalLines:
        for (double y = startY; y <= endY; y += size) {
          canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
        }
        break;

      case CanvasBackgroundVariant.verticalLines:
        for (double x = startX; x <= endX; x += size) {
          canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
        }
        break;

      case CanvasBackgroundVariant.diagonalStripes:
        final double diagSize = math.max(endX - startX, endY - startY) * 2;
        final double offsetX = startX;
        final double offsetY = startY;
        
        // Draw 45 degree lines covering the bounding box
        for (double d = -diagSize; d <= diagSize; d += size * 2) {
          canvas.drawLine(
            Offset(offsetX + d, offsetY),
            Offset(offsetX + d + diagSize, offsetY + diagSize),
            paint..strokeWidth = size,
          );
        }
        break;

      case CanvasBackgroundVariant.checkerboard:
        for (double x = startX; x <= endX; x += size) {
          for (double y = startY; y <= endY; y += size) {
            bool isEvenRow = (y / size).floor() % 2 == 0;
            bool isEvenCol = (x / size).floor() % 2 == 0;
            if (isEvenRow == isEvenCol) {
              canvas.drawRect(Rect.fromLTWH(x, y, size, size), fillPaint);
            }
          }
        }
        break;

      case CanvasBackgroundVariant.none:
        // Do nothing
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasBackgroundPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.size != size ||
        oldDelegate.fill != fill ||
        oldDelegate.isLimitedBounds != isLimitedBounds ||
        oldDelegate.transform != transform;
  }
}
