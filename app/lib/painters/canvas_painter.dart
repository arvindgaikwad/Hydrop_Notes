import 'package:flutter/material.dart';
import '../models/stroke.dart';
import '../controllers/canvas_controller.dart';

void _drawStroke(Canvas canvas, Stroke stroke) {
  if (stroke.points.isEmpty) return;

  final paint = Paint()
    ..color = stroke.color
    ..style = (!stroke.isInkPen && !stroke.isPixelEraser) ? PaintingStyle.stroke : PaintingStyle.fill
    ..strokeWidth = stroke.baseWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  if (stroke.isPixelEraser) {
    paint.blendMode = BlendMode.clear;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = stroke.baseWidth;
  } else if (stroke.isTape) {
    if (stroke.isTapeRevealed) {
      paint.color = stroke.color.withValues(alpha: 0.2);
    } else {
      paint.color = stroke.color.withValues(alpha: 0.95);
    }
  }

  canvas.drawPath(stroke.path, paint);
}

class CombinedCanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final ActiveStrokeNotifier? activeStrokeNotifier;

  CombinedCanvasPainter({
    required this.strokes,
    this.activeStrokeNotifier,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Only open an offscreen layer when eraser strokes (BlendMode.clear) are present.
    // saveLayer(null,...) allocates a full-screen GPU texture — skip it for normal strokes.
    final bool needsLayer = strokes.any((s) => s.isPixelEraser) ||
        (activeStrokeNotifier?.stroke?.isPixelEraser ?? false);
    if (needsLayer) canvas.saveLayer(null, Paint());
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (activeStrokeNotifier?.stroke != null) {
      _drawStroke(canvas, activeStrokeNotifier!.stroke!);
    }
    if (needsLayer) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CombinedCanvasPainter oldDelegate) {
    // Always repaint if there is an active stroke being drawn (since its points mutate),
    // otherwise only repaint if the strokes list instance changed.
    if (activeStrokeNotifier?.stroke != null || oldDelegate.activeStrokeNotifier?.stroke != null) return true;
    return oldDelegate.strokes != strokes;
  }
}

/// Renders strokes split into two groups:
///  - [staticStrokes]: drawn at their actual positions (not being dragged)
///  - [dragStrokes]: drawn with [dragOffset] applied (visual ghost during drag)
class SelectionDragPainter extends CustomPainter {
  final List<Stroke> staticStrokes;
  final List<Stroke> dragStrokes;
  final Offset pendingTranslate;
  final double pendingScale;
  final double pendingRotation;
  final Offset? transformCenter;
  final ActiveStrokeNotifier? activeStrokeNotifier;

  SelectionDragPainter({
    required this.staticStrokes,
    required this.dragStrokes,
    required this.pendingTranslate,
    required this.pendingScale,
    required this.pendingRotation,
    required this.transformCenter,
    this.activeStrokeNotifier,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Only open an offscreen layer when eraser strokes (BlendMode.clear) are present.
    final bool needsLayer =
        staticStrokes.any((s) => s.isPixelEraser) ||
        dragStrokes.any((s) => s.isPixelEraser) ||
        (activeStrokeNotifier?.stroke?.isPixelEraser ?? false);
    if (needsLayer) canvas.saveLayer(null, Paint());

    // Draw non-selected strokes normally
    for (final stroke in staticStrokes) {
      _drawStroke(canvas, stroke);
    }
    // Draw selected strokes with visual transform applied
    if (dragStrokes.isNotEmpty) {
      final center = transformCenter;
      if (center != null &&
          (pendingTranslate != Offset.zero ||
              pendingScale != 1.0 ||
              pendingRotation != 0.0)) {
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.translate(pendingTranslate.dx, pendingTranslate.dy);
        canvas.scale(pendingScale);
        canvas.rotate(pendingRotation);
        canvas.translate(-center.dx, -center.dy);
        for (final stroke in dragStrokes) {
          _drawStroke(canvas, stroke);
        }
        canvas.restore();
      } else {
        for (final stroke in dragStrokes) {
          _drawStroke(canvas, stroke);
        }
      }
    }

    if (activeStrokeNotifier?.stroke != null) {
      _drawStroke(canvas, activeStrokeNotifier!.stroke!);
    }

    if (needsLayer) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SelectionDragPainter oldDelegate) {
    if (activeStrokeNotifier?.stroke != null || oldDelegate.activeStrokeNotifier?.stroke != null) return true;
    return oldDelegate.pendingTranslate != pendingTranslate ||
        oldDelegate.pendingScale != pendingScale ||
        oldDelegate.pendingRotation != pendingRotation ||
        oldDelegate.transformCenter != transformCenter ||
        oldDelegate.staticStrokes != staticStrokes ||
        oldDelegate.dragStrokes != dragStrokes;
  }
}
