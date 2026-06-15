import 'package:flutter/material.dart';
import '../theme/hydrop_theme.dart';
import '../controllers/canvas_controller.dart';

class BoundingBoxOverlay extends StatefulWidget {
  final Rect initialRect;
  final double initialRotation;
  final double initialScale;
  final CanvasController canvasController;
  final Function(
    Offset translateDelta,
    double scaleMultiplier,
    double rotationDelta,
  )
  onTransformUpdate;
  final VoidCallback onTransformEnd;
  final VoidCallback? onDoubleTap;

  const BoundingBoxOverlay({
    super.key,
    required this.initialRect,
    this.initialRotation = 0.0,
    this.initialScale = 1.0,
    required this.canvasController,
    required this.onTransformUpdate,
    required this.onTransformEnd,
    this.onDoubleTap,
  });

  @override
  State<BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<BoundingBoxOverlay> {
  final GlobalKey _rotatedBoxKey = GlobalKey();

  // --- Core state ---
  late Offset _currentPosition; // top-left in canvas space (unrotated)
  late double _currentWidth;
  late double _currentHeight;
  late double _currentRotation;
  late double _currentScale;

  late Offset _lastReportedPosition;
  late double _lastReportedScale;
  late double _lastReportedRotation;

  bool _isRotating = false;
  bool _isResizing = false;
  bool _isDragging = false;

  bool get _isTransforming => _isRotating || _isResizing || _isDragging;

  // --- Rotation state ---
  Offset? _boxCenterGlobal;
  double _rotationOffset = 0.0;

  // --- Resize state ---
  // We track the anchor corner's CANVAS position and recompute _currentPosition
  // after each scale change so that the anchor corner stays pinned.
  Offset _resizeAnchorCanvas = Offset.zero; // anchor corner in canvas space
  Offset? _resizeAnchorGlobal; // anchor corner in global/screen space
  Alignment _resizeAlignment = Alignment.center;
  Offset? _resizeInitialDiagonal; // initial handle→anchor vector (global)
  double _resizeInitialDistance = 1.0;
  double _resizeInitialScale = 1.0;

  @override
  void initState() {
    super.initState();
    _syncWithNode();
  }

  @override
  void didUpdateWidget(BoundingBoxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isTransforming) return;

    if (oldWidget.initialRect != widget.initialRect ||
        oldWidget.initialRotation != widget.initialRotation ||
        oldWidget.initialScale != widget.initialScale) {
      _syncWithNode();
    }
  }

  void _syncWithNode() {
    _currentPosition = widget.initialRect.topLeft;
    _currentWidth = widget.initialRect.width;
    _currentHeight = widget.initialRect.height;
    _currentRotation = widget.initialRotation;
    _currentScale = widget.initialScale;

    _lastReportedPosition = _currentPosition;
    _lastReportedScale = _currentScale;
    _lastReportedRotation = _currentRotation;
  }

  // ---------- Helpers for rotated corner positions in canvas space ----------

  /// Returns the canvas-space position of a corner identified by [alignment],
  /// given the current _currentPosition, _currentScale, and _currentRotation.
  Offset _cornerInCanvas(Alignment alignment) {
    final Rect unrotatedBounds = Rect.fromLTWH(
      _currentPosition.dx,
      _currentPosition.dy,
      _currentWidth * _currentScale,
      _currentHeight * _currentScale,
    );
    return widget.canvasController.getRotatedCornerCanvasPosition(
      unrotatedBounds,
      _currentRotation,
      alignment,
    );
  }

  /// Given a desired anchor corner position in canvas space [anchorCanvas]
  /// and the alignment of that corner [alignment], computes what _currentPosition
  /// must be so that the anchor stays at that canvas position.
  Offset _positionForAnchor(
    Alignment alignment,
    Offset anchorCanvas,
    double scale,
  ) {
    final double w = _currentWidth * scale;
    final double h = _currentHeight * scale;
    return widget.canvasController.getUnrotatedTopLeftForRotatedAnchor(
      anchorCanvas,
      w,
      h,
      _currentRotation,
      alignment,
    );
  }

