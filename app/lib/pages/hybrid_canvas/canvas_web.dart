// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../controllers/canvas_controller.dart';
import 'canvas_interface.dart';
import '../../models/canvas_objects.dart';
import '../../widgets/text_node_widget.dart';
import '../../widgets/image_node_widget.dart';
import '../../painters/connector_painter.dart';
import '../../painters/export_frame_painter.dart';
import '../../widgets/bounding_box_overlay.dart';
import '../../theme/hydrop_theme.dart';

HybridCanvasWidget getHybridCanvasWidget({
  required CanvasController canvasController,
  required bool isDrawing,
  required TransformationController transformationController,
  String canvasType = 'infinite',
}) {
  return _WebCanvasWidget(
    canvasController: canvasController,
    isDrawing: isDrawing,
    transformationController: transformationController,
    canvasType: canvasType,
  );
}

class _WebCanvasWidget extends HybridCanvasWidget {
  const _WebCanvasWidget({
    required super.canvasController,
    required super.isDrawing,
    required super.transformationController,
    super.canvasType = 'infinite',
  });

  @override
  State<_WebCanvasWidget> createState() => _WebCanvasWidgetState();
}

class _WebCanvasWidgetState extends State<_WebCanvasWidget> {
  late String _viewId;
  html.CanvasElement? _canvas;
  html.CanvasRenderingContext2D? _ctx;

  Offset? _lastLocalPoint;

  // Export Frame State
  // ignore: unused_field
  bool _isDraggingExportFrame = false;
  // ignore: unused_field
  bool _isResizingExportFrame = false;
  // ignore: unused_field
  int _resizeHandleIndex = -1; // 0: TL, 1: TR, 2: BL, 3: BR
  // ignore: unused_field
  Offset? _exportFrameDragStart;
  // ignore: unused_field
  Rect? _exportFrameStartRect;

