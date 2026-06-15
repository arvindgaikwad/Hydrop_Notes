// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/stroke.dart';
import '../models/canvas_objects.dart';
import '../theme/theme.dart';
import 'dart:math';
import '../widgets/canvas_background_pattern.dart';
import 'workspace_controller.dart';
import '../utils/rdp_simplifier.dart';


enum DrawingTool {
  pan,
  inkPen,
  normalPen,
  pixelEraser,
  strokeEraser,
  text,
  image,
  lasso,
  select,
  tape,
  connector,
  document,
  exportFrame,
}

class CanvasSelection {
  final List<Stroke> strokes;
  final List<TextNode> textNodes;
  final List<ImageNode> imageNodes;
  final List<DocumentNode> documentNodes;
  Rect? boundingBox;
  double rotation;

  CanvasSelection({
    this.strokes = const [],
    this.textNodes = const [],
    this.imageNodes = const [],
    this.documentNodes = const [],
    this.boundingBox,
    this.rotation = 0.0,
  });

  bool get isEmpty =>
      strokes.isEmpty && textNodes.isEmpty && imageNodes.isEmpty && documentNodes.isEmpty;
}

class CanvasStateSnapshot {
  final List<CanvasLayer> layers;

  CanvasStateSnapshot({required this.layers});

  factory CanvasStateSnapshot.fromCurrent(CanvasController controller) {
    return CanvasStateSnapshot(
      layers: controller.layersNotifier.value.map((l) => l.clone()).toList(),
    );
  }
}

class CanvasController extends ChangeNotifier {
  // Notifier for all layers
  final ValueNotifier<List<CanvasLayer>> layersNotifier = ValueNotifier([
    CanvasLayer(
      id: 'layer-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Layer 1',
    ),
  ]);

  // Notifiers for background pattern state
  final ValueNotifier<CanvasBackgroundVariant> backgroundVariantNotifier = ValueNotifier(CanvasBackgroundVariant.grid);
  final ValueNotifier<CanvasBackgroundMask> backgroundMaskNotifier = ValueNotifier(CanvasBackgroundMask.none);

  // Notifier for the active layer index
  final ValueNotifier<int> activeLayerIndexNotifier = ValueNotifier(0);

  // Notifier for canvas scenes
  final ValueNotifier<List<CanvasScene>> scenesNotifier = ValueNotifier([]);

  // Notifier for the stroke currently being drawn
  final ActiveStrokeNotifier activeStrokeNotifier = ActiveStrokeNotifier();

  // Notifier for the lasso selection state
  final ValueNotifier<CanvasSelection> selectionNotifier = ValueNotifier(
    CanvasSelection(),
  );

  // Visual-only offset applied to selected strokes during drag (no data mutation).
  // Reset to zero on commit. Observed by the canvas painter for live feedback.
  final ValueNotifier<Offset> selectionDragOffsetNotifier =
      ValueNotifier(Offset.zero);

  // Undo / Redo Stacks
  final List<CanvasStateSnapshot> undoStack = [];
  final List<CanvasStateSnapshot> redoStack = [];

  // Export State
  final ValueNotifier<Rect?> exportFrameNotifier = ValueNotifier(null);
  final ValueNotifier<String?> pendingExportFormatNotifier = ValueNotifier(null);
  final ValueNotifier<String> pendingExportNameNotifier = ValueNotifier('horizon_export');

  DrawingTool currentTool = DrawingTool.pan;
  Color currentColor = AppTheme.primary;
  double currentWidth = 4.0;

  // Pending transform accumulator — built up during drag, flushed on release.
  Offset _pendingTranslate = Offset.zero;
  double _pendingScale = 1.0;
  double _pendingRotation = 0.0;
  Offset? _transformCenter; // center of bounding box when drag started

  Offset get pendingTranslate => _pendingTranslate;
  double get pendingScale => _pendingScale;
  double get pendingRotation => _pendingRotation;
  Offset? get transformCenter => _transformCenter;
  bool get isTransforming => _pendingTranslate != Offset.zero || _pendingScale != 1.0 || _pendingRotation != 0.0;

  // Connector Tool State
  String? activeConnectorStartNodeId;
  Offset? activeConnectorStartPoint;
  Offset? activeConnectorEndPoint;

  void setTool(DrawingTool tool) {
    currentTool = tool;
    notifyListeners();
  }

  void setColor(Color color) {
    currentColor = color;
    if (currentTool != DrawingTool.inkPen &&
        currentTool != DrawingTool.normalPen &&
        currentTool != DrawingTool.text &&
        currentTool != DrawingTool.tape &&
        currentTool != DrawingTool.connector) {
      currentTool = DrawingTool.inkPen;
    }
    notifyListeners();
  }

  void setWidth(double width) {
    currentWidth = width;
    notifyListeners();
  }

  CanvasLayer get activeLayer {
    if (activeLayerIndexNotifier.value < 0 ||
        activeLayerIndexNotifier.value >= layersNotifier.value.length) {
      return layersNotifier.value.last;
    }
    return layersNotifier.value[activeLayerIndexNotifier.value];
  }

  void startStroke(Offset point, double pressure) {
    if (currentTool == DrawingTool.text || currentTool == DrawingTool.image) {
      return;
    }

    if (currentTool == DrawingTool.connector) {
      final node = findNodeAtPoint(point);
      startConnector(node?.id, startPoint: node == null ? point : null);
      return;
    }

    if (currentTool == DrawingTool.strokeEraser) {
      _eraseStrokeAtPoint(point);
      return;
    }

    if (activeLayer.isLocked || !activeLayer.isVisible) {
      return; // Cannot draw on locked/hidden layer
    }

    final stroke = Stroke(
      points: [StrokePoint(point, pressure)],
      color:
          (currentTool == DrawingTool.lasso ||
              currentTool == DrawingTool.select)
          ? AppTheme.primary.withValues(alpha: 0.5)
          : (currentTool == DrawingTool.pixelEraser
                ? Colors.transparent
                : currentColor),
      baseWidth:
          (currentTool == DrawingTool.lasso ||
              currentTool == DrawingTool.select)
          ? 2.0
          : (currentWidth *
                (currentTool == DrawingTool.pixelEraser || currentTool == DrawingTool.tape ? 3.0 : 1.0)),
      isPixelEraser: currentTool == DrawingTool.pixelEraser,
      isInkPen: currentTool == DrawingTool.inkPen,
      isTape: currentTool == DrawingTool.tape,
    );
    activeStrokeNotifier.start(stroke);
  }