  // ---------- Transform reporting ----------

  void _reportTransform() {
    final double actualWidth = _currentWidth * _currentScale;
    final double actualHeight = _currentHeight * _currentScale;
    final Offset currentCenter =
        _currentPosition + Offset(actualWidth / 2, actualHeight / 2);

    final double lastWidth = _currentWidth * _lastReportedScale;
    final double lastHeight = _currentHeight * _lastReportedScale;
    final Offset lastCenter =
        _lastReportedPosition + Offset(lastWidth / 2, lastHeight / 2);

    Offset translateDelta = currentCenter - lastCenter;
    double scaleMultiplier = _currentScale / _lastReportedScale;
    double rotationDelta = _currentRotation - _lastReportedRotation;

    widget.onTransformUpdate(translateDelta, scaleMultiplier, rotationDelta);

    _lastReportedPosition = _currentPosition;
    _lastReportedScale = _currentScale;
    _lastReportedRotation = _currentRotation;
  }

  void _commitTransform() {
    widget.onTransformEnd();
  }

  // ---------- Resize ----------

  void _onResizeStart(Alignment alignment, DragStartDetails details) {
    setState(() {
      _isResizing = true;
    });
    _resizeAlignment = alignment;

    // The anchor is the OPPOSITE corner
    final Alignment anchorAlignment = Alignment(-alignment.x, -alignment.y);
    _resizeAnchorCanvas = _cornerInCanvas(anchorAlignment);

    // Record initial diagonal vector (in global/screen space) for dot-product projection
    final RenderBox renderBox =
        _rotatedBoxKey.currentContext!.findRenderObject() as RenderBox;
    final double actualWidth = _currentWidth * _currentScale;
    final double actualHeight = _currentHeight * _currentScale;

    final Offset anchorLocal = Offset(
      12 + actualWidth / 2 - alignment.x * actualWidth / 2,
      40 + actualHeight / 2 - alignment.y * actualHeight / 2,
    );
    final Offset handleLocal = Offset(
      12 + actualWidth / 2 + alignment.x * actualWidth / 2,
      40 + actualHeight / 2 + alignment.y * actualHeight / 2,
    );
    _resizeAnchorGlobal = renderBox.localToGlobal(anchorLocal);
    final Offset handleGlobal = renderBox.localToGlobal(handleLocal);

    _resizeInitialDiagonal = handleGlobal - _resizeAnchorGlobal!;
    _resizeInitialDistance = _resizeInitialDiagonal!.distance;
    if (_resizeInitialDistance < 1.0) _resizeInitialDistance = 1.0;

    _resizeInitialScale = _currentScale;
  }

  void _onResizeUpdate(DragUpdateDetails details) {
    if (_resizeInitialDiagonal == null || _resizeAnchorGlobal == null) return;

    final Alignment alignment = _resizeAlignment;
    final Offset handleGlobal = _resizeAnchorGlobal! + _resizeInitialDiagonal!;

    double scaleMultiplier = widget.canvasController
        .calculateResizeScaleMultiplier(
          handleGlobal,
          _resizeAnchorGlobal!,
          details.globalPosition,
        );

    setState(() {
      final double newScale = _resizeInitialScale * scaleMultiplier;
      _currentScale = newScale;

      // Recompute position so the anchor corner stays fixed in canvas space
      final Alignment anchorAlignment = Alignment(-alignment.x, -alignment.y);
      _currentPosition = _positionForAnchor(
        anchorAlignment,
        _resizeAnchorCanvas,
        newScale,
      );

      _reportTransform();
    });
  }

  // ---------- Build handles ----------

  MouseCursor _getCursorForAlignment(Alignment alignment, double rotation) {
    return widget.canvasController.getCursorForAlignment(alignment, rotation);
  }

