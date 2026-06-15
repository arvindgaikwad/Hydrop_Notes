import 'package:flutter/material.dart';
import '../controllers/canvas_controller.dart';
import '../controllers/workspace_controller.dart';
import '../models/canvas_objects.dart';
import '../theme/hydrop_theme.dart';

class ScenesPanel extends StatelessWidget {
  final CanvasController controller;
  final TransformationController transformationController;
  final WorkspaceController workspace;
  final String noteId;
  final ValueChanged<CanvasScene> onSceneSelected;
  final VoidCallback? onPlaySlideshow;
  final VoidCallback? onClose;

  const ScenesPanel({
    super.key,
    required this.controller,
    required this.transformationController,
    required this.workspace,
    required this.noteId,
    required this.onSceneSelected,
    this.onPlaySlideshow,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: ht.sidebarBackground,
        border: Border(left: ht.borderThin),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: ht.borderThin)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scenes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ht.sidebarText,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add_a_photo_outlined, color: ht.iconDefault),
                      onPressed: () => _addCurrentViewScene(context),
                      tooltip: 'Capture View',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.play_circle_outline_rounded, color: ht.iconDefault),
                      onPressed: onPlaySlideshow,
                      tooltip: 'Play Slideshow',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
                    if (onClose != null) ...[
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(Icons.close, color: ht.iconDefault),
                        onPressed: onClose,
                        tooltip: 'Close',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Scenes List
          Expanded(
            child: ValueListenableBuilder<List<CanvasScene>>(
              valueListenable: controller.scenesNotifier,
              builder: (context, scenes, _) {
                if (scenes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.landscape_outlined,
                            size: 40,
                            color: ht.textDisabled,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No scenes captured yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ht.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Zoom & pan somewhere and click the camera icon to save a view.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ht.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: scenes.length,
                  itemBuilder: (context, index) {
                    final scene = scenes[index];
                    return _SceneItem(
                      scene: scene,
                      index: index,
                      onTap: () => onSceneSelected(scene),
                      onDelete: () {
                        controller.deleteScene(scene.id, noteId, workspace);
                      },
                      onRename: (newName) {
                        controller.renameScene(scene.id, newName, noteId, workspace);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addCurrentViewScene(BuildContext context) {
    final ht = HydropTheme.of(context);
    final matrix = transformationController.value;
    final translation = matrix.getTranslation();
    final scale = matrix.getMaxScaleOnAxis();

    final textController = TextEditingController(
      text: 'Scene ${controller.scenesNotifier.value.length + 1}',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ht.surface,
          title: Text(
            'Capture Scene',
            style: TextStyle(color: ht.textPrimary),
          ),
          content: TextField(
            controller: textController,
            style: TextStyle(color: ht.textPrimary),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: TextStyle(color: ht.textSecondary),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ht.divider),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ht.primary),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: ht.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  controller.addScene(
                    name: name,
                    x: translation.x,
                    y: translation.y,
                    scale: scale,
                    noteId: noteId,
                    workspace: workspace,
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Capture',
                style: TextStyle(color: ht.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SceneItem extends StatefulWidget {
  final CanvasScene scene;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _SceneItem({
    required this.scene,
    required this.index,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<_SceneItem> createState() => _SceneItemState();
}

class _SceneItemState extends State<_SceneItem> {
  bool _isEditing = false;
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.scene.name);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitRename();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SceneItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.name != widget.scene.name && !_isEditing) {
      _textController.text = widget.scene.name;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _textController.text = widget.scene.name;
    });
    _focusNode.requestFocus();
  }

  void _commitRename() {
    if (!_isEditing) return;
    setState(() {
      _isEditing = false;
    });
    final newName = _textController.text.trim();
    if (newName.isNotEmpty && newName != widget.scene.name) {
      widget.onRename(newName);
    } else {
      _textController.text = widget.scene.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: ht.borderThin),
        ),
        child: Row(
          children: [
            // Slide Number Badge
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ht.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ht.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Scene Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    SizedBox(
                      height: 24,
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          fontSize: 14,
                          color: ht.textPrimary,
                          fontWeight: ht.fontBold,
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(bottom: 8),
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _commitRename(),
                      ),
                    )
                  else
                    GestureDetector(
                      onDoubleTap: _startEditing,
                      child: Text(
                        widget.scene.name,
                        style: TextStyle(
                          fontWeight: ht.fontMedium,
                          color: ht.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    'Zoom: ${(widget.scene.scale * 100).round()}%',
                    style: TextStyle(fontSize: 10, color: ht.textSecondary),
                  ),
                ],
              ),
            ),

            // Rename Button
            IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
              iconSize: 18,
              color: _isEditing ? ht.primary : ht.iconDefault,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: _isEditing ? _commitRename : _startEditing,
            ),

            const SizedBox(width: 4),

            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 18,
              color: ht.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
