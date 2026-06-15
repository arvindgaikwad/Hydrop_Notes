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

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _canvasController,
      builder: (context, _) {
        final isDrawing = _canvasController.currentTool != DrawingTool.pan;
        return Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              // High-performance zooming/panning background grid
              if (widget.note.canvasType == 'infinite' || widget.note.canvasType == 'limited_infinite')
                ListenableBuilder(
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
              Positioned(
                right: 20,
                top: 20,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: HydropTheme.of(context).toolbarDecoration,
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
                        IconButton(
                          icon: const Icon(Icons.layers_outlined),
                          tooltip: 'Layers',
                          color: _showLayersPanel
                              ? HydropTheme.of(context).primary
                              : HydropTheme.of(context).iconDefault,
                          onPressed: () {
                            setState(() {
                              _showLayersPanel = !_showLayersPanel;
                              if (_showLayersPanel) _showScenesPanel = false;
                            });
                          },
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
                              ? HydropTheme.of(context).iconActive
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
                              ? HydropTheme.of(context).iconActive
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
              ),

              // Drawing Toolbar
              DrawingToolbar(controller: _canvasController),

              // Layers Panel
              if (_showLayersPanel)
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
              if (_showScenesPanel)
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

              // Floating Slideshow Controls Overlay
              if (_presentationMode && _canvasController.scenesNotifier.value.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Center(
                    child: SafeArea(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: HydropTheme.of(context).toolbarDecoration,
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
                  ),
                ),

              // Minimap
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
              Positioned(
                left: 20,
                bottom: 20,
                child: SafeArea(
                  child: ValueListenableBuilder<Matrix4>(
                    valueListenable: _transformationController,
                    builder: (context, matrix, _) {
                      final scale = matrix.getMaxScaleOnAxis();
                      final percentage = (scale * 100).round();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: HydropTheme.of(context).toolbarDecoration,
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            color: HydropTheme.of(context).textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
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
                      child: Container(
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
                                  await ExportController.exportToImage(context, _canvasController.layersNotifier.value, cropRect: rect, fileName: _canvasController.pendingExportNameNotifier.value);
                                } else {
                                  await ExportController.exportToPdf(_canvasController.layersNotifier.value, canvasType: widget.note.canvasType, cropRect: rect, fileName: _canvasController.pendingExportNameNotifier.value);
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
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String selectedFormat = 'png';
        String selectedRegion = 'full';
        String fileName = 'horizon_export';

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: HydropTheme.of(context).surface,
              title: Text('Export Canvas', style: TextStyle(color: HydropTheme.of(context).textPrimary)),
              content: Column(
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
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('PNG Image'),
                        selected: selectedFormat == 'png',
                        onSelected: (val) => setStateDialog(() => selectedFormat = 'png'),
                        selectedColor: HydropTheme.of(context).primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('PDF Document'),
                        selected: selectedFormat == 'pdf',
                        onSelected: (val) => setStateDialog(() => selectedFormat = 'pdf'),
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
                ],
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
                        await ExportController.exportToImage(context, _canvasController.layersNotifier.value, fileName: fileName);
                      } else {
                        await ExportController.exportToPdf(_canvasController.layersNotifier.value, canvasType: widget.note.canvasType, fileName: fileName);
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
}
