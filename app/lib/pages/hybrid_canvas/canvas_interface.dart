import 'package:flutter/material.dart';
import '../../controllers/canvas_controller.dart';

import 'hybrid_canvas_stub.dart'
    if (dart.library.io) 'canvas_native.dart'
    if (dart.library.html) 'canvas_web.dart';

abstract class HybridCanvasWidget extends StatefulWidget {
  final CanvasController canvasController;
  final bool isDrawing;
  final TransformationController transformationController;
  final String canvasType;

  const HybridCanvasWidget({
    super.key,
    required this.canvasController,
    required this.isDrawing,
    required this.transformationController,
    this.canvasType = 'infinite',
  });

  factory HybridCanvasWidget.create({
    required CanvasController canvasController,
    required bool isDrawing,
    required TransformationController transformationController,
    String canvasType = 'infinite',
  }) {
    return getHybridCanvasWidget(
      canvasController: canvasController,
      isDrawing: isDrawing,
      transformationController: transformationController,
      canvasType: canvasType,
    );
  }
}