  void updateStroke(Offset point, double pressure) {
    if (currentTool == DrawingTool.connector) {
      updateConnector(point);
      return;
    }

    if (currentTool == DrawingTool.strokeEraser) {
      _eraseStrokeAtPoint(point);
      return;
    }

    activeStrokeNotifier.update(point, pressure);
  }

  void endStroke() {
    if (currentTool == DrawingTool.connector) {
      if ((activeConnectorStartNodeId != null || activeConnectorStartPoint != null) &&
          activeConnectorEndPoint != null) {
        final targetNode = findNodeAtPoint(activeConnectorEndPoint!);
        final endNodeId = targetNode?.id;

        // Prevent connecting a node to itself
        if (endNodeId == null || endNodeId != activeConnectorStartNodeId) {
          final newConnector = ConnectorNode(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            startNodeId: activeConnectorStartNodeId,
            endNodeId: endNodeId,
            startPoint: activeConnectorStartNodeId == null ? activeConnectorStartPoint : null,
            endPoint: endNodeId == null ? activeConnectorEndPoint : null,
            colorValue: currentColor.toARGB32(),
            strokeWidth: currentWidth,
          );
          final layer = activeLayer;
          layer.connectorNodes.add(newConnector);
          layersNotifier.value = List.from(layersNotifier.value);
        }
      }
      activeConnectorStartNodeId = null;
      activeConnectorStartPoint = null;
      activeConnectorEndPoint = null;
      notifyListeners();
      return;
    }

    if (currentTool == DrawingTool.text ||
        currentTool == DrawingTool.image ||
        currentTool == DrawingTool.strokeEraser) {
      return;
    }

    final finishedStroke = activeStrokeNotifier.stroke;
    if (finishedStroke != null && finishedStroke.points.isNotEmpty) {
      if (currentTool == DrawingTool.lasso) {
        _calculateLassoSelection(finishedStroke);
      } else if (currentTool == DrawingTool.select) {
        _calculateRectSelection(finishedStroke);
      } else {
        saveSnapshot();
        // We only use RDP for Tape strokes (straight highlights).
        // All Pens need raw, dense pointer data to compute smooth bezier curves accurately without jagged edges.
        if (finishedStroke.points.length > 2 && finishedStroke.isTape) {
          final simplifiedPoints = RDPSimplifier.simplify(finishedStroke.points, 0.5);
          finishedStroke.points.clear();
          finishedStroke.points.addAll(simplifiedPoints);
          finishedStroke.invalidateCache();
        }
        final layer = activeLayer;
        layer.strokes = [...layer.strokes, finishedStroke];
        _forceLayersUpdate();
      }
    }
    activeStrokeNotifier.end();
  }

  TransformableNode? findNodeAtPoint(Offset point) {
    for (var layer in layersNotifier.value.reversed) {
      if (!layer.isVisible || layer.isLocked) continue;
      
      for (var text in layer.textNodes.reversed) {
        if (getNodeBounds(text).contains(point)) return text;
      }
      for (var image in layer.imageNodes.reversed) {
        if (getNodeBounds(image).contains(point)) return image;
      }
      for (var doc in layer.documentNodes.reversed) {
        if (getNodeBounds(doc).contains(point)) return doc;
      }
    }
    return null;
  }

  void moveNode(TransformableNode node, Offset delta) {
    node.position += delta;
    _forceLayersUpdate();
  }

  void _stretchStroke(Stroke stroke, String movedNodeId, Offset delta) {
    final int N = stroke.points.length;
    if (N <= 1) return;

    List<double> cumulativeDist = List.filled(N, 0.0);
    double totalDist = 0.0;
    for (int i = 1; i < N; i++) {
      totalDist += (stroke.points[i].point - stroke.points[i - 1].point).distance;
      cumulativeDist[i] = totalDist;
    }

    for (int i = 0; i < N; i++) {
      double t = totalDist == 0 ? (i / (N - 1)) : cumulativeDist[i] / totalDist;
      double weight = 0.0;
      if (stroke.startNodeId == movedNodeId) weight += (1.0 - t);
      if (stroke.endNodeId == movedNodeId) weight += t;

      stroke.points[i].point += delta * weight;
    }
    stroke.invalidateCache();
  }

  void selectNode(dynamic node) {
    if (node is! TextNode && node is! ImageNode && node is! DocumentNode) return;

    final bounds = getNodeBounds(node);
    selectionNotifier.value = CanvasSelection(
      textNodes: node is TextNode ? [node] : [],
      imageNodes: node is ImageNode ? [node] : [],
      documentNodes: node is DocumentNode ? [node] : [],
      boundingBox: bounds,
      rotation: (node is TextNode || node is ImageNode || node is DocumentNode) ? node.rotation : 0.0,
    );
    notifyListeners();
  }

