import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../controllers/canvas_controller.dart';
import '../../painters/canvas_painter.dart';
import 'canvas_interface.dart';
import '../../models/canvas_objects.dart';
import '../../widgets/text_node_widget.dart';
import '../../widgets/image_node_widget.dart';
import '../../widgets/document_node_widget.dart';
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
  return _NativeCanvasWidget(
    canvasController: canvasController,
    isDrawing: isDrawing,
    transformationController: transformationController,
    canvasType: canvasType,
  );
}

class _NativeCanvasWidget extends HybridCanvasWidget {
  const _NativeCanvasWidget({
    required super.canvasController,
    required super.isDrawing,
    required super.transformationController,
    super.canvasType = 'infinite',
  });

  @override
  State<_NativeCanvasWidget> createState() => _NativeCanvasWidgetState();
}

class _NativeCanvasWidgetState extends State<_NativeCanvasWidget> {
  Offset? _middleMouseStart;
  final Set<int> _activePointerIds = {};

  // Export Frame State
  bool _isDraggingExportFrame = false;
  bool _isResizingExportFrame = false;
  int _resizeHandleIndex = -1; // 0: TL, 1: TR, 2: BL, 3: BR
  Offset? _exportFrameDragStart;
  Rect? _exportFrameStartRect;

  void _onPointerDown(PointerDownEvent event) {
    _activePointerIds.add(event.pointer);
    if (_activePointerIds.length > 1) {
       widget.canvasController.endStroke();
       setState(() {}); // Enable InteractiveViewer panning
       return;
    }

    if (event.buttons == 4 || event.buttons == kMiddleMouseButton) {
      _middleMouseStart = event.position;
      return;
    }

    if (!widget.isDrawing) return;
    final Offset localOffset = widget.transformationController.toScene(
      event.localPosition,
    );

    final controller = widget.canvasController;

    if (controller.currentTool == DrawingTool.text || controller.currentTool == DrawingTool.document) {
      // Allow background GestureDetector to handle spawning text/document nodes
      // and their Widgets to handle selecting existing nodes.
      return;
    }

    if (controller.currentTool == DrawingTool.exportFrame) {
      final rect = controller.exportFrameNotifier.value;
      if (rect != null) {
        // Hit test handles (radius 20)
        final handles = [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight];
        for (int i = 0; i < handles.length; i++) {
          if ((localOffset - handles[i]).distance < 20) {
            _isResizingExportFrame = true;
            _resizeHandleIndex = i;
            _exportFrameDragStart = localOffset;
            _exportFrameStartRect = rect;
            return;
          }
        }
        // Hit test inside rect
        if (rect.contains(localOffset)) {
          _isDraggingExportFrame = true;
          _exportFrameDragStart = localOffset;
          _exportFrameStartRect = rect;
          return;
        }
      }
      return; // Ignore other touches while in export mode
    }

    if (controller.currentTool == DrawingTool.image) {
      controller.pickImageAndPlace(localOffset);
      return;
    }

    if (controller.currentTool == DrawingTool.select ||
        controller.currentTool == DrawingTool.lasso) {
      final selection = controller.selectionNotifier.value;
      if (selection.boundingBox != null) {
        final box = selection.boundingBox!;
        final double rotation = selection.rotation;

        Offset testOffset = localOffset;
        if (rotation != 0.0) {
          final center = box.center;
          final dx = localOffset.dx - center.dx;
          final dy = localOffset.dy - center.dy;
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
            if (controller.getNodeBounds(image).contains(localOffset)) return;
          }
          for (var text in layer.textNodes) {
            if (controller.getNodeBounds(text).contains(localOffset)) return;
          }
          for (var doc in layer.documentNodes) {
            if (controller.getNodeBounds(doc).contains(localOffset)) return;
          }
        }
      }
    }

    controller.startStroke(localOffset, event.pressure);
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
    // details.delta is in local (rotated/scaled) coordinate space.
    // We must un-rotate it by the node's rotation to get canvas space movement.
    double dx = details.delta.dx;
    double dy = details.delta.dy;

