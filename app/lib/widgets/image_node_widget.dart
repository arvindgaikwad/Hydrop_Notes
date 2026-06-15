import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/canvas_objects.dart';
import '../controllers/canvas_controller.dart';
import '../theme/hydrop_theme.dart';

class ImageNodeWidget extends StatelessWidget {
  final ImageNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final void Function(Offset delta)? onResizeUpdate;
  final CanvasController canvasController;

  const ImageNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.canvasController,
    this.onPanStart,
    this.onPanUpdate,
    this.onResizeUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);

    Offset visualPosition = node.position;
    double visualScale = node.scale;
    double visualRotation = node.rotation;

    if (isSelected &&
        canvasController.isTransforming &&
        canvasController.transformCenter != null) {
      final center = canvasController.transformCenter!;
      final translate = canvasController.pendingTranslate;
      final scale = canvasController.pendingScale;
      final rotation = canvasController.pendingRotation;

      final Offset nodeCenter = Offset(
        node.position.dx + node.width / 2,
        node.position.dy + node.height / 2,
      );

      double dx = nodeCenter.dx - center.dx;
      double dy = nodeCenter.dy - center.dy;

      dx *= scale;
      dy *= scale;

      if (rotation != 0.0) {
        final double s = math.sin(rotation);
        final double c = math.cos(rotation);
        final double nx = dx * c - dy * s;
        final double ny = dx * s + dy * c;
        dx = nx;
        dy = ny;
      }

      final Offset newCenter = Offset(
        center.dx + dx + translate.dx,
        center.dy + dy + translate.dy,
      );

      visualScale = node.scale * scale;
      visualRotation = node.rotation + rotation;
      visualPosition = Offset(
        newCenter.dx - node.width / 2,
        newCenter.dy - node.height / 2,
      );
    }

    return Positioned(
      left: visualPosition.dx,
      top: visualPosition.dy,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(visualRotation)
          ..multiply(Matrix4.diagonal3Values(visualScale, visualScale, 1.0)),
        child: GestureDetector(
          onTap: onTap,
          onPanStart: (_) => onPanStart?.call(),
          onPanUpdate: onPanUpdate,
          child: SizedBox(
            width: node.width,
            height: node.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(node.filePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: ht.divider,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: ht.textDisabled,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