  bool toggleTapeAtPoint(Offset point) {
    for (var layer in layersNotifier.value.reversed) {
      if (!layer.isVisible || layer.isLocked) continue;
      for (var stroke in layer.strokes.reversed) {
        if (stroke.isTape) {
          // If the point is inside the bounding box of the tape
          final bounds = _getStrokeBounds(stroke);
          if (bounds.contains(point)) {
            // Precise hit testing against the path could be done with stroke.path.contains(point)
            // But path.contains is a bit slow and bounding box is usually enough for thick tapes,
            // let's try path.contains for accuracy:
            if (stroke.path.contains(point)) {
              saveSnapshot();
              stroke.isTapeRevealed = !stroke.isTapeRevealed;
              _forceLayersUpdate();
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  void startConnector(String? nodeId, {Offset? startPoint}) {
    saveSnapshot();
    activeConnectorStartNodeId = nodeId;
    activeConnectorStartPoint = startPoint;
    activeConnectorEndPoint = null;
    notifyListeners();
  }

  void updateConnector(Offset endPoint) {
    if (activeConnectorStartNodeId != null || activeConnectorStartPoint != null) {
      activeConnectorEndPoint = endPoint;
      notifyListeners();
    }
  }

  Rect getNodeBounds(dynamic node) {
    if (node is TextNode || node is ImageNode || node is DocumentNode) {
      final double width = node.width;
      final double height = node.height;
      final double scale = node.scale;
      final Offset position = node.position;

      // Since Transform.scale scales from the center, the visible top-left shifts.
      // visible_width = width * scale
      // visible_height = height * scale
      // visible_left = position.dx + (width/2) - (visible_width/2)
      final double vWidth = width * scale;
      final double vHeight = height * scale;
      final double vLeft = position.dx + (width / 2) - (vWidth / 2);
      final double vTop = position.dy + (height / 2) - (vHeight / 2);

      return Rect.fromLTWH(vLeft, vTop, vWidth, vHeight);
    }
    return Rect.zero;
  }

  /// Called on every pointer-move during drag/rotate/resize.
  /// ONLY updates the bounding box visually — zero stroke math.
  void transformSelection(
    Offset translateDelta,
    double scaleMultiplier,
    double rotationDelta,
  ) {
    final selection = selectionNotifier.value;
    if (selection.isEmpty ||
        (currentTool != DrawingTool.lasso && currentTool != DrawingTool.select)) {
      return;
    }
    if (selection.boundingBox == null) return;

    // Accumulate the pending transform so we can flush it on release.
    _pendingTranslate += translateDelta;
    _pendingScale *= scaleMultiplier;
    _pendingRotation += rotationDelta;
    _transformCenter ??= selection.boundingBox!.center;

    // Update the visual drag offset for the canvas painter (zero-cost live feedback).
    selectionDragOffsetNotifier.value = _pendingTranslate;

    // Update the bounding box visually (cheap — just a Rect).
    final Rect oldBounds = selection.boundingBox!;
    double newWidth = oldBounds.width * scaleMultiplier;
    double newHeight = oldBounds.height * scaleMultiplier;
    Offset newCenter = oldBounds.center + translateDelta;

    selectionNotifier.value = CanvasSelection(
      strokes: selection.strokes,
      textNodes: selection.textNodes,
      imageNodes: selection.imageNodes,
      documentNodes: selection.documentNodes,
      boundingBox: Rect.fromCenter(
        center: newCenter,
        width: newWidth,
        height: newHeight,
      ),
      rotation: selection.rotation + rotationDelta,
    );

    if (translateDelta != Offset.zero) {
      bool forcesUpdate = false;
      for (var layer in layersNotifier.value) {
        if (layer.isLocked) continue;
        for (var stroke in layer.strokes) {
          if (!selection.strokes.contains(stroke)) {
            bool startSelected = stroke.startNodeId != null && 
                (selection.textNodes.any((t) => t.id == stroke.startNodeId) || 
                 selection.imageNodes.any((i) => i.id == stroke.startNodeId) ||
                 selection.documentNodes.any((d) => d.id == stroke.startNodeId));
            bool endSelected = stroke.endNodeId != null && 
                (selection.textNodes.any((t) => t.id == stroke.endNodeId) || 
                 selection.imageNodes.any((i) => i.id == stroke.endNodeId) ||
                 selection.documentNodes.any((d) => d.id == stroke.endNodeId));
                 
            if (startSelected && !endSelected) {
              _stretchStroke(stroke, stroke.startNodeId!, translateDelta);
              forcesUpdate = true;
            } else if (endSelected && !startSelected) {
              _stretchStroke(stroke, stroke.endNodeId!, translateDelta);
              forcesUpdate = true;
            } else if (startSelected && endSelected) {
              for (int i = 0; i < stroke.points.length; i++) {
                stroke.points[i] = StrokePoint(stroke.points[i].point + translateDelta, stroke.points[i].pressure);
              }
              stroke.invalidateCache();
              forcesUpdate = true;
            }
          }
        }
      }
      if (forcesUpdate) _forceLayersUpdate();
    }
  }

  /// Called once on pointer-up — applies the accumulated transform to actual
  /// stroke points/nodes and forces a canvas repaint. This is the expensive
  /// step but it only happens once per gesture, so it feels instant.
  void commitSelectionTransform() {
    final selection = selectionNotifier.value;
    if (selection.isEmpty) {
      _resetPendingTransform();
      return;
    }

    final Offset translate = _pendingTranslate;
    final double scale = _pendingScale;
    final double rotation = _pendingRotation;
    final Offset center = _transformCenter ?? (selection.boundingBox?.center ?? Offset.zero);

    _resetPendingTransform();

    if (translate == Offset.zero && scale == 1.0 && rotation == 0.0) return;

    Offset transformPoint(Offset p) {
      double dx = p.dx - center.dx;
      double dy = p.dy - center.dy;

      dx *= scale;
      dy *= scale;

      if (rotation != 0.0) {
        double s = sin(rotation);
        double c = cos(rotation);
        double nx = dx * c - dy * s;
        double ny = dx * s + dy * c;
        dx = nx;
        dy = ny;
      }

      return Offset(
        center.dx + dx + translate.dx,
        center.dy + dy + translate.dy,
      );
    }

    for (var stroke in selection.strokes) {
      stroke.baseWidth *= scale;
      for (var i = 0; i < stroke.points.length; i++) {
        stroke.points[i] = StrokePoint(
          transformPoint(stroke.points[i].point),
          stroke.points[i].pressure,
        );
      }
      stroke.invalidateCache();
    }

    for (var text in selection.textNodes) {
      Offset nodeCenter = Offset(
        text.position.dx + text.width / 2,
        text.position.dy + text.height / 2,
      );
      Offset newCenter = transformPoint(nodeCenter);
      text.scale *= scale;
      text.rotation += rotation;
      text.position = Offset(
        newCenter.dx - text.width / 2,
        newCenter.dy - text.height / 2,
      );
    }

    for (var image in selection.imageNodes) {
      Offset nodeCenter = Offset(
        image.position.dx + image.width / 2,
        image.position.dy + image.height / 2,
      );
      Offset newCenter = transformPoint(nodeCenter);
      image.scale *= scale;
      image.rotation += rotation;
      image.position = Offset(
        newCenter.dx - image.width / 2,
        newCenter.dy - image.height / 2,
      );
    }

    for (var doc in selection.documentNodes) {
      Offset nodeCenter = Offset(
        doc.position.dx + doc.width / 2,
        doc.position.dy + doc.height / 2,
      );
      Offset newCenter = transformPoint(nodeCenter);
      doc.scale *= scale;
      doc.rotation += rotation;
      doc.position = Offset(
        newCenter.dx - doc.width / 2,
        newCenter.dy - doc.height / 2,
      );
    }

    _forceLayersUpdate();
  }

  void _resetPendingTransform() {
    _pendingTranslate = Offset.zero;
    _pendingScale = 1.0;
    _pendingRotation = 0.0;
    _transformCenter = null;
    selectionDragOffsetNotifier.value = Offset.zero;
  }

  /// Calculates the visual canvas coordinate of a corner anchor for a rotated bounding box.
  /// Used by selection handles to determine their true geometric pivot points.
  Offset getRotatedCornerCanvasPosition(
    Rect unrotatedBounds,
    double rotation,
    Alignment alignment,
  ) {
    final double w = unrotatedBounds.width;
    final double h = unrotatedBounds.height;
    final Offset center = unrotatedBounds.center;
    final double lx = alignment.x * w / 2;
    final double ly = alignment.y * h / 2;
    final double cosA = cos(rotation);
    final double sinA = sin(rotation);
    return Offset(
      center.dx + lx * cosA - ly * sinA,
      center.dy + lx * sinA + ly * cosA,
    );
  }

  /// Calculates the unrotated Top-Left canvas coordinate needed to place a specific anchor at a target position.
  Offset getUnrotatedTopLeftForRotatedAnchor(
    Offset targetAnchorCanvas,
    double width,
    double height,
    double rotation,
    Alignment alignment,
  ) {
    final double lx = alignment.x * width / 2;
    final double ly = alignment.y * height / 2;
    final double cosA = cos(rotation);
    final double sinA = sin(rotation);
    final Offset center = Offset(
      targetAnchorCanvas.dx - (lx * cosA - ly * sinA),
      targetAnchorCanvas.dy - (lx * sinA + ly * cosA),
    );
    return center - Offset(width / 2, height / 2);
  }

  /// Calculates the rotation angle between the object's global center and the current mouse position.
  double calculateRotationAngle(Offset centerGlobal, Offset currentGlobal) {
    return atan2(
      currentGlobal.dy - centerGlobal.dy,
      currentGlobal.dx - centerGlobal.dx,
    );
  }

  /// Calculates the appropriate mouse cursor for a given resize handle alignment and current rotation.
  MouseCursor getCursorForAlignment(Alignment alignment, double rotation) {
    // Determine the base angle of the corner in unrotated space
    double baseAngle = atan2(alignment.y, alignment.x);

    // Add the current rotation to find its visual angle on screen
    double visualAngle = (baseAngle + rotation) % (2 * pi);
    if (visualAngle < 0) visualAngle += 2 * pi;

    double degrees = visualAngle * 180 / pi;
    degrees = degrees % 180;

    if (degrees > 22.5 && degrees <= 67.5) {
      return SystemMouseCursors.resizeUpLeftDownRight;
    } else if (degrees > 67.5 && degrees <= 112.5) {
      return SystemMouseCursors.resizeUpDown;
    } else if (degrees > 112.5 && degrees <= 157.5) {
      return SystemMouseCursors.resizeUpRightDownLeft;
    } else {
      return SystemMouseCursors.resizeLeftRight;
    }
  }

  /// Calculates the uniform scale multiplier when dragging a resize handle.
  /// Projects the current mouse vector onto the ideal diagonal vector.
  double calculateResizeScaleMultiplier(
    Offset handleGlobal,
    Offset anchorGlobal,
    Offset currentGlobal,
  ) {
    final Offset initialDiagonal = handleGlobal - anchorGlobal;
    final double initialDistance = initialDiagonal.distance;
    if (initialDistance < 1.0) return 1.0;

    final Offset currentVector = currentGlobal - anchorGlobal;
    final Offset diagUnit = initialDiagonal / initialDistance;
    final double projectedLength =
        currentVector.dx * diagUnit.dx + currentVector.dy * diagUnit.dy;

    return (projectedLength / initialDistance).clamp(0.1, 10.0);
  }

  /// Translates a local DragUpdateDetails.delta (which is pre-rotated by GestureDetector's Transform)
  /// back into absolute, unrotated canvas space.
  Offset translateLocalDeltaToCanvasSpace(Offset localDelta, double rotation) {
    final double cosA = cos(rotation);
    final double sinA = sin(rotation);
    return Offset(
      localDelta.dx * cosA - localDelta.dy * sinA,
      localDelta.dx * sinA + localDelta.dy * cosA,
    );
  }

  void rotateSelection90() {
    saveSnapshot();
    transformSelection(Offset.zero, 1.0, pi / 2);
    commitSelectionTransform();
  }

  void scaleSelection(double factor) {
    saveSnapshot();
    transformSelection(Offset.zero, factor, 0.0);
    commitSelectionTransform();
  }

  void clearSelection() {
    selectionNotifier.value = CanvasSelection();
  }

  void deleteSelection() {
    final selection = selectionNotifier.value;
    if (selection.isEmpty) return;

    saveSnapshot();

    for (var layer in layersNotifier.value) {
      if (layer.isLocked) continue;

      layer.strokes = layer.strokes.where((s) => !selection.strokes.contains(s)).toList();
      layer.textNodes = layer.textNodes.where((t) => !selection.textNodes.contains(t)).toList();
      layer.imageNodes = layer.imageNodes.where((i) => !selection.imageNodes.contains(i)).toList();
      layer.documentNodes = layer.documentNodes.where((d) => !selection.documentNodes.contains(d)).toList();
    }

    clearSelection();
    _forceLayersUpdate();
  }

  void duplicateSelection() {
    final selection = selectionNotifier.value;
    if (selection.isEmpty) return;

    saveSnapshot();

    final offset = const Offset(20, 20);
    final active = activeLayer;

    // Deep copy strokes
    final newStrokes = selection.strokes
        .map(
          (s) => Stroke(
            points: s.points
                .map((p) => StrokePoint(p.point + offset, p.pressure))
                .toList(),
            color: s.color,
            baseWidth: s.baseWidth,
            isPixelEraser: s.isPixelEraser,
          ),
        )
        .toList();
    active.strokes.addAll(newStrokes);

    // Deep copy text
    final newTexts = selection.textNodes
        .map(
          (t) => TextNode(
            id: 'text-${DateTime.now().microsecondsSinceEpoch}',
            text: t.text,
            position: t.position + offset,
            fontSize: t.fontSize,
            color: t.color,
            isBold: t.isBold,
            width: t.width,
            height: t.height,
            rotation: t.rotation,
            scale: t.scale,
          ),
        )
        .toList();
    active.textNodes.addAll(newTexts);

    // Deep copy images
    final newImages = selection.imageNodes
        .map(
          (i) => ImageNode(
            id: 'img-${DateTime.now().microsecondsSinceEpoch}',
            filePath: i.filePath,
            position: i.position + offset,
            width: i.width,
            height: i.height,
            rotation: i.rotation,
            scale: i.scale,
          ),
        )
        .toList();
    active.imageNodes.addAll(newImages);

    // Deep copy documents
    final newDocuments = selection.documentNodes
        .map(
          (d) => DocumentNode(
            id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
            text: d.text,
            position: d.position + offset,
            width: d.width,
            height: d.height,
            rotation: d.rotation,
            scale: d.scale,
          ),
        )
        .toList();
    active.documentNodes.addAll(newDocuments);

    final newBoundingBox = selection.boundingBox?.translate(
      offset.dx,
      offset.dy,
    );

    selectionNotifier.value = CanvasSelection(
      strokes: newStrokes,
      textNodes: newTexts,
      imageNodes: newImages,
      documentNodes: newDocuments,
      boundingBox: newBoundingBox,
      rotation: selection.rotation,
    );
    _forceLayersUpdate();
  }

  void updateNodeTransform(
    String id,
    Offset position,
    double width,
    double height,
    double rotation,
    double scale,
  ) {
    bool found = false;
    for (var layer in layersNotifier.value) {
      if (layer.isLocked) continue;

      for (var text in layer.textNodes) {
        if (text.id == id) {
          text.position = position;
          text.width = width;
          text.height = height;
          text.rotation = rotation;
          text.scale = scale;
          found = true;
          break;
        }
      }
      if (found) break;

      for (var img in layer.imageNodes) {
        if (img.id == id) {
          img.position = position;
          img.width = width;
          img.height = height;
          img.rotation = rotation;
          img.scale = scale;
          found = true;
          break;
        }
      }
      if (found) break;

      for (var doc in layer.documentNodes) {
        if (doc.id == id) {
          doc.position = position;
          doc.width = width;
          doc.height = height;
          doc.rotation = rotation;
          doc.scale = scale;
          found = true;
          break;
        }
      }
      if (found) break;
    }

    if (found) {
      _forceLayersUpdate();
    }
  }

  void addTextNode(String text, Offset position) {
    saveSnapshot();
    final newNode = TextNode(
      id: 'text-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      position: position,
      color: currentColor,
    );
    final layer = activeLayer;
    layer.textNodes = [...layer.textNodes, newNode];
    _forceLayersUpdate();
    setTool(DrawingTool.pan); // Switch to pan to allow interaction
  }

  void addDocumentNode(Offset position) {
    saveSnapshot();
    final newNode = DocumentNode(
      id: 'doc-${DateTime.now().microsecondsSinceEpoch}',
      text: '',
      position: position,
    );
    final layer = activeLayer;
    layer.documentNodes = [...layer.documentNodes, newNode];
    _forceLayersUpdate();
    setTool(DrawingTool.select); // Switch to select to allow interaction
    selectNode(newNode);
  }

  void updateTextNodeText(String id, String newText) {
    bool found = false;
    for (var layer in layersNotifier.value) {
      if (layer.isLocked) continue;
      for (var text in layer.textNodes) {
        if (text.id == id) {
          saveSnapshot();
          text.text = newText;
          found = true;
          break;
        }
      }
      if (found) break;
    }
    if (found) {
      _forceLayersUpdate();
    }
  }

  void updateDocumentNodeText(String id, String newText) {
    bool found = false;
    for (var layer in layersNotifier.value) {
      if (layer.isLocked) continue;
      for (var doc in layer.documentNodes) {
        if (doc.id == id) {
          saveSnapshot();
          doc.text = newText;
          found = true;
          break;
        }
      }
      if (found) break;
    }
    if (found) {
      _forceLayersUpdate();
    }
  }

  void updateTextNodePosition(String id, Offset newPosition) {
    bool found = false;
    for (var layer in layersNotifier.value) {
      if (layer.isLocked) continue;
      for (var text in layer.textNodes) {
        if (text.id == id) {
          saveSnapshot();
          text.position = newPosition;
          found = true;
          break;
        }
      }
      if (found) break;
    }
    if (found) {
      _forceLayersUpdate();
    }
  }

  void _calculateRectSelection(Stroke selectStroke) {
    if (selectStroke.points.isEmpty) return;

    final bounds = _getStrokeBounds(selectStroke);

    final selectedStrokes = <Stroke>[];
    final selectedTextNodes = <TextNode>[];
    final selectedImageNodes = <ImageNode>[];
    final selectedDocumentNodes = <DocumentNode>[];

    double minX = double.infinity,
        minY = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity;

    void includePointInBounds(Offset p) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    for (var layer in layersNotifier.value) {
      if (!layer.isVisible || layer.isLocked) continue;

      for (var stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        final strokeBounds = _getStrokeBounds(stroke);
        if (bounds.overlaps(strokeBounds)) {
          selectedStrokes.add(stroke);
          includePointInBounds(strokeBounds.topLeft);
          includePointInBounds(strokeBounds.bottomRight);
        }
      }

      for (var text in layer.textNodes) {
        final textRect = getNodeBounds(text);
        if (bounds.overlaps(textRect) ||
            bounds.contains(textRect.center) ||
            bounds.contains(text.position)) {
          selectedTextNodes.add(text);
          includePointInBounds(textRect.topLeft);
          includePointInBounds(textRect.bottomRight);
        }
      }

      for (var image in layer.imageNodes) {
        final imageRect = getNodeBounds(image);
        if (bounds.overlaps(imageRect) ||
            bounds.contains(imageRect.center) ||
            bounds.contains(image.position)) {
          selectedImageNodes.add(image);
          includePointInBounds(imageRect.topLeft);
          includePointInBounds(imageRect.bottomRight);
        }
      }

      for (var doc in layer.documentNodes) {
        final docRect = getNodeBounds(doc);
        if (bounds.overlaps(docRect) ||
            bounds.contains(docRect.center) ||
            bounds.contains(doc.position)) {
          selectedDocumentNodes.add(doc);
          includePointInBounds(docRect.topLeft);
          includePointInBounds(docRect.bottomRight);
        }
      }
    }

    if (selectedStrokes.isEmpty &&
        selectedTextNodes.isEmpty &&
        selectedImageNodes.isEmpty &&
        selectedDocumentNodes.isEmpty) {
      selectionNotifier.value = CanvasSelection();
      return;
    }

    selectionNotifier.value = CanvasSelection(
      strokes: selectedStrokes,
      textNodes: selectedTextNodes,
      imageNodes: selectedImageNodes,
      documentNodes: selectedDocumentNodes,
      boundingBox: Rect.fromLTRB(minX, minY, maxX, maxY).inflate(10),
    );
  }

  void _calculateLassoSelection(Stroke lassoStroke) {
    final polygon = lassoStroke.points.map((p) => p.point).toList();
    if (polygon.length < 3) return;

    final selectedStrokes = <Stroke>[];
    final selectedTextNodes = <TextNode>[];
    final selectedImageNodes = <ImageNode>[];
    final selectedDocumentNodes = <DocumentNode>[];

    double minX = double.infinity,
        minY = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity;

    void includePointInBounds(Offset p) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    for (var layer in layersNotifier.value) {
      if (!layer.isVisible || layer.isLocked) continue;

      for (var stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        final bounds = _getStrokeBounds(stroke);
        bool anyPointInLasso = false;
        for (var p in stroke.points) {
          if (_isPointInPolygon(p.point, polygon)) {
            anyPointInLasso = true;
            break;
          }
        }
        if (anyPointInLasso || _isPointInPolygon(bounds.center, polygon)) {
          selectedStrokes.add(stroke);
          includePointInBounds(bounds.topLeft);
          includePointInBounds(bounds.bottomRight);
        }
      }

      for (var text in layer.textNodes) {
        final textRect = getNodeBounds(text);
        if (_isPointInPolygon(textRect.center, polygon) ||
            _isPointInPolygon(textRect.topLeft, polygon) ||
            _isPointInPolygon(textRect.bottomRight, polygon)) {
          selectedTextNodes.add(text);
          includePointInBounds(textRect.topLeft);
          includePointInBounds(textRect.bottomRight);
        }
      }

      for (var image in layer.imageNodes) {
        final imageRect = getNodeBounds(image);
        if (_isPointInPolygon(imageRect.center, polygon) ||
            _isPointInPolygon(imageRect.topLeft, polygon) ||
            _isPointInPolygon(imageRect.bottomRight, polygon)) {
          selectedImageNodes.add(image);
          includePointInBounds(imageRect.topLeft);
          includePointInBounds(imageRect.bottomRight);
        }
      }

      for (var doc in layer.documentNodes) {
        final docRect = getNodeBounds(doc);
        if (_isPointInPolygon(docRect.center, polygon) ||
            _isPointInPolygon(docRect.topLeft, polygon) ||
            _isPointInPolygon(docRect.bottomRight, polygon)) {
          selectedDocumentNodes.add(doc);
          includePointInBounds(docRect.topLeft);
          includePointInBounds(docRect.bottomRight);
        }
      }
    }

    if (selectedStrokes.isEmpty &&
        selectedTextNodes.isEmpty &&
        selectedImageNodes.isEmpty &&
        selectedDocumentNodes.isEmpty) {
      selectionNotifier.value = CanvasSelection();
      return;
    }

    selectionNotifier.value = CanvasSelection(
      strokes: selectedStrokes,
      textNodes: selectedTextNodes,
      imageNodes: selectedImageNodes,
      documentNodes: selectedDocumentNodes,
      boundingBox: Rect.fromLTRB(minX, minY, maxX, maxY).inflate(10),
    );
  }

  Rect _getStrokeBounds(Stroke stroke) {
    if (stroke.points.isEmpty) return Rect.zero;
    
    double minX = double.infinity,
        minY = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity;
        
    final pointsToCheck = stroke.isInkPen ? stroke.outlinePolygon : stroke.points.map((p)=>p.point).toList();
    
    for (var p in pointsToCheck) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool isInside = false;
    int i = 0, j = polygon.length - 1;
    for (i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx <
              (polygon[j].dx - polygon[i].dx) *
                      (point.dy - polygon[i].dy) /
                      (polygon[j].dy - polygon[i].dy) +
                  polygon[i].dx) {
        isInside = !isInside;
      }
      j = i;
    }
    return isInside;
  }

  Future<void> exportToPng() async {
    // 1. Calculate global bounding box across all layers
    double minX = double.infinity,
        minY = double.infinity,
        maxX = -double.infinity,
        maxY = -double.infinity;

    void expandBounds(Offset p) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    for (var layer in layersNotifier.value) {
      if (!layer.isVisible) continue;
      for (var stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        final bounds = _getStrokeBounds(stroke);
        expandBounds(bounds.topLeft);
        expandBounds(bounds.bottomRight);
      }
      for (var text in layer.textNodes) {
        final bounds = getNodeBounds(text);
        expandBounds(bounds.topLeft);
        expandBounds(bounds.bottomRight);
      }
      for (var image in layer.imageNodes) {
        final bounds = getNodeBounds(image);
        expandBounds(bounds.topLeft);
        expandBounds(bounds.bottomRight);
      }
    }

    if (minX == double.infinity) return; // Empty canvas

    // Add padding
    minX -= 50;
    minY -= 50;
    maxX += 50;
    maxY += 50;

    final width = (maxX - minX).ceil();
    final height = (maxY - minY).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    // Draw background
    final bgPaint = Paint()..color = AppTheme.background;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      bgPaint,
    );

    // Translate canvas so top-left of bounds is at (0,0)
    canvas.translate(-minX, -minY);

    // Render from bottom layer to top layer
    for (int i = 0; i < layersNotifier.value.length; i++) {
      final layer = layersNotifier.value[i];
      if (!layer.isVisible) continue;

      // Draw Strokes
      for (final stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        final paint = Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill;

        if (stroke.isPixelEraser) {
          paint.blendMode = BlendMode.clear;
        }

        canvas.drawPath(stroke.path, paint);
      }

      // Draw Text Nodes
      for (final textNode in layer.textNodes) {
        final paragraphBuilder =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  textAlign: TextAlign.left,
                  fontSize: 24, // Assuming default size for MVP
                ),
              )
              ..pushStyle(ui.TextStyle(color: textNode.color))
              ..addText(textNode.text);

        final paragraph = paragraphBuilder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
        canvas.drawParagraph(paragraph, textNode.position);
      }

      // We skip images for now to avoid the async decoding overhead,
      // but they can be added later!
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      try {
        final dir = await getDownloadsDirectory();
        if (dir != null) {
          final file = File(
            '${dir.path}\\horizon_export_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await file.writeAsBytes(byteData.buffer.asUint8List());
        }
      } catch (e) {
        debugPrint('Failed to export: $e');
      }
    }
  }

  void _eraseStrokeAtPoint(Offset point) {
    bool changed = false;

    // Erase from top layer to bottom
    for (int l = layersNotifier.value.length - 1; l >= 0; l--) {
      final layer = layersNotifier.value[l];
      if (!layer.isVisible || layer.isLocked) continue;

      final currentStrokes = List<Stroke>.from(layer.strokes);

      for (int i = currentStrokes.length - 1; i >= 0; i--) {
        final stroke = currentStrokes[i];
        if (stroke.isPixelEraser) continue;

        for (final strokePoint in stroke.points) {
          if ((strokePoint.point - point).distance < 20.0) {
            currentStrokes.removeAt(i);
            layer.strokes = currentStrokes;
            changed = true;
            break;
          }
        }
        if (changed) break;
      }
      if (changed) break;
    }

    if (changed) {
      saveSnapshot();
      _forceLayersUpdate();
    }
  }

  // Scene/Bookmark Management
  void addScene({
    required String name,
    required double x,
    required double y,
    required double scale,
    required String noteId,
    required WorkspaceController workspace,
  }) {
    final newScene = CanvasScene(
      id: 'scene-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      x: x,
      y: y,
      scale: scale,
    );
    scenesNotifier.value = [...scenesNotifier.value, newScene];
    saveScenes(noteId, workspace);
  }

  void deleteScene(String id, String noteId, WorkspaceController workspace) {
    scenesNotifier.value = scenesNotifier.value.where((s) => s.id != id).toList();
    saveScenes(noteId, workspace);
  }

  void renameScene(String id, String newName, String noteId, WorkspaceController workspace) {
    scenesNotifier.value = scenesNotifier.value.map((s) {
      if (s.id == id) {
        s.name = newName;
      }
      return s;
    }).toList();
    saveScenes(noteId, workspace);
  }

  void saveScenes(String noteId, WorkspaceController workspace) {
    final maps = scenesNotifier.value.map((s) => s.toMap()).toList();
    final index = workspace.notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final note = workspace.notes[index];
      note.scenes = maps;
      workspace.saveNoteCanvas(noteId, layersNotifier.value);
    }
  }

  void clear() {
    saveSnapshot();
    layersNotifier.value = [
      CanvasLayer(
        id: 'layer-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Layer 1',
      ),
    ];
    activeLayerIndexNotifier.value = 0;
    selectionNotifier.value = CanvasSelection();
    activeStrokeNotifier.end();
  }

  @override
  void dispose() {
    layersNotifier.dispose();
    activeLayerIndexNotifier.dispose();
    scenesNotifier.dispose();
    activeStrokeNotifier.dispose();
    selectionNotifier.dispose();
    selectionDragOffsetNotifier.dispose();
    backgroundVariantNotifier.dispose();
    backgroundMaskNotifier.dispose();
    super.dispose();
  }

  void saveSnapshot() {
    undoStack.add(CanvasStateSnapshot.fromCurrent(this));
    if (undoStack.length > 50) {
      undoStack.removeAt(0); // Limit undo history
    }
    redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (undoStack.isEmpty) return;

    redoStack.add(CanvasStateSnapshot.fromCurrent(this));
    final snapshot = undoStack.removeLast();
    _restoreSnapshot(snapshot);
  }

  void redo() {
    if (redoStack.isEmpty) return;

    undoStack.add(CanvasStateSnapshot.fromCurrent(this));
    final snapshot = redoStack.removeLast();
    _restoreSnapshot(snapshot);
  }

  void _restoreSnapshot(CanvasStateSnapshot snapshot) {
    selectionNotifier.value = CanvasSelection();
    layersNotifier.value = snapshot.layers.map((l) => l.clone()).toList();
    if (activeLayerIndexNotifier.value >= layersNotifier.value.length) {
      activeLayerIndexNotifier.value = layersNotifier.value.length - 1;
    }
    notifyListeners();
  }

  void _forceLayersUpdate() {
    layersNotifier.value = List.from(layersNotifier.value);
    notifyListeners();
  }

  // Layer Management Methods
  void addLayer() {
    saveSnapshot();

    int highestNum = 0;
    for (final layer in layersNotifier.value) {
      if (layer.name.startsWith('Layer ')) {
        final numPart = layer.name.substring(6);
        final num = int.tryParse(numPart);
        if (num != null && num > highestNum) {
          highestNum = num;
        }
      }
    }

    final newLayer = CanvasLayer(
      id: 'layer-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Layer ${highestNum + 1}',
    );
    final currentLayers = List<CanvasLayer>.from(layersNotifier.value);
    final insertIndex = activeLayerIndexNotifier.value + 1;
    currentLayers.insert(insertIndex, newLayer);
    layersNotifier.value = currentLayers;
    activeLayerIndexNotifier.value = insertIndex;
  }

  void renameLayer(int index, String newName) {
    if (index >= 0 && index < layersNotifier.value.length) {
      saveSnapshot();
      final currentLayers = List<CanvasLayer>.from(layersNotifier.value);
      currentLayers[index].name = newName;
      layersNotifier.value = currentLayers;
      notifyListeners();
    }
  }

  void removeLayer(int index) {
    if (layersNotifier.value.length <= 1) {
      return; // Must have at least one layer
    }
    saveSnapshot();
    final layers = List<CanvasLayer>.from(layersNotifier.value);
    layers.removeAt(index);
    layersNotifier.value = layers;

    if (activeLayerIndexNotifier.value >= layers.length) {
      activeLayerIndexNotifier.value = layers.length - 1;
    }
  }

  void toggleLayerVisibility(int index) {
    saveSnapshot();
    layersNotifier.value[index].isVisible =
        !layersNotifier.value[index].isVisible;
    _forceLayersUpdate();
  }

  // ---------------------------------------------------------------------------
  // Logic Handlers (Moved from UI for Architecture strictness)
  // ---------------------------------------------------------------------------
  Future<void> pickImageAndPlace(Offset position) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      saveSnapshot();

      final String path = result.files.single.path!;

      // Decode image dimensions to maintain aspect ratio
      double displayWidth = 300.0;
      double displayHeight = 300.0;
      try {
        final File file = File(path);
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();

        final double imgWidth = frame.image.width.toDouble();
        final double imgHeight = frame.image.height.toDouble();

        if (imgWidth > 0 && imgHeight > 0) {
          displayWidth = imgWidth;
          displayHeight = imgHeight;
          if (displayWidth > 300 || displayHeight > 300) {
            if (displayWidth > displayHeight) {
              displayHeight = displayHeight * (300 / displayWidth);
              displayWidth = 300;
            } else {
              displayWidth = displayWidth * (300 / displayHeight);
              displayHeight = 300;
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to decode image dimensions: $e');
      }

      final newNode = ImageNode(
        id: 'img-${DateTime.now().millisecondsSinceEpoch}',
        filePath: path,
        position: position,
        width: displayWidth,
        height: displayHeight,
      );
      final layer = activeLayer;
      layer.imageNodes = [...layer.imageNodes, newNode];
      layersNotifier.value = List.from(layersNotifier.value);
      setTool(DrawingTool.select);
      selectNode(newNode);
    }
  }

  Future<void> placeDroppedImage(String path, Offset position) async {
    saveSnapshot();

    double displayWidth = 300.0;
    double displayHeight = 300.0;
    try {
      final File file = File(path);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      final double imgWidth = frame.image.width.toDouble();
      final double imgHeight = frame.image.height.toDouble();

      if (imgWidth > 0 && imgHeight > 0) {
        displayWidth = imgWidth;
        displayHeight = imgHeight;
        if (displayWidth > 300 || displayHeight > 300) {
          if (displayWidth > displayHeight) {
            displayHeight = displayHeight * (300 / displayWidth);
            displayWidth = 300;
          } else {
            displayWidth = displayWidth * (300 / displayHeight);
            displayHeight = 300;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to decode dropped image dimensions: $e');
    }

    final newNode = ImageNode(
      id: 'img-${DateTime.now().millisecondsSinceEpoch}',
      filePath: path,
      position: position,
      width: displayWidth,
      height: displayHeight,
    );
    final layer = activeLayer;
    layer.imageNodes = [...layer.imageNodes, newNode];
    layersNotifier.value = List.from(layersNotifier.value);
    setTool(DrawingTool.select);
    selectNode(newNode);
  }

  void handleZoom(
    Offset localPosition,
    double zoomFactor,
    TransformationController controller,
    String canvasType,
  ) {
    final matrix = controller.value.clone();
    
    final double currentScale = matrix.getMaxScaleOnAxis();
    final double targetScale = currentScale * zoomFactor;
    
    double effectiveZoom = zoomFactor;
    if (targetScale < 0.1) {
      effectiveZoom = 0.1 / currentScale;
    } else if (targetScale > 10.0) {
      effectiveZoom = 10.0 / currentScale;
    }

    final Matrix4 scaleTransform = Matrix4.identity()
      ..leftTranslate(localPosition.dx, localPosition.dy)
      ..scale(effectiveZoom)
      ..leftTranslate(-localPosition.dx, -localPosition.dy);
      
    final Matrix4 newMatrix = scaleTransform.multiplied(matrix);

    if (canvasType == 'limited_infinite') {
      double dx = newMatrix.getTranslation().x;
      double dy = newMatrix.getTranslation().y;
      if (dx > 0) dx = 0;
      if (dy > 0) dy = 0;
      newMatrix.setTranslationRaw(dx, dy, newMatrix.getTranslation().z);
    }

    controller.value = newMatrix;
  }
}

class ActiveStrokeNotifier extends ChangeNotifier {
  Stroke? stroke;

  void start(Stroke s) {
    stroke = s;
    notifyListeners();
  }

  void update(Offset point, double pressure) {
    stroke?.points.add(StrokePoint(point, pressure));
    notifyListeners();
  }

  void end() {
    stroke = null;
    notifyListeners();
  }
}