  Widget _buildSquareHandle(
    double actualWidth,
    double actualHeight,
    Alignment alignment,
  ) {
    final double handleX = 12 + actualWidth / 2 + alignment.x * actualWidth / 2;
    final double handleY =
        40 + actualHeight / 2 + alignment.y * actualHeight / 2;

    return Positioned(
      left: handleX - 5,
      top: handleY - 5,
      width: 10,
      height: 10,
      child: MouseRegion(
        cursor: _getCursorForAlignment(alignment, _currentRotation),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _onResizeStart(alignment, details),
          onPanUpdate: _onResizeUpdate,
          onPanEnd: (_) {
            setState(() {
              _isResizing = false;
            });
            _commitTransform();
          },
          onPanCancel: () {
            setState(() {
              _isResizing = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: HydropTheme.of(context).primary,
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    final double actualWidth = _currentWidth * _currentScale;
    final double actualHeight = _currentHeight * _currentScale;

    return Positioned(
      left: _currentPosition.dx - 12,
      top: _currentPosition.dy - 40,
      child: Transform.rotate(
        angle: _currentRotation,
        origin: const Offset(0, 14),
        child: SizedBox(
          key: _rotatedBoxKey,
          width: actualWidth + 24,
          height: actualHeight + 52,
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Bounding Box Frame (drag to move)
                Positioned(
                  left: 12,
                  top: 40,
                  width: actualWidth,
                  height: actualHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (_) {
                      setState(() {
                        _isDragging = true;
                      });
                    },
                    onPanUpdate: (details) {
                      // details.delta is in the local (rotated) coordinate space.
                      // Delegate to CanvasController to convert it back to canvas space.
                      final Offset canvasDelta = widget.canvasController
                          .translateLocalDeltaToCanvasSpace(
                            details.delta,
                            _currentRotation,
                          );

                      setState(() {
                        _currentPosition += canvasDelta;
                      });
                      _reportTransform();
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isDragging = false;
                      });
                      _commitTransform();
                    },
                    onPanCancel: () {
                      setState(() {
                        _isDragging = false;
                      });
                    },
                    onDoubleTap: widget.onDoubleTap,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: ht.primary, width: 2),
                        color: ht.primary.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),

                // 8-Point Resize Handles
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.topLeft,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.topCenter,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.topRight,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.centerLeft,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.centerRight,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.bottomLeft,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.bottomCenter,
                ),
                _buildSquareHandle(
                  actualWidth,
                  actualHeight,
                  Alignment.bottomRight,
                ),

                // Connecting line for rotation handle
                Positioned(
                  left: (actualWidth / 2) + 11,
                  top: 24,
                  width: 2,
                  height: 16,
                  child: Container(color: ht.primary),
                ),

                // Rotation Handle
                Positioned(
                  left: (actualWidth / 2),
                  top: 0,
                  width: 24,
                  height: 24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (details) {
                      final RenderBox renderBox =
                          _rotatedBoxKey.currentContext!.findRenderObject()
                              as RenderBox;
                      final Offset localCenter = Offset(
                        12 + actualWidth / 2,
                        40 + actualHeight / 2,
                      );
                      _boxCenterGlobal = renderBox.localToGlobal(localCenter);
                      final double angle = widget.canvasController
                          .calculateRotationAngle(
                            _boxCenterGlobal!,
                            details.globalPosition,
                          );
                      _rotationOffset = _currentRotation - angle;
                      setState(() {
                        _isRotating = true;
                      });
                    },
                    onPanUpdate: (details) {
                      if (_boxCenterGlobal == null) return;
                      final double angle = widget.canvasController
                          .calculateRotationAngle(
                            _boxCenterGlobal!,
                            details.globalPosition,
                          );
                      setState(() {
                        _currentRotation = angle + _rotationOffset;
                        _reportTransform();
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isRotating = false;
                      });
                      _commitTransform();
                    },
                    onPanCancel: () {
                      setState(() {
                        _isRotating = false;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: ht.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.rotate_right,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Rotation Degree Indicator
                if (_isRotating)
                  Positioned(
                    left: (actualWidth / 2) - 20,
                    top: -28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ht.textPrimary,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${((_currentRotation * 180 / 3.1415926535897932) % 360).round()}°',
                          style: TextStyle(
                            color: ht.background,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
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