    // Check if node has rotation property
    if (node is ImageNode || node is TextNode || node is DocumentNode) {
      final double rot = node.rotation;
      final double cosA = math.cos(rot);
      final double sinA = math.sin(rot);
      dx = details.delta.dx * cosA - details.delta.dy * sinA;
      dy = details.delta.dx * sinA + details.delta.dy * cosA;
    } else {
      dx = details.delta.dx;
      dy = details.delta.dy;
    }

    final Offset sceneDelta = Offset(dx, dy) / scale;
    widget.canvasController.moveNode(node, sceneDelta);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointerIds.length > 1) return; // Let InteractiveViewer handle it

    if (_middleMouseStart != null) {
      final delta = event.position - _middleMouseStart!;
      _middleMouseStart = event.position;

      final matrix = widget.transformationController.value.clone();
      final scale = matrix.getMaxScaleOnAxis();
      matrix.multiply(
        Matrix4.translationValues(delta.dx / scale, delta.dy / scale, 0.0),
      );

      if (widget.canvasType == 'limited_infinite') {
        double dx = matrix.getTranslation().x;
        double dy = matrix.getTranslation().y;
        if (dx > 0) dx = 0;
        if (dy > 0) dy = 0;
        matrix.setTranslationRaw(dx, dy, matrix.getTranslation().z);
      }

      widget.transformationController.value = matrix;
      return;
    }

    if (!widget.isDrawing) return;

    final controller = widget.canvasController;

    if (controller.currentTool == DrawingTool.exportFrame) {
      final Offset localOffset = widget.transformationController.toScene(event.localPosition);
      if (_isDraggingExportFrame && _exportFrameDragStart != null && _exportFrameStartRect != null) {
        final delta = localOffset - _exportFrameDragStart!;
        controller.exportFrameNotifier.value = _exportFrameStartRect!.shift(delta);
      } else if (_isResizingExportFrame && _exportFrameDragStart != null && _exportFrameStartRect != null) {
        final delta = localOffset - _exportFrameDragStart!;
        Rect r = _exportFrameStartRect!;
        if (_resizeHandleIndex == 0) { // TL
          r = Rect.fromLTRB(r.left + delta.dx, r.top + delta.dy, r.right, r.bottom);
        } else if (_resizeHandleIndex == 1) { // TR
          r = Rect.fromLTRB(r.left, r.top + delta.dy, r.right + delta.dx, r.bottom);
        } else if (_resizeHandleIndex == 2) { // BL
          r = Rect.fromLTRB(r.left + delta.dx, r.top, r.right, r.bottom + delta.dy);
        } else if (_resizeHandleIndex == 3) { // BR
          r = Rect.fromLTRB(r.left, r.top, r.right + delta.dx, r.bottom + delta.dy);
        }
        // Prevent negative size
        if (r.width > 50 && r.height > 50) {
          controller.exportFrameNotifier.value = r;
        }
      }
      return;
    }

    if (controller.currentTool == DrawingTool.text ||
        controller.currentTool == DrawingTool.document ||
        controller.currentTool == DrawingTool.image) {
      return;
    }

    final Offset localOffset = widget.transformationController.toScene(
      event.localPosition,
    );
    widget.canvasController.updateStroke(localOffset, event.pressure);
  }

  void _onPointerUp(PointerEvent event) {
    _activePointerIds.remove(event.pointer);
    if (_activePointerIds.isEmpty) {
      setState(() {}); // Disable InteractiveViewer panning
    }

    if (_middleMouseStart != null) {
      _middleMouseStart = null;
      return;
    }

    if (!widget.isDrawing) return;

    final controller = widget.canvasController;

    if (controller.currentTool == DrawingTool.exportFrame) {
      _isDraggingExportFrame = false;
      _isResizingExportFrame = false;
      _resizeHandleIndex = -1;
      _exportFrameDragStart = null;
      _exportFrameStartRect = null;
      return;
    }

    if (controller.currentTool == DrawingTool.text ||
        controller.currentTool == DrawingTool.document ||
        controller.currentTool == DrawingTool.image) {
      return;
    }

    widget.canvasController.endStroke();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.canvasController,
      builder: (context, _) {
        final activeTool = widget.canvasController.currentTool;
        return DropTarget(
          onDragDone: (details) async {
            // Find RenderBox to convert global drag position to local coordinate
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final Offset localPosition = renderBox.globalToLocal(
              details.globalPosition,
            );
            final offset = widget.transformationController.toScene(
              localPosition,
            );
            for (final file in details.files) {
              widget.canvasController.placeDroppedImage(file.path, offset);
            }
          },
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                final controller = widget.transformationController;

                // Trackpad pan vs Mouse Wheel zoom based on HardwareKeyboard control/cmd keys
                if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) {
                  // Zooming via keyboard shortcut + scroll
                  final zoomDelta = signal.scrollDelta.dy > 0 ? 0.9 : 1.1;
                  final RenderBox renderBox = context.findRenderObject() as RenderBox;
                  final Offset localPosition = renderBox.globalToLocal(signal.position);

                  widget.canvasController.handleZoom(
                    localPosition,
                    zoomDelta,
                    controller,
                    widget.canvasType,
                  );
                } else {
                  // Panning via mouse wheel or trackpad
                  final currentMatrix = controller.value;
                  // The delta is inverted for translation
                  final translationDelta = Offset(-signal.scrollDelta.dx, -signal.scrollDelta.dy);

                  // Apply translation but keep scale
                  final nextMatrix = currentMatrix.clone();
                  final scale = nextMatrix.getMaxScaleOnAxis();
                  nextMatrix.translateByDouble(translationDelta.dx / scale, translationDelta.dy / scale, 0.0, 1.0);
                  controller.value = nextMatrix;
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) {
                final scenePosition = widget.transformationController.toScene(details.localPosition);
                bool hitTape = widget.canvasController.toggleTapeAtPoint(scenePosition);
                if (hitTape) return;

                if (widget.canvasController.currentTool == DrawingTool.text) {
                  widget.canvasController.saveSnapshot();
                  final newNode = TextNode(
                    id: 'text-${DateTime.now().millisecondsSinceEpoch}',
                    text: '',
                    position: scenePosition,
                    color: widget.canvasController.currentColor,
                  );
                  final layer = widget.canvasController.activeLayer;
                  layer.textNodes = [...layer.textNodes, newNode];
                  widget.canvasController.layersNotifier.value = List.from(
                    widget.canvasController.layersNotifier.value,
                  );
                } else if (widget.canvasController.currentTool == DrawingTool.document) {
                  widget.canvasController.saveSnapshot();
                  final newNode = DocumentNode(
                    id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                    text: '',
                    position: scenePosition,
                  );
                  final layer = widget.canvasController.activeLayer;
                  layer.documentNodes = [...layer.documentNodes, newNode];
                  widget.canvasController.layersNotifier.value = List.from(
                    widget.canvasController.layersNotifier.value,
                  );
                } else if (widget.canvasController.currentTool == DrawingTool.select ||
                           widget.canvasController.currentTool == DrawingTool.lasso) {
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
                  widget.canvasController.selectionNotifier.value = CanvasSelection();
                }
              },
              child: ExcludeSemantics(
                child: InteractiveViewer(
                  transformationController: widget.transformationController,
                  constrained: false,
                  clipBehavior: Clip.none,
                  minScale: 0.1,
                  maxScale: 10.0,
                  panEnabled: !widget.isDrawing || _activePointerIds.length > 1,
                  scaleEnabled: !widget.isDrawing || _activePointerIds.length > 1,
                  boundaryMargin: const EdgeInsets.all(1e9),
                  child: SizedBox(
                    width: 100000,
                    height: 100000,
                    child: Stack(
                      clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: widget.canvasType == 'a4'
                              ? HydropTheme.of(context).background
                              : Colors.transparent,
                        ),
                      ),

                      if (widget.canvasType == 'a4')
                        Center(
                          child: Container(
                            width: 1240,
                            height: 1754,
                            decoration: BoxDecoration(
                              color: HydropTheme.of(context).background,
                              border: Border.all(
                                color: HydropTheme.of(context).divider,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Layer Rendering Engine
                      ClipPath(
                        clipper: widget.canvasType == 'a4'
                            ? A4Clipper()
                            : (widget.canvasType == 'limited_infinite'
                                ? LimitedClipper()
                                : null),
                        clipBehavior: widget.canvasType == 'infinite'
                            ? Clip.none
                            : Clip.hardEdge,
                        child: ListenableBuilder(
                          listenable: Listenable.merge([
                            widget.canvasController.layersNotifier,
                            widget.canvasController.selectionNotifier,
                            widget.canvasController.activeLayerIndexNotifier,
                            // NOTE: selectionDragOffsetNotifier is intentionally excluded here.
                            // It fires on every PointerMoveEvent during drag and would cause
                            // the entire layer widget tree to rebuild at 60-120Hz.
                            // It is consumed directly in RepaintBoundary > CustomPaint via
                            // the `repaint` parameter of each painter, which only triggers
                            // rasterization — not a widget rebuild.
                          ]),
                          builder: (context, _) {
                            final layers =
                                widget.canvasController.layersNotifier.value;
                            final selection =
                                widget.canvasController.selectionNotifier.value;
                            final activeLayerIndex = widget
                                .canvasController
                                .activeLayerIndexNotifier
                                .value;
                            final activeStroke = widget
                                .canvasController
                                .activeStrokeNotifier
                                .stroke;

                            final layerWidgets = <Widget>[];

                            for (int i = 0; i < layers.length; i++) {
                              final layer = layers[i];
                              if (!layer.isVisible) continue;

                              // 1. Images
                              // 1. Images
                              if (layer.imageNodes.isNotEmpty) {
                                layerWidgets.addAll(
                                  layer.imageNodes
                                      .map(
                                        (img) => ValueListenableBuilder<Offset>(
                                          valueListenable: widget.canvasController.selectionDragOffsetNotifier,
                                          builder: (context, _, child) => ImageNodeWidget(
                                            key: ValueKey(img.id),
                                            node: img,
                                            isSelected: selection.imageNodes
                                                .contains(img),
                                            canvasController: widget.canvasController,
                                            onTap: () {
                                              if (activeTool ==
                                                      DrawingTool.select ||
                                                  activeTool ==
                                                      DrawingTool.lasso) {
                                                widget.canvasController
                                                    .selectNode(img);
                                              }
                                            },
                                            onPanStart:
                                                (activeTool == DrawingTool.select)
                                                ? () => _handleNodePanStart(img)
                                                : null,
                                            onPanUpdate:
                                                (activeTool == DrawingTool.select)
                                                ? (details) =>
                                                      _handleNodePanUpdate(
                                                        details,
                                                        img,
                                                        layer,
                                                      )
                                                : null,
                                            onResizeUpdate: (delta) {
                                              widget.canvasController
                                                  .saveSnapshot();
                                              // Transform delta based on scale
                                              final scale = widget
                                                  .transformationController
                                                  .value
                                                  .getMaxScaleOnAxis();
                                              final adjustedDelta = delta / scale;
  
                                              final newList =
                                                  List<ImageNode>.from(
                                                    layer.imageNodes,
                                                  );
                                              final index = newList.indexOf(img);
                                              if (index != -1) {
                                                newList[index] = ImageNode(
                                                  id: img.id,
                                                  filePath: img.filePath,
                                                  position: img.position,
                                                  width:
                                                      (img.width +
                                                              adjustedDelta.dx)
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
                                        ),
                                      )
                                      .toList(),
                                );
                              }

                              // 1.5 Connectors
                              final isLayerActive = i == activeLayerIndex;
                              if (layer.connectorNodes.isNotEmpty || 
                                  (isLayerActive && activeTool == DrawingTool.connector && (widget.canvasController.activeConnectorStartNodeId != null || widget.canvasController.activeConnectorStartPoint != null))) {
                                layerWidgets.add(
                                  RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      isComplex: true,
                                      willChange: isLayerActive &&
                                          (activeTool == DrawingTool.connector),
                                      painter: ConnectorPainter(
                                        connectors: layer.connectorNodes,
                                        controller: widget.canvasController,
                                        isActiveLayer: isLayerActive,
                                        repaint: widget.canvasController.selectionDragOffsetNotifier,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 2. Strokes
                              if (layer.strokes.isNotEmpty ||
                                  (isLayerActive &&
                                      activeStroke != null &&
                                      activeTool != DrawingTool.select)) {
                                // Split strokes: selected ones move visually, rest stay put.
                                final selectedSet = selection.strokes.toSet();
                                final hasSelectedStrokes =
                                    widget.canvasController.isTransforming &&
                                    layer.strokes.any(
                                      (s) => selectedSet.contains(s),
                                    );

                                layerWidgets.add(
                                  RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      isComplex: true,
                                      willChange: isLayerActive &&
                                          activeTool != DrawingTool.select &&
                                          activeStroke != null,
                                      painter: hasSelectedStrokes
                                          ? SelectionDragPainter(
                                              staticStrokes: layer.strokes
                                                  .where(
                                                    (s) =>
                                                        !selectedSet.contains(s),
                                                  )
                                                  .toList(),
                                              dragStrokes: layer.strokes
                                                  .where(
                                                    (s) => selectedSet.contains(s),
                                                  )
                                                  .toList(),
                                              pendingTranslate: widget.canvasController.pendingTranslate,
                                              pendingScale: widget.canvasController.pendingScale,
                                              pendingRotation: widget.canvasController.pendingRotation,
                                              transformCenter: widget.canvasController.transformCenter,
                                              activeStrokeNotifier:
                                                  (isLayerActive &&
                                                      activeTool !=
                                                          DrawingTool.select)
                                                  ? widget.canvasController.activeStrokeNotifier
                                                  : null,
                                              repaint: Listenable.merge([
                                                widget.canvasController.activeStrokeNotifier,
                                                // Rule 3: visual ghost during selection drag.
                                                widget.canvasController.selectionDragOffsetNotifier,
                                              ]),
                                            )
                                          : CombinedCanvasPainter(
                                              strokes: layer.strokes,
                                              activeStrokeNotifier:
                                                  (isLayerActive &&
                                                      activeTool !=
                                                          DrawingTool.select)
                                                  ? widget.canvasController.activeStrokeNotifier
                                                  : null,
                                              repaint: widget.canvasController.activeStrokeNotifier,
                                            ),
                                    ),
                                  ),
                                );
                              }

                              // 3. Texts
                              if (layer.textNodes.isNotEmpty) {
                                layerWidgets.addAll(
                                  layer.textNodes
                                      .map(
                                        (t) => ValueListenableBuilder<Offset>(
                                          valueListenable: widget.canvasController.selectionDragOffsetNotifier,
                                          builder: (context, _, child) => TextNodeWidget(
                                            key: ValueKey(t.id),
                                            node: t,
                                            isSelected: selection.textNodes.contains(t),
                                            canvasController: widget.canvasController,
                                            forceEditOnTap: activeTool == DrawingTool.text,
                                            autofocus: t.text.isEmpty,
                                            onTap: () {
                                              if (activeTool == DrawingTool.select || activeTool == DrawingTool.lasso) {
                                                widget.canvasController.selectNode(t);
                                              }
                                            },
                                            onPanStart: (activeTool == DrawingTool.select) ? () => _handleNodePanStart(t) : null,
                                            onPanUpdate: (activeTool == DrawingTool.select) ? (details) => _handleNodePanUpdate(details, t, layer) : null,
                                            onTextChanged: (newText) {
                                              widget.canvasController.saveSnapshot();
                                              t.text = newText;
                                              widget.canvasController.layersNotifier.value = List.from(widget.canvasController.layersNotifier.value);
                                            },
                                            onStyleChanged: () {
                                              widget.canvasController.saveSnapshot();
                                              widget.canvasController.layersNotifier.value = List.from(widget.canvasController.layersNotifier.value);
                                            },
                                            onDelete: () {
                                              widget.canvasController.saveSnapshot();
                                              final list = List<TextNode>.from(layer.textNodes);
                                              list.remove(t);
                                              layer.textNodes = list;
                                              widget.canvasController.layersNotifier.value = List.from(widget.canvasController.layersNotifier.value);
                                            },
                                          ),
                                        ),
                                      )
                                      .toList(),
                                );
                              }

                              // 4. Documents
                              if (layer.documentNodes.isNotEmpty) {
                                layerWidgets.addAll(
                                  layer.documentNodes
                                      .map(
                                        (d) => ValueListenableBuilder<Offset>(
                                          valueListenable: widget.canvasController.selectionDragOffsetNotifier,
                                          builder: (context, _, child) => DocumentNodeWidget(
                                            key: ValueKey(d.id),
                                            node: d,
                                            isSelected: selection.documentNodes
                                                .contains(d),
                                            canvasController: widget.canvasController,
                                            forceEditOnTap:
                                                activeTool == DrawingTool.document,
                                            autofocus: d.text.isEmpty,
                                            onTap: () {
                                              if (activeTool ==
                                                      DrawingTool.select ||
                                                  activeTool ==
                                                      DrawingTool.lasso) {
                                                widget.canvasController
                                                    .selectNode(d);
                                              }
                                            },
                                            onPanStart:
                                                (activeTool == DrawingTool.select)
                                                ? () => _handleNodePanStart(d)
                                                : null,
                                            onPanUpdate:
                                                (activeTool == DrawingTool.select)
                                                ? (details) =>
                                                      _handleNodePanUpdate(
                                                        details,
                                                        d,
                                                        layer,
                                                      )
                                                : null,
                                            onTextChanged: (newText) {
                                              widget.canvasController
                                                  .saveSnapshot();
                                              d.text = newText;
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
                                              final list = List<DocumentNode>.from(
                                                layer.documentNodes,
                                              );
                                              list.remove(d);
                                              layer.documentNodes = list;
                                              widget
                                                  .canvasController
                                                  .layersNotifier
                                                  .value = List.from(
                                                layers,
                                              );
                                            },
                                          ),
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
                          if (selection.isEmpty ||
                              selection.boundingBox == null) {
                            return const SizedBox.shrink();
                          }

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              BoundingBoxOverlay(
                                initialRect: selection.boundingBox!,
                                initialRotation: selection.rotation,
                                initialScale: 1.0,
                                canvasController: widget.canvasController,
                                onTransformUpdate:
                                    (
                                      translate,
                                      scaleMultiplier,
                                      rotationDelta,
                                    ) {
                                      widget.canvasController
                                          .transformSelection(
                                            translate,
                                            scaleMultiplier,
                                            rotationDelta,
                                          );
                                    },
                                onTransformEnd: () {
                                  widget.canvasController
                                      .commitSelectionTransform();
                                  widget.canvasController.saveSnapshot();
                                },
                              ),
                              // Floating Menu
                              Positioned(
                                left: selection.boundingBox!.left,
                                top: selection.boundingBox!.top - 64,
                                child: UnconstrainedBox(
                                  alignment: Alignment.topLeft,
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
                                            onPressed: () => widget
                                                .canvasController
                                                .duplicateSelection(),
                                          ),
                                          const SizedBox(width: 4),
                                          _MenuButton(
                                            icon: Icons.delete_rounded,
                                            color: Colors.redAccent,
                                            tooltip: 'Delete',
                                            onPressed: () => widget
                                                .canvasController
                                                .deleteSelection(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: MarqueeSelectionPainter(
                              canvasController: widget.canvasController,
                              activeTool: activeTool,
                              color: HydropTheme.of(context).primary,
                              repaint: widget.canvasController.activeStrokeNotifier,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        );
      },
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

class LimitedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
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

class MarqueeSelectionPainter extends CustomPainter {
  final CanvasController canvasController;
  final DrawingTool activeTool;
  final Color color;

  MarqueeSelectionPainter({
    required this.canvasController,
    required this.activeTool,
    required this.color,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (activeTool != DrawingTool.select) return;
    final activeStroke = canvasController.activeStrokeNotifier.stroke;
    if (activeStroke == null || activeStroke.points.isEmpty) return;

    double minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    for (var p in activeStroke.points) {
      if (p.point.dx < minX) minX = p.point.dx;
      if (p.point.dx > maxX) maxX = p.point.dx;
      if (p.point.dy < minY) minY = p.point.dy;
      if (p.point.dy > maxY) maxY = p.point.dy;
    }
    if (minX == double.infinity) return;

    final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
    final paintFill = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(rect, paintFill);
    canvas.drawRect(rect, paintStroke);
  }

  @override
  bool shouldRepaint(covariant MarqueeSelectionPainter oldDelegate) {
    return oldDelegate.activeTool != activeTool || oldDelegate.color != color;
  }
}
