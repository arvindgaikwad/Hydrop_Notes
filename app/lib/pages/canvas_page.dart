// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../controllers/workspace_controller.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/export_controller.dart';
import 'hybrid_canvas/canvas_interface.dart';
import '../widgets/drawing_toolbar.dart';
import '../widgets/layers_panel.dart';
import '../widgets/scenes_panel.dart';
import '../widgets/minimap.dart';
import '../widgets/canvas_background_pattern.dart';
import '../theme/hydrop_theme.dart';

import 'package:flutter/services.dart';
import '../models/workspace.dart';
import '../models/canvas_objects.dart';

class CanvasPage extends StatefulWidget {
  final WorkspaceController workspace;
  final NoteDocument note;

  const CanvasPage({super.key, required this.workspace, required this.note});

  @override
  State<CanvasPage> createState() => _CanvasPageState();
}

class _CanvasPageState extends State<CanvasPage> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final CanvasController _canvasController = CanvasController();
  bool _showLayersPanel = false;
  bool _showScenesPanel = false;
  bool _presentationMode = false;
  int _currentPresentationIndex = 0;
  bool _initializedMobile = false;

  late AnimationController _cameraAnimationController;
  Animation<Matrix4>? _cameraAnimation;

  @override
  void initState() {
    super.initState();
    // Load existing items from the note
    if (widget.note.layers.isEmpty) {
      widget.note.layers = [
        CanvasLayer(
          id: 'layer-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Layer 1',
        ),
      ];
    }
    _canvasController.layersNotifier.value = List.from(widget.note.layers);

    // Load scenes from the note document
    _canvasController.scenesNotifier.value = widget.note.scenes
        .map((s) => CanvasScene.fromMap(s as Map))
        .toList();

    // Save items whenever they change
    _canvasController.layersNotifier.addListener(_saveCanvas);

    // Restore undo/redo stacks
    _canvasController.undoStack.addAll(
      widget.note.undoStack.cast<CanvasStateSnapshot>(),
    );
    _canvasController.redoStack.addAll(
      widget.note.redoStack.cast<CanvasStateSnapshot>(),
    );

    // Camera animation controller setup
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(CanvasPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      // Save old note state
      oldWidget.note.undoStack = List.from(_canvasController.undoStack);
      oldWidget.note.redoStack = List.from(_canvasController.redoStack);

      // Load new note state
      if (widget.note.layers.isEmpty) {
        widget.note.layers = [
          CanvasLayer(
            id: 'layer-${DateTime.now().millisecondsSinceEpoch}',
            name: 'Layer 1',
          ),
        ];
      }
      _canvasController.layersNotifier.removeListener(_saveCanvas);
      _canvasController.layersNotifier.value = List.from(widget.note.layers);
      _canvasController.layersNotifier.addListener(_saveCanvas);

      // Load new scenes
      _canvasController.scenesNotifier.value = widget.note.scenes
          .map((s) => CanvasScene.fromMap(s as Map))
          .toList();

      _canvasController.undoStack.clear();
      _canvasController.redoStack.clear();
      _canvasController.undoStack.addAll(
        widget.note.undoStack.cast<CanvasStateSnapshot>(),
      );
      _canvasController.redoStack.addAll(
        widget.note.redoStack.cast<CanvasStateSnapshot>(),
      );

      _canvasController.activeLayerIndexNotifier.value = 0;
      _canvasController.selectionNotifier.value = CanvasSelection();

      // Reset presentation/scenes UI states
      _showScenesPanel = false;
      _presentationMode = false;
      _currentPresentationIndex = 0;
    }
  }

  void _saveCanvas() {
    widget.workspace.saveNoteCanvas(
      widget.note.id,
      _canvasController.layersNotifier.value,
    );
  }

  void _animateToScene(CanvasScene scene) {
    final targetMatrix = Matrix4.identity()
      ..leftTranslate(scene.x, scene.y)
      ..scale(scene.scale);

    _cameraAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _cameraAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    _cameraAnimationController.addListener(_onCameraAnimationUpdate);
    _cameraAnimationController.forward(from: 0.0).then((_) {
      _cameraAnimationController.removeListener(_onCameraAnimationUpdate);
    });
  }

  void _onCameraAnimationUpdate() {
    if (_cameraAnimation != null) {
      _transformationController.value = _cameraAnimation!.value;
    }
  }

  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    // Save undo/redo stacks to the transient note document
    widget.note.undoStack = List.from(_canvasController.undoStack);
    widget.note.redoStack = List.from(_canvasController.redoStack);

    _transformationController.dispose();
    _cameraAnimationController.dispose();
    _canvasController.layersNotifier.dispose();
    _canvasController.activeLayerIndexNotifier.dispose();
    _canvasController.activeStrokeNotifier.dispose();
    _canvasController.selectionNotifier.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed) {
        if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _canvasController.redo();
          } else {
            _canvasController.undo();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      }

      // If a text field or another focus node has primary focus, don't steal keys like "b", "e", "delete" etc.
      if (!node.hasPrimaryFocus) {
        return KeyEventResult.ignored;
      }

      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyB:
          _canvasController.setTool(DrawingTool.inkPen);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyE:
          _canvasController.setTool(DrawingTool.pixelEraser);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyV:
          _canvasController.setTool(DrawingTool.select);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyL:
          _canvasController.setTool(DrawingTool.lasso);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyT:
          _canvasController.setTool(DrawingTool.text);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyP:
          _canvasController.setTool(DrawingTool.pan);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.delete:
          _canvasController.deleteSelection();
          return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: ListenableBuilder(
        listenable: _canvasController,
        builder: (context, _) {
        final isMobile = MediaQuery.sizeOf(context).width < 600;
        if (isMobile && !_initializedMobile) {
          _initializedMobile = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _canvasController.setTool(DrawingTool.pan);
          });
        }
        final isDrawing = _canvasController.currentTool != DrawingTool.pan;
        return Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // High-performance zooming/panning background grid
              if (widget.note.canvasType == 'infinite' || widget.note.canvasType == 'limited_infinite')
                RepaintBoundary(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      _canvasController.backgroundVariantNotifier,
                      _canvasController.backgroundMaskNotifier,
                    ]),
                    builder: (context, _) {
                      return CanvasBackgroundPattern(
                        variant: _canvasController.backgroundVariantNotifier.value,
                        mask: _canvasController.backgroundMaskNotifier.value,
                        transformationController: _transformationController,
                        fill: HydropTheme.of(context).primary.withValues(alpha: 0.1),
                        isLimitedBounds: widget.note.canvasType == 'limited_infinite',
                      );
                    },
                  ),
                ),

              ExcludeSemantics(
                child: RepaintBoundary(
                  child: HybridCanvasWidget.create(
                    canvasController: _canvasController,
                    isDrawing: isDrawing,
                    transformationController: _transformationController,
                    canvasType: widget.note.canvasType,
                  ),
                ),
              ),

              // Export & Layers Buttons Overlay
              if (!isMobile)
                Positioned(
                  right: 20,
                  top: 20,
                  child: SafeArea(
                    child: HydropTheme.of(context).applyBackdrop(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        decoration: HydropTheme.of(context).toolbarDecoration,
                        child: IconTheme(
                          data: IconThemeData(weight: 300, size: 24, color: HydropTheme.of(context).iconDefault),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.file_download_outlined),
                                tooltip: 'Export',
                                color: HydropTheme.of(context).iconDefault,
                                onPressed: () {
                                  _showExportDialog(context);
                                },
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                color: HydropTheme.of(context).divider,
                              ),
                              PopupMenuButton<CanvasBackgroundVariant>(
                                icon: const Icon(Icons.grid_on_rounded),
                                tooltip: 'Background Pattern',
                                color: HydropTheme.of(context).surface,
                                onSelected: (variant) {
                                  _canvasController.backgroundVariantNotifier.value = variant;
                                  _canvasController.backgroundMaskNotifier.value = CanvasBackgroundMask.none;
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.none,
                                    child: Text('None'),
                                  ),
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.dots,
                                    child: Text('Dots'),
                                  ),
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.grid,
                                    child: Text('Grid'),
                                  ),
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.diagonalStripes,
                                    child: Text('Diagonal Stripes'),
                                  ),
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.horizontalLines,
                                    child: Text('Horizontal Lines'),
                                  ),
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.verticalLines,
                                    child: Text('Vertical Lines'),
                                  ),
                                  const PopupMenuItem(
                                    value: CanvasBackgroundVariant.checkerboard,
                                    child: Text('Checkerboard'),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.bookmarks_outlined),
                                tooltip: 'Scenes',
                                color: _showScenesPanel
                                    ? HydropTheme.of(context).primary
                                    : HydropTheme.of(context).iconDefault,
                                onPressed: () {
                                  setState(() {
                                    _showScenesPanel = !_showScenesPanel;
                                    if (_showScenesPanel) {
                                      _showLayersPanel = false;
                                    }
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.layers_outlined),
                                tooltip: 'Layers',
                                color: _showLayersPanel
                                    ? HydropTheme.of(context).primary
                                    : HydropTheme.of(context).iconDefault,
                                onPressed: () {
                                  setState(() {
                                    _showLayersPanel = !_showLayersPanel;
                                    if (_showLayersPanel) {
                                      _showScenesPanel = false;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(HydropTheme.of(context).radiusXl),
                    ),
                  ),
                ),

              // Drawing Toolbar
              if (!isMobile) DrawingToolbar(controller: _canvasController),

              // Layers Panel
              if (_showLayersPanel && !isMobile)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: SafeArea(
                    child: LayersPanel(
                      controller: _canvasController,
                      onClose: () => setState(() => _showLayersPanel = false),
                    ),
                  ),
                ),

              // Scenes Panel
              if (_showScenesPanel && !isMobile)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: SafeArea(
                    child: ScenesPanel(
                      controller: _canvasController,
                      transformationController: _transformationController,
                      workspace: widget.workspace,
                      noteId: widget.note.id,
                      onClose: () => setState(() => _showScenesPanel = false),
                      onSceneSelected: (scene) {
                        final idx = _canvasController.scenesNotifier.value.indexOf(scene);
                        if (idx != -1) {
                          _currentPresentationIndex = idx;
                        }
                        _animateToScene(scene);
                      },
                      onPlaySlideshow: () {
                        if (_canvasController.scenesNotifier.value.isNotEmpty) {
                          setState(() {
                            _showScenesPanel = false;
                            _presentationMode = true;
                            _currentPresentationIndex = 0;
                          });
                          _animateToScene(_canvasController.scenesNotifier.value[0]);
                        }
                      },
                    ),
                  ),
                ),

              // === MOBILE UI OVERLAYS ===
              if (isMobile)
                Positioned(
                  top: 16,
                  left: 16,
                  child: SafeArea(
                    child: HydropTheme.of(context).applyBackdrop(
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: HydropTheme.of(context).toolbarDecoration,
                        child: IconTheme(
                          data: IconThemeData(weight: 300, size: 24, color: HydropTheme.of(context).iconDefault),
                          child: IconButton(
                            icon: const Icon(Icons.layers_outlined),
                            color: HydropTheme.of(context).iconDefault,
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  height: MediaQuery.sizeOf(context).height * 0.7,
                                  decoration: BoxDecoration(
                                    color: HydropTheme.of(context).surface,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: LayersPanel(
                                      controller: _canvasController,
                                      onClose: () => Navigator.pop(ctx),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(HydropTheme.of(context).radiusXl),
                    ),
                  ),
                ),
              if (isMobile)
                Positioned(
                  top: 16,
                  right: 16,
                  child: SafeArea(
                    child: HydropTheme.of(context).applyBackdrop(
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: HydropTheme.of(context).toolbarDecoration,
                        child: IconTheme(
                          data: IconThemeData(weight: 300, size: 24, color: HydropTheme.of(context).iconDefault),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.undo_outlined),
                                color: HydropTheme.of(context).iconDefault,
                                onPressed: _canvasController.undoStack.isNotEmpty ? _canvasController.undo : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.redo_outlined),
                                color: HydropTheme.of(context).iconDefault,
                                onPressed: _canvasController.redoStack.isNotEmpty ? _canvasController.redo : null,
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                color: HydropTheme.of(context).divider,
                              ),
                              IconButton(
                                icon: const Icon(Icons.ios_share_outlined),
                                color: HydropTheme.of(context).iconDefault,
                                onPressed: () {
                                  _showExportDialog(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      borderRadius: BorderRadius.circular(HydropTheme.of(context).radiusXl),
                    ),
                  ),
                ),
              if (isMobile)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: FloatingActionButton(
                      backgroundColor: HydropTheme.of(context).primary,
                      elevation: 4,
                      child: Icon(
                        _canvasController.currentTool == DrawingTool.pan ? Icons.pan_tool :
                        _canvasController.currentTool == DrawingTool.pixelEraser ? Icons.auto_fix_high :
                        _canvasController.currentTool == DrawingTool.text ? Icons.text_fields :
                        _canvasController.currentTool == DrawingTool.image ? Icons.image :
                        _canvasController.currentTool == DrawingTool.connector ? Icons.timeline :
                        _canvasController.currentTool == DrawingTool.normalPen ? Icons.edit :
                        Icons.brush,
                        color: HydropTheme.of(context).surface
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => Container(
                            decoration: BoxDecoration(
                              color: HydropTheme.of(context).surface,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  _mobileToolButton(ctx, Icons.pan_tool, 'Pan', DrawingTool.pan),
                                  _mobileToolButton(ctx, Icons.brush, 'Ink', DrawingTool.inkPen),
                                  _mobileToolButton(ctx, Icons.edit, 'Pen', DrawingTool.normalPen),
                                  _mobileToolButton(ctx, Icons.auto_fix_high, 'Erase', DrawingTool.pixelEraser),
                                  _mobileToolButton(ctx, Icons.text_fields, 'Text', DrawingTool.text),
                                  _mobileToolButton(ctx, Icons.image, 'Image', DrawingTool.image),
                                  _mobileToolButton(ctx, Icons.timeline, 'Link', DrawingTool.connector),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Floating Slideshow Controls Overlay
              if (_presentationMode && _canvasController.scenesNotifier.value.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: SafeArea(
                      child: HydropTheme.of(context).applyBackdrop(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: HydropTheme.of(context).toolbarDecoration,
                          child: IconTheme(
                            data: IconThemeData(weight: 300, size: 24, color: HydropTheme.of(context).iconDefault),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_rounded),
                                  tooltip: 'Previous Scene',
                                  color: _currentPresentationIndex > 0
                                      ? HydropTheme.of(context).iconDefault
                                      : HydropTheme.of(context).textDisabled,
                                  onPressed: _currentPresentationIndex > 0
                                      ? () {
                                          setState(() {
                                            _currentPresentationIndex--;
                                          });
                                          _animateToScene(
                                            _canvasController.scenesNotifier.value[_currentPresentationIndex],
                                          );
                                        }
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_currentPresentationIndex + 1} of ${_canvasController.scenesNotifier.value.length}: ${_canvasController.scenesNotifier.value[_currentPresentationIndex].name}',
                                  style: TextStyle(
                                    color: HydropTheme.of(context).textPrimary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                                  tooltip: 'Next Scene',
                                  color: _currentPresentationIndex <
                                          _canvasController.scenesNotifier.value.length - 1
                                      ? HydropTheme.of(context).iconDefault
                                      : HydropTheme.of(context).textDisabled,
                                  onPressed: _currentPresentationIndex <
                                          _canvasController.scenesNotifier.value.length - 1
                                      ? () {
                                          setState(() {
                                            _currentPresentationIndex++;
                                          });
                                          _animateToScene(
                                            _canvasController.scenesNotifier.value[_currentPresentationIndex],
                                          );
                                        }
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: HydropTheme.of(context).divider,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Exit Slideshow',
                                  onPressed: () {
                                    setState(() {
                                      _presentationMode = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(HydropTheme.of(context).radiusXl),
                      ),
                    ),
                  ),
                ),

              // Minimap
              if (!isMobile)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SafeArea(
                    child: Minimap(
                      canvasController: _canvasController,
                      transformationController: _transformationController,
                    ),
                  ),
                ),

              // Zoom Percentage
              if (!isMobile)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: SafeArea(
                    child: ValueListenableBuilder<Matrix4>(
                      valueListenable: _transformationController,
                      builder: (context, matrix, _) {
                        final scale = matrix.getMaxScaleOnAxis();
                        final percentage = (scale * 100).round();
                        
                        void zoom(double factor) {
                          final size = MediaQuery.of(context).size;
                          final center = Offset(size.width / 2, size.height / 2);
                          final Matrix4 newMatrix = Matrix4.identity()
                            ..translate(center.dx, center.dy)
                            ..scale(factor)
                            ..translate(-center.dx, -center.dy)
                            ..multiply(matrix);
                          _transformationController.value = newMatrix;
                        }

                        final ht = HydropTheme.of(context);
                        return ht.applyBackdrop(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: ht.toolbarDecoration,
                            child: IconTheme(
                              data: IconThemeData(weight: 300, size: 20, color: ht.textSecondary),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => zoom(1.0 / scale), // Reset to 100%
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$percentage%',
                                        style: TextStyle(
                                          color: ht.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 24,
                                    width: 1,
                                    color: ht.divider,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    color: ht.textSecondary,
                                    onPressed: () => zoom(1 / 1.2),
                                    tooltip: 'Zoom Out',
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    splashRadius: 22,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    color: ht.textSecondary,
                                    onPressed: () => zoom(1.2),
                                    tooltip: 'Zoom In',
                                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                    splashRadius: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(ht.radiusXl),
                        );
                      },
                    ),
                  ),
                ),

              // Export Frame Confirmation
              if (_canvasController.currentTool == DrawingTool.exportFrame)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 100,
                  child: Center(
                    child: SafeArea(
                      child: HydropTheme.of(context).applyBackdrop(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: HydropTheme.of(context).toolbarDecoration,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                label: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                                onPressed: () {
                                  setState(() {
                                    _canvasController.currentTool = DrawingTool.pan;
                                    _canvasController.exportFrameNotifier.value = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text('Confirm Export', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: HydropTheme.of(context).primary,
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  final format = _canvasController.pendingExportFormatNotifier.value;
                                  final rect = _canvasController.exportFrameNotifier.value;
                                  
                                  setState(() {
                                    _canvasController.setTool(DrawingTool.pan);
                                    _canvasController.exportFrameNotifier.value = null;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Exporting to $format...')),
                                  );

                                  if (format == 'png') {
                                    await ExportController.exportToImage(
                                      context, 
                                      _canvasController.layersNotifier.value, 
                                      cropRect: rect, 
                                      fileName: _canvasController.pendingExportNameNotifier.value,
                                      includeGrid: _canvasController.pendingExportIncludeGrid,
                                      transparentBackground: _canvasController.pendingExportTransparentBackground,
                                      backgroundVariant: _canvasController.backgroundVariantNotifier.value,
                                    );
                                  } else if (format == 'svg') {
                                    await ExportController.exportToSvg(
                                      context, 
                                      _canvasController.layersNotifier.value, 
                                      cropRect: rect, 
                                      fileName: _canvasController.pendingExportNameNotifier.value,
                                      includeGrid: _canvasController.pendingExportIncludeGrid,
                                      transparentBackground: _canvasController.pendingExportTransparentBackground,
                                      backgroundVariant: _canvasController.backgroundVariantNotifier.value,
                                    );
                                  } else {
                                    await ExportController.exportToPdf(
                                      _canvasController.layersNotifier.value, 
                                      canvasType: widget.note.canvasType, 
                                      cropRect: rect, 
                                      fileName: _canvasController.pendingExportNameNotifier.value,
                                      includeGrid: _canvasController.pendingExportIncludeGrid,
                                      transparentBackground: _canvasController.pendingExportTransparentBackground,
                                      backgroundVariant: _canvasController.backgroundVariantNotifier.value,
                                    );
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Export Complete!')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        borderRadius: BorderRadius.circular(HydropTheme.of(context).radiusXl),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String selectedFormat = 'png';
        String selectedRegion = 'full';
        String fileName = 'horizon_export';
        bool includeGrid = false;
        bool transparentBackground = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: HydropTheme.of(context).surface,
              title: Text('Export Canvas', style: TextStyle(color: HydropTheme.of(context).textPrimary)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File Name', style: TextStyle(color: HydropTheme.of(context).textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'horizon_export',
                        filled: true,
                        fillColor: HydropTheme.of(context).surfaceVariant,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        fileName = val.trim().isEmpty ? 'horizon_export' : val.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Format', style: TextStyle(color: HydropTheme.of(context).textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('PNG Image'),
                          selected: selectedFormat == 'png',
                          onSelected: (val) => setStateDialog(() => selectedFormat = 'png'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                        ChoiceChip(
                          label: const Text('PDF Document'),
                          selected: selectedFormat == 'pdf',
                          onSelected: (val) => setStateDialog(() => selectedFormat = 'pdf'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                        ChoiceChip(
                          label: const Text('SVG Vector'),
                          selected: selectedFormat == 'svg',
                          onSelected: (val) => setStateDialog(() => selectedFormat = 'svg'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Region', style: TextStyle(color: HydropTheme.of(context).textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Full Canvas (Auto)'),
                          selected: selectedRegion == 'full',
                          onSelected: (val) => setStateDialog(() => selectedRegion = 'full'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                        ChoiceChip(
                          label: const Text('A4 Frame'),
                          selected: selectedRegion == 'a4',
                          onSelected: (val) => setStateDialog(() => selectedRegion = 'a4'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                        ChoiceChip(
                          label: const Text('Long Form'),
                          selected: selectedRegion == 'long',
                          onSelected: (val) => setStateDialog(() => selectedRegion = 'long'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                        ChoiceChip(
                          label: const Text('Custom Region'),
                          selected: selectedRegion == 'custom',
                          onSelected: (val) => setStateDialog(() => selectedRegion = 'custom'),
                          selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Background Settings', style: TextStyle(color: HydropTheme.of(context).textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Include Grid/Pattern'),
                      value: includeGrid,
                      activeColor: HydropTheme.of(context).primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateDialog(() => includeGrid = val),
                    ),
                    SwitchListTile(
                      title: const Text('Transparent Background'),
                      value: transparentBackground,
                      activeColor: HydropTheme.of(context).primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setStateDialog(() => transparentBackground = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: TextStyle(color: HydropTheme.of(context).textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: HydropTheme.of(context).primary),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    
                    if (selectedRegion == 'full') {
                      // Immediate Export
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Exporting to $selectedFormat...')),
                      );
                      if (selectedFormat == 'png') {
                        await ExportController.exportToImage(
                          context, 
                          _canvasController.layersNotifier.value, 
                          fileName: fileName,
                          includeGrid: includeGrid,
                          transparentBackground: transparentBackground,
                          backgroundVariant: _canvasController.backgroundVariantNotifier.value,
                        );
                      } else if (selectedFormat == 'svg') {
                        await ExportController.exportToSvg(
                          context, 
                          _canvasController.layersNotifier.value, 
                          fileName: fileName,
                          includeGrid: includeGrid,
                          transparentBackground: transparentBackground,
                          backgroundVariant: _canvasController.backgroundVariantNotifier.value,
                        );
                      } else {
                        await ExportController.exportToPdf(
                          _canvasController.layersNotifier.value, 
                          canvasType: widget.note.canvasType, 
                          fileName: fileName,
                          includeGrid: includeGrid,
                          transparentBackground: transparentBackground,
                          backgroundVariant: _canvasController.backgroundVariantNotifier.value,
                        );
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export Complete!')),
                        );
                      }
                    } else {
                      // Enter Export Frame Mode
                      _canvasController.pendingExportFormatNotifier.value = selectedFormat;
                      _canvasController.pendingExportNameNotifier.value = fileName;
                      _canvasController.pendingExportIncludeGrid = includeGrid;
                      _canvasController.pendingExportTransparentBackground = transparentBackground;
                      
                      // Calculate initial rect size in viewport center
                      final center = _transformationController.toScene(
                        Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2)
                      );
                      
                      double width = 800;
                      double height = 600;
                      if (selectedRegion == 'a4') {
                        width = 800;
                        height = 1131; // 1:1.414 aspect
                      } else if (selectedRegion == 'long') {
                        width = 800;
                        height = 2400; // long scroll
                      }
                      
                      final initialRect = Rect.fromCenter(center: center, width: width, height: height);
                      
                      setState(() {
                        _canvasController.setTool(DrawingTool.exportFrame);
                        _canvasController.exportFrameNotifier.value = initialRect;
                      });
                    }
                  },
                  child: const Text('Continue', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _mobileToolButton(BuildContext context, IconData icon, String label, DrawingTool tool) {
    final ht = HydropTheme.of(context);
    final isSelected = _canvasController.currentTool == tool;
    return GestureDetector(
      onTap: () {
        _canvasController.setTool(tool);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? ht.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(ht.radiusLg),
          border: Border.all(color: isSelected ? ht.primary : Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? ht.iconActive : ht.iconDefault, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? ht.textPrimary : ht.textSecondary,
                fontWeight: isSelected ? ht.fontBold : ht.fontMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
