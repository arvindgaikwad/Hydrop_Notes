import 'package:flutter/material.dart';
import '../controllers/canvas_controller.dart';
import '../theme/hydrop_theme.dart';

class Minimap extends StatelessWidget {
  final CanvasController canvasController;
  final TransformationController transformationController;

  const Minimap({
    super.key,
    required this.canvasController,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    return Container(
      width: 200,
      height: 150,
      decoration: ht.insetSurface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            canvasController.layersNotifier,
            transformationController,
          ]),
          builder: (context, _) {
            // Find global bounds of all strokes
            double minX = double.infinity,
                minY = double.infinity,
                maxX = -double.infinity,
                maxY = -double.infinity;

            for (var layer in canvasController.layersNotifier.value) {
              if (!layer.isVisible) continue;
              for (var stroke in layer.strokes) {
                if (stroke.points.isEmpty) continue;
                for (var p in stroke.points) {
                  if (p.point.dx < minX) minX = p.point.dx;
                  if (p.point.dx > maxX) maxX = p.point.dx;
                  if (p.point.dy < minY) minY = p.point.dy;
                  if (p.point.dy > maxY) maxY = p.point.dy;
                }
              }
            }

            if (minX == double.infinity) {
              minX = 0;
              minY = 0;
              maxX = 2000;
              maxY = 2000; // default bounds
            } else {
              // Add padding
              minX -= 500;
              minY -= 500;
              maxX += 500;
              maxY += 500;
            }

            final contentRect = Rect.fromLTRB(minX, minY, maxX, maxY);

            // Calculate viewport
            final matrix = transformationController.value;
            // The screen size isn't easily available here without LayoutBuilder.
            return LayoutBuilder(
              builder: (context, constraints) {
                // final screenSize = MediaQuery.of(context).size;
                final invertedMatrix = Matrix4.inverted(matrix);

                final viewportTopLeft = MatrixUtils.transformPoint(
                  invertedMatrix,
                  Offset.zero,
                );
                final viewportBottomRight = MatrixUtils.transformPoint(
                  invertedMatrix,
                  Offset(constraints.maxWidth, constraints.maxHeight),
                );

                final viewportRect = Rect.fromPoints(
                  viewportTopLeft,
                  viewportBottomRight,
                );

                return CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: MinimapPainter(
                    layers: canvasController.layersNotifier.value,
                    viewportRect: viewportRect,
                    contentBounds: contentRect,
                    ht: ht,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class MinimapPainter extends CustomPainter {
  final List<dynamic> layers;
  final Rect contentBounds;
  final Rect viewportRect;
  final HydropTheme ht;

  MinimapPainter({
    required this.layers,
    required this.viewportRect,
    required this.contentBounds,
    required this.ht,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Calculate scale to fit content into the minimap
    final scaleX = size.width / contentBounds.width;
    final scaleY = size.height / contentBounds.height;
    final scale = scaleX < scaleY ? scaleX : scaleY; // fit uniformly

    // 2. Center the content
    final offsetX = (size.width - contentBounds.width * scale) / 2;
    final offsetY = (size.height - contentBounds.height * scale) / 2;

    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.translate(-contentBounds.left, -contentBounds.top);

    // 3. Draw all strokes
    canvas.saveLayer(null, Paint());
    for (var layer in layers) {
      if (!layer.isVisible) continue;
      for (var stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        final paint = Paint()
          ..color = stroke.color
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              stroke.baseWidth *
              2; // Make strokes thicker in minimap to be visible

        if (stroke.isPixelEraser) {
          paint.blendMode = BlendMode.clear;
        }

        canvas.drawPath(stroke.path, paint);
      }

      // Draw placeholders for Text Nodes
      final textPaint = Paint()
        ..color = ht.iconDefault.withAlpha(100)
        ..style = PaintingStyle.fill;
      for (var node in layer.textNodes) {
        canvas.drawRect(
          Rect.fromLTWH(node.position.dx, node.position.dy, node.width, node.height),
          textPaint,
        );
      }

      // Draw placeholders for Image Nodes
      final imagePaint = Paint()
        ..color = ht.primary.withAlpha(100)
        ..style = PaintingStyle.fill;
      for (var node in layer.imageNodes) {
        canvas.drawRect(
          Rect.fromLTWH(node.position.dx, node.position.dy, node.width, node.height),
          imagePaint,
        );
      }
      
      // Draw placeholders for Document Nodes
      final docPaint = Paint()
        ..color = Colors.amber.withAlpha(100)
        ..style = PaintingStyle.fill;
      for (var node in layer.documentNodes) {
        canvas.drawRect(
          Rect.fromLTWH(node.position.dx, node.position.dy, node.width, node.height),
          docPaint,
        );
      }
    }
    canvas.restore();

    // 4. Draw viewport rectangle
    final viewportPaint = Paint()
      ..color = ht.iconDefault
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale;

    canvas.drawRect(viewportRect, viewportPaint);
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    return true; // Simplified for MVP
  }
}
