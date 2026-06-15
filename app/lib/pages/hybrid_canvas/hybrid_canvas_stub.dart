import 'package:flutter/material.dart';
import '../../controllers/canvas_controller.dart';
import 'canvas_interface.dart';

HybridCanvasWidget getHybridCanvasWidget({
  required CanvasController canvasController,
  required bool isDrawing,
  required TransformationController transformationController,
  String canvasType = 'infinite',
}) {
  throw UnsupportedError(
    'Cannot create hybrid canvas without dart:html or dart:ui_web',
  );
}