  @override
  void initState() {
    super.initState();
    _viewId = 'html-canvas-view-${DateTime.now().millisecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      _canvas = html.CanvasElement()
        ..style.width = '100%'
        ..style.height = '100%';

      _ctx = _canvas!.context2D;

      final ratio = html.window.devicePixelRatio;
      html.window.onResize.listen((_) {
        _resizeCanvas(ratio);
      });

      Future.delayed(Duration.zero, () => _resizeCanvas(ratio));
      return _canvas!;
    });

    widget.canvasController.layersNotifier.addListener(_redrawAll);
    widget.transformationController.addListener(_redrawAll);
  }

  @override
  void dispose() {
    widget.canvasController.layersNotifier.removeListener(_redrawAll);
    widget.transformationController.removeListener(_redrawAll);
    super.dispose();
  }

  void _resizeCanvas(num ratio) {
    if (_canvas == null) return;
    final rect = _canvas!.getBoundingClientRect();
    _canvas!.width = (rect.width * ratio).toInt();
    _canvas!.height = (rect.height * ratio).toInt();
    _redrawAll();
  }

  void _redrawAll() {
    if (_canvas == null || _ctx == null) return;
    final ratio = html.window.devicePixelRatio;

    _ctx!.clearRect(0, 0, _canvas!.width!, _canvas!.height!);

    _ctx!.save();
    _ctx!.scale(ratio, ratio);

    final matrix = widget.transformationController.value;
    _ctx!.transform(
      matrix[0],
      matrix[1],
      matrix[4],
      matrix[5],
      matrix[12],
      matrix[13],
    );

    // Grid MVP
    _ctx!.fillStyle = 'rgba(0,0,0,0.05)';
    for (double i = 0; i < 4000; i += 50) {
      for (double j = 0; j < 4000; j += 50) {
        _ctx!.beginPath();
        _ctx!.arc(i, j, 1.5, 0, 3.14159 * 2);
        _ctx!.fill();
      }
    }

    _ctx!.lineCap = 'round';
    _ctx!.lineJoin = 'round';

    for (final layer in widget.canvasController.layersNotifier.value) {
      if (!layer.isVisible) continue;
      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;

        final colorHex = stroke.color
            .toARGB32()
            .toRadixString(16)
            .padLeft(8, '0');
        final r = int.parse(colorHex.substring(2, 4), radix: 16);
        final g = int.parse(colorHex.substring(4, 6), radix: 16);
        final b = int.parse(colorHex.substring(6, 8), radix: 16);
        final a = int.parse(colorHex.substring(0, 2), radix: 16) / 255.0;

        if (stroke.isPixelEraser) {
          _ctx!.globalCompositeOperation = 'destination-out';
          _ctx!.strokeStyle = 'rgba(0,0,0,1)';
        } else {
          _ctx!.globalCompositeOperation = 'source-over';
          if (stroke.isTape) {
            final alphaTape = stroke.isTapeRevealed ? 0.2 : 0.95;
            _ctx!.strokeStyle = 'rgba($r,$g,$b,$alphaTape)';
          } else {
            _ctx!.strokeStyle = 'rgba($r,$g,$b,$a)';
          }
        }
        if (stroke.isInkPen && stroke.points.length > 1) {
          final polygon = stroke.outlinePolygon;
          if (polygon.isNotEmpty) {
            _ctx!.beginPath();
            _ctx!.moveTo(polygon.first.dx, polygon.first.dy);
            for (int i = 1; i < polygon.length; i++) {
              _ctx!.lineTo(polygon[i].dx, polygon[i].dy);
            }
            _ctx!.closePath();
            
            if (stroke.isPixelEraser) {
               _ctx!.fillStyle = 'rgba(0,0,0,1)';
            } else if (stroke.isTape) {
               final alphaTape = stroke.isTapeRevealed ? 0.2 : 0.95;
               _ctx!.fillStyle = 'rgba($r,$g,$b,$alphaTape)';
            } else {
               _ctx!.fillStyle = 'rgba($r,$g,$b,$a)';
            }
            _ctx!.fill();
          }
        } else {
          _ctx!.lineWidth = stroke.baseWidth;
  
          _ctx!.beginPath();
          final first = stroke.points.first.point;
          _ctx!.moveTo(first.dx, first.dy);
  
          if (stroke.points.length == 1) {
            _ctx!.lineTo(first.dx, first.dy);
          } else {
            for (int i = 1; i < stroke.points.length; i++) {
              final p = stroke.points[i].point;
              _ctx!.lineTo(p.dx, p.dy);
            }
          }
          _ctx!.stroke();
        }
      }
    }

    _ctx!.restore();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isDrawing) return;

    final controller = widget.canvasController;
    if (controller.currentTool == DrawingTool.text || controller.currentTool == DrawingTool.document) return;

    final localOffset = event.localPosition;
    final scenePoint = widget.transformationController.toScene(localOffset);

    if (controller.currentTool == DrawingTool.exportFrame) {
      final rect = controller.exportFrameNotifier.value;
      if (rect != null) {
        // Hit test handles (radius 20)
        final handles = [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight];
        for (int i = 0; i < handles.length; i++) {
          if ((scenePoint - handles[i]).distance < 20) {
            _isResizingExportFrame = true;
            _resizeHandleIndex = i;
            _exportFrameDragStart = scenePoint;
            _exportFrameStartRect = rect;
            return;
          }
        }
        // Hit test inside rect
        if (rect.contains(scenePoint)) {
          _isDraggingExportFrame = true;
          _exportFrameDragStart = scenePoint;
          _exportFrameStartRect = rect;
          return;
        }
      }
      return; // Ignore other touches while in export mode
    }

    if (controller.currentTool == DrawingTool.image) {
      // Allow controller to pick image and place
      // (This should be called from onTapDown, similar to native)
      return;
    }

    if (controller.currentTool == DrawingTool.select ||
        controller.currentTool == DrawingTool.lasso) {
      final selection = controller.selectionNotifier.value;
      if (selection.boundingBox != null) {
        final box = selection.boundingBox!;
        final double rotation = selection.rotation;

        Offset testOffset = scenePoint;
        if (rotation != 0.0) {
          final center = box.center;
          final dx = scenePoint.dx - center.dx;
          final dy = scenePoint.dy - center.dy;
          final cosA = math.cos(-rotation);
          final sinA = math.sin(-rotation);
          testOffset = Offset(
            center.dx + dx * cosA - dy * sinA,
            center.dy + dx * sinA + dy * cosA,
          );
        }

        final boxRect = Rect.fromLTWH(
          box.left - 20,
          box.top - 45,
          box.width + 40,
          box.height + 65,
        );
        final menuRect = Rect.fromLTWH(
          box.left - 10,
          box.top - 80,
          110,
          50,
        );
        if (boxRect.contains(testOffset) || menuRect.contains(testOffset)) return;
      }
      if (controller.currentTool == DrawingTool.select) {
        for (var layer in controller.layersNotifier.value) {
          if (!layer.isVisible || layer.isLocked) continue;
          for (var image in layer.imageNodes) {
            if (controller.getNodeBounds(image).contains(scenePoint)) return;
          }
          for (var text in layer.textNodes) {
            if (controller.getNodeBounds(text).contains(scenePoint)) return;
          }
          for (var doc in layer.documentNodes) {
            if (controller.getNodeBounds(doc).contains(scenePoint)) return;
          }
        }
      }
    }

    widget.canvasController.startStroke(scenePoint, event.pressure);

    _lastLocalPoint = localOffset;

    if (_ctx != null) {
      final ratio = html.window.devicePixelRatio;
      _ctx!.save();
      _ctx!.scale(ratio, ratio);
      _ctx!.lineCap = 'round';
      _ctx!.lineJoin = 'round';

      final colorHex = widget.canvasController.currentColor
          .toARGB32()
          .toRadixString(16)
          .padLeft(8, '0');
      final r = int.parse(colorHex.substring(2, 4), radix: 16);
      final g = int.parse(colorHex.substring(4, 6), radix: 16);
      final b = int.parse(colorHex.substring(6, 8), radix: 16);
      final a = int.parse(colorHex.substring(0, 2), radix: 16) / 255.0;

      if (widget.canvasController.currentTool == DrawingTool.pixelEraser) {
        _ctx!.globalCompositeOperation = 'destination-out';
        _ctx!.strokeStyle = 'rgba(0,0,0,1)';
        _ctx!.lineWidth = widget.canvasController.currentWidth * 3.0;
      } else {
        _ctx!.globalCompositeOperation = 'source-over';
        _ctx!.strokeStyle = 'rgba($r,$g,$b,$a)';
        _ctx!.lineWidth = widget.canvasController.currentWidth;
      }

      _ctx!.beginPath();
      _ctx!.moveTo(localOffset.dx, localOffset.dy);
      _ctx!.lineTo(localOffset.dx, localOffset.dy);
      _ctx!.stroke();
      _ctx!.restore();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.isDrawing || _lastLocalPoint == null) return;

    final controller = widget.canvasController;
    if (controller.currentTool == DrawingTool.text ||
        controller.currentTool == DrawingTool.document ||
        controller.currentTool == DrawingTool.image) {
      return;
    }

    final localOffset = event.localPosition;
    final scenePoint = widget.transformationController.toScene(localOffset);
    widget.canvasController.updateStroke(scenePoint, event.pressure);

    if (_ctx != null) {
      final ratio = html.window.devicePixelRatio;
      _ctx!.save();
      _ctx!.scale(ratio, ratio);
      _ctx!.lineCap = 'round';
      _ctx!.lineJoin = 'round';

      final colorHex = widget.canvasController.currentColor
          .toARGB32()
          .toRadixString(16)
          .padLeft(8, '0');
      final r = int.parse(colorHex.substring(2, 4), radix: 16);
      final g = int.parse(colorHex.substring(4, 6), radix: 16);
      final b = int.parse(colorHex.substring(6, 8), radix: 16);
      final a = int.parse(colorHex.substring(0, 2), radix: 16) / 255.0;

      if (widget.canvasController.currentTool == DrawingTool.pixelEraser) {
        _ctx!.globalCompositeOperation = 'destination-out';
        _ctx!.strokeStyle = 'rgba(0,0,0,1)';
        _ctx!.lineWidth = widget.canvasController.currentWidth * 3.0;
      } else {
        _ctx!.globalCompositeOperation = 'source-over';
        _ctx!.strokeStyle = 'rgba($r,$g,$b,$a)';
        _ctx!.lineWidth = widget.canvasController.currentWidth;
      }

      _ctx!.beginPath();
      _ctx!.moveTo(_lastLocalPoint!.dx, _lastLocalPoint!.dy);
      _ctx!.lineTo(localOffset.dx, localOffset.dy);
      _ctx!.stroke();
      _ctx!.restore();
    }

    _lastLocalPoint = localOffset;
  }

  void _onPointerUp(PointerEvent event) {
    if (!widget.isDrawing) return;

    final controller = widget.canvasController;
    if (controller.currentTool == DrawingTool.text ||
        controller.currentTool == DrawingTool.document ||
        controller.currentTool == DrawingTool.image) {
      return;
    }

    _lastLocalPoint = null;
    widget.canvasController.endStroke();
  }

  void _handleNodePanStart(dynamic node) {
    widget.canvasController.saveSnapshot();
    final selection = widget.canvasController.selectionNotifier.value;
    if (node is ImageNode && !selection.imageNodes.contains(node)) {
      widget.canvasController.selectNode(node);
    } else if (node is TextNode && !selection.textNodes.contains(node)) {
      widget.canvasController.selectNode(node);
    } else if (node is DocumentNode && !selection.documentNodes.contains(node)) {
      widget.canvasController.selectNode(node);
    }
  }

  void _handleNodePanUpdate(
    DragUpdateDetails details,
    dynamic node,
    CanvasLayer layer,
  ) {
    final double scale = widget.transformationController.value
        .getMaxScaleOnAxis();
    final Offset sceneDelta = details.delta / scale;
    widget.canvasController.moveNode(node, sceneDelta);
  }

  @override
  Widget build(BuildContext context) {
    final activeTool = widget.canvasController.currentTool;
    return Stack(
      children: [
        // Background HTML5 Canvas
        HtmlElementView(viewType: _viewId),

        // Foreground Flutter Event Catcher & Panner
        Positioned.fill(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: InteractiveViewer(
              transformationController: widget.transformationController,
              constrained: false,
              minScale: 0.1,
              maxScale: 10.0,
              panEnabled: !widget.isDrawing,
              scaleEnabled: !widget.isDrawing,
              boundaryMargin: const EdgeInsets.all(1e9),
              child: SizedBox(
                width: 100000,
                height: 100000,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final scenePosition = widget.transformationController.toScene(details.localPosition);
                          bool hitTape = widget.canvasController.toggleTapeAtPoint(scenePosition);
                          if (hitTape) return;

                          if (widget.canvasController.currentTool ==
                              DrawingTool.text) {
                            widget.canvasController.saveSnapshot();
                            final newNode = TextNode(
                              id: 'text-${DateTime.now().millisecondsSinceEpoch}',
                              text: '',
                              position: details.localPosition,
                              color: widget.canvasController.currentColor,
                            );
                            final layer = widget.canvasController.activeLayer;
                            layer.textNodes = [...layer.textNodes, newNode];
                            widget.canvasController.layersNotifier.value =
                                List.from(
                                  widget.canvasController.layersNotifier.value,
                                );
                          } else if (widget.canvasController.currentTool ==
                              DrawingTool.document) {
                            widget.canvasController.saveSnapshot();
                            final newNode = DocumentNode(
                              id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                              text: '',
                              position: details.localPosition,
                            );
                            final layer = widget.canvasController.activeLayer;
                            layer.documentNodes = [...layer.documentNodes, newNode];
                            widget.canvasController.layersNotifier.value =
                                List.from(
                                  widget.canvasController.layersNotifier.value,
                                );
                          } else if (widget.canvasController.currentTool ==
                                  DrawingTool.select ||
                              widget.canvasController.currentTool ==
                                  DrawingTool.lasso) {
                            final selection = widget.canvasController.selectionNotifier.value;
                            if (selection.boundingBox != null) {
                              final box = selection.boundingBox!;
                              final double rotation = selection.rotation;

                              Offset testOffset = scenePosition;
                              if (rotation != 0.0) {
                                final center = box.center;
                                final dx = scenePosition.dx - center.dx;
                                final dy = scenePosition.dy - center.dy;
                                final cosA = math.cos(-rotation);
                                final sinA = math.sin(-rotation);
                                testOffset = Offset(
                                  center.dx + dx * cosA - dy * sinA,
                                  center.dy + dx * sinA + dy * cosA,
                                );
                              }

                              final boxRect = Rect.fromLTWH(
                                box.left - 20,
                                box.top - 45,
                                box.width + 40,
                                box.height + 65,
                              );
                              final menuRect = Rect.fromLTWH(
                                box.left - 10,
                                box.top - 80,
                                110,
                                50,
                              );
                              if (boxRect.contains(testOffset) || menuRect.contains(testOffset)) return;
                            }
                            widget.canvasController.selectionNotifier.value =
                                CanvasSelection();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Layer Rendering Engine for Flutter Widgets (Text, Image)
                    ClipPath(
                      clipper: widget.canvasType == 'a4' ? A4Clipper() : null,
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          widget.canvasController.layersNotifier,
                          widget.canvasController.selectionNotifier,
                          widget.canvasController.activeStrokeNotifier,
                        ]),
                        builder: (context, _) {
                          final layers =
                              widget.canvasController.layersNotifier.value;
                          final selection =
                              widget.canvasController.selectionNotifier.value;

                          final layerWidgets = <Widget>[];

                          for (int i = 0; i < layers.length; i++) {
                            final layer = layers[i];
                            if (!layer.isVisible) continue;

                            // 1. Images
                            if (layer.imageNodes.isNotEmpty) {
                              layerWidgets.addAll(
                                layer.imageNodes
                                    .map(
                                      (img) => ImageNodeWidget(
                                        key: ValueKey(img.id),
                                        node: img,
                                        isSelected: selection.imageNodes
                                            .contains(img),
                                        canvasController: widget.canvasController,
                                        onTap: () {
                                          if (activeTool ==
                                                  DrawingTool.select ||
                                              activeTool == DrawingTool.lasso) {
                                            widget.canvasController.selectNode(
                                              img,
                                            );
                                          }
                                        },
                                        onPanStart:
                                            (activeTool == DrawingTool.select)
                                            ? () => _handleNodePanStart(img)
                                            : null,
                                        onPanUpdate:
                                            (activeTool == DrawingTool.select)
                                            ? (details) => _handleNodePanUpdate(
                                                details,
                                                img,
                                                layer,
                                              )
                                            : null,
                                        onResizeUpdate: (delta) {
                                          widget.canvasController
                                              .saveSnapshot();
                                          final scale = widget
                                              .transformationController
                                              .value
                                              .getMaxScaleOnAxis();
                                          final adjustedDelta = delta / scale;

                                          final newList = List<ImageNode>.from(
                                            layer.imageNodes,
                                          );
                                          final index = newList.indexOf(img);
                                          if (index != -1) {
                                            newList[index] = ImageNode(
                                              id: img.id,
                                              filePath: img.filePath,
                                              position: img.position,
                                              width:
                                                  (img.width + adjustedDelta.dx)
                                                      .clamp(50.0, 2000.0),
                                              height:
                                                  (img.height +
                                                          adjustedDelta.dy)
                                                      .clamp(50.0, 2000.0),
                                            );
                                            layer.imageNodes = newList;
                                            widget
                                                .canvasController
                                                .layersNotifier
                                                .value = List.from(
                                              layers,
                                            );
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              );
                            }

                            // Note: Strokes are drawn by the HTML5 canvas below,
                            // so we don't draw CustomPaint here!

                            // 1.5 Connectors
                            final isLayerActive = i == widget.canvasController.activeLayerIndexNotifier.value;
                            if (layer.connectorNodes.isNotEmpty || 
                                (isLayerActive && activeTool == DrawingTool.connector && (widget.canvasController.activeConnectorStartNodeId != null || widget.canvasController.activeConnectorStartPoint != null))) {
                              layerWidgets.add(
                                CustomPaint(
                                  size: const Size(100000, 100000),
                                  painter: ConnectorPainter(
                                    connectors: layer.connectorNodes,
                                    controller: widget.canvasController,
                                    isActiveLayer: isLayerActive,
                                  ),
                                ),
                              );
                            }

                            // 2. Texts
                            if (layer.textNodes.isNotEmpty) {
                              layerWidgets.addAll(
                                layer.textNodes
                                    .map(
                                      (t) => TextNodeWidget(
                                        key: ValueKey(t.id),
                                        node: t,
                                        isSelected: selection.textNodes
                                            .contains(t),
                                        canvasController: widget.canvasController,
                                        forceEditOnTap:
                                            activeTool == DrawingTool.text,
                                        autofocus: t.text.isEmpty,
                                        onTap: () {
                                          if (activeTool ==
                                                  DrawingTool.select ||
                                              activeTool == DrawingTool.lasso) {
                                            widget.canvasController.selectNode(
                                              t,
                                            );
                                          }
                                        },
                                        onPanStart:
                                            (activeTool == DrawingTool.select)
                                            ? () => _handleNodePanStart(t)
                                            : null,
                                        onPanUpdate:
                                            (activeTool == DrawingTool.select)
                                            ? (details) => _handleNodePanUpdate(
                                                details,
                                                t,
                                                layer,
                                              )
                                            : null,
                                        onTextChanged: (newText) {
                                          widget.canvasController
                                              .saveSnapshot();
                                          t.text = newText;
                                        },
                                        onStyleChanged: () {
                                          widget.canvasController
                                              .saveSnapshot();
                                          widget
                                              .canvasController
                                              .layersNotifier
                                              .value = List.from(
                                            widget
                                                .canvasController
                                                .layersNotifier
                                                .value,
                                          );
                                        },
                                        onDelete: () {
                                          widget.canvasController
                                              .saveSnapshot();
                                          final list = List<TextNode>.from(
                                            layer.textNodes,
                                          );
                                          list.remove(t);
                                          layer.textNodes = list;
                                          widget
                                              .canvasController
                                              .layersNotifier
                                              .value = List.from(
                                            layers,
                                          );
                                        },
                                      ),
                                    )
                                    .toList(),
                              );
                            }
                          }

                          return Stack(children: layerWidgets);
                        },
                      ),
                    ),

                    // Selection Bounding Box Overlay
                    ValueListenableBuilder<CanvasSelection>(
                      valueListenable:
                          widget.canvasController.selectionNotifier,
                      builder: (context, selection, _) {
                        if (selection.isEmpty || selection.boundingBox == null) {
                          return const SizedBox.shrink();
                        }

                        final isSingleNode =
                            selection.strokes.isEmpty &&
                            (selection.textNodes.length +
                                    selection.imageNodes.length ==
                                1);
                        final singleNode = isSingleNode
                            ? (selection.textNodes.isNotEmpty
                                  ? selection.textNodes.first
                                  : selection.imageNodes.first)
                            : null;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            BoundingBoxOverlay(
                              canvasController: widget.canvasController,
                              initialRect: selection.boundingBox!,
                              initialRotation: isSingleNode
                                  ? singleNode!.rotation
                                  : 0.0,
                              initialScale: 1.0,
                              onTransformUpdate:
                                  (translate, scaleMultiplier, rotationDelta) {
                                    widget.canvasController.transformSelection(
                                      translate,
                                      scaleMultiplier,
                                      rotationDelta,
                                    );
                                  },
                              onTransformEnd: () {
                                widget.canvasController.saveSnapshot();
                              },
                            ),
                            Positioned(
                              left: selection.boundingBox!.left,
                              top: selection.boundingBox!.top - 64,
                              child: HydropTheme.of(context).applyBackdrop(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  decoration: HydropTheme.of(context).toolbarDecoration,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _MenuButton(
                                        icon: Icons.copy_rounded,
                                        tooltip: 'Duplicate',
                                        onPressed: () => widget.canvasController
                                            .duplicateSelection(),
                                      ),
                                      const SizedBox(width: 4),
                                      _MenuButton(
                                        icon: Icons.delete_rounded,
                                        color: Colors.redAccent,
                                        tooltip: 'Delete',
                                        onPressed: () => widget.canvasController
                                            .deleteSelection(),
                                      ),
                                    ],
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                      // Export Frame Overlay
                      ValueListenableBuilder<Rect?>(
                        valueListenable: widget.canvasController.exportFrameNotifier,
                        builder: (context, frameRect, _) {
                          if (widget.canvasController.currentTool != DrawingTool.exportFrame || frameRect == null) {
                            return const SizedBox.shrink();
                          }
                          return Positioned.fill(
                            child: CustomPaint(
                              painter: ExportFramePainter(exportRect: frameRect),
                            ),
                          );
                        },
                      ),

                      // Marquee Selection Overlay
                    ListenableBuilder(
                      listenable: widget.canvasController.activeStrokeNotifier,
                      builder: (context, _) {
                        final activeStroke =
                            widget.canvasController.activeStrokeNotifier.stroke;
                        if (activeTool == DrawingTool.select &&
                            activeStroke != null &&
                            activeStroke.points.isNotEmpty) {
                          final points = activeStroke.points;
                          double minX = double.infinity,
                              minY = double.infinity,
                              maxX = -double.infinity,
                              maxY = -double.infinity;
                          for (var p in points) {
                            if (p.point.dx < minX) minX = p.point.dx;
                            if (p.point.dx > maxX) maxX = p.point.dx;
                            if (p.point.dy < minY) minY = p.point.dy;
                            if (p.point.dy > maxY) maxY = p.point.dy;
                          }
                          if (minX == double.infinity) {
                            return const SizedBox.shrink();
                          }
                          final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
                          return Positioned.fromRect(
                            rect: rect,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: HydropTheme.of(context).primary,
                                    width: 1,
                                    style: BorderStyle.solid,
                                  ),
                                  color: HydropTheme.of(
                                    context,
                                  ).primary.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class A4Clipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1240,
      height: 1754,
    );
    path.addRect(rect);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MenuButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _MenuButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    final baseColor = widget.color ?? ht.iconDefault;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (widget.color != null
                      ? widget.color!.withValues(alpha: 0.15)
                      : ht.primary.withValues(alpha: 0.15))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _isHovered
                  ? (widget.color ?? ht.primary)
                  : baseColor,
            ),
          ),
        ),
      ),
    );
  }
}
