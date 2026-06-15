import 'package:flutter/material.dart';
import '../controllers/canvas_controller.dart';
import '../models/canvas_objects.dart';
import '../theme/hydrop_theme.dart';

class LayersPanel extends StatelessWidget {
  final CanvasController controller;
  final VoidCallback? onClose;

  const LayersPanel({super.key, required this.controller, this.onClose});

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
                  'Layers',
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
                      icon: Icon(Icons.add, color: ht.iconDefault),
                      onPressed: () => controller.addLayer(),
                      tooltip: 'Add Layer',
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

          // Layers List (Reversed so top layer is at top of list)
          Expanded(
            child: ValueListenableBuilder<List<CanvasLayer>>(
              valueListenable: controller.layersNotifier,
              builder: (context, layers, _) {
                return ValueListenableBuilder<int>(
                  valueListenable: controller.activeLayerIndexNotifier,
                  builder: (context, activeIndex, _) {
                    return ListView.builder(
                      itemCount: layers.length,
                      itemBuilder: (context, index) {
                        // Reverse index for display: top layer (highest index) shown first
                        final actualIndex = layers.length - 1 - index;
                        final layer = layers[actualIndex];
                        final isActive = actualIndex == activeIndex;

                        return _LayerItem(
                          layer: layer,
                          isActive: isActive,
                          onTap: () {
                            controller.activeLayerIndexNotifier.value =
                                actualIndex;
                          },
                          onToggleVisibility: () {
                            controller.toggleLayerVisibility(actualIndex);
                          },
                          onDelete: () {
                            controller.removeLayer(actualIndex);
                          },
                          onRename: (newName) {
                            controller.renameLayer(actualIndex, newName);
                          },
                        );
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
}

class _LayerItem extends StatefulWidget {
  final CanvasLayer layer;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _LayerItem({
    required this.layer,
    required this.isActive,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onDelete,
    required this.onRename,
  });

  @override
  State<_LayerItem> createState() => _LayerItemState();
}

class _LayerItemState extends State<_LayerItem> {
  bool _isEditing = false;
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.layer.name);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitRename();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _LayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layer.name != widget.layer.name && !_isEditing) {
      _textController.text = widget.layer.name;
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
      _textController.text = widget.layer.name;
    });
    _focusNode.requestFocus();
  }

  void _commitRename() {
    if (!_isEditing) return;
    setState(() {
      _isEditing = false;
    });
    final newName = _textController.text.trim();
    if (newName.isNotEmpty && newName != widget.layer.name) {
      widget.onRename(newName);
    } else {
      _textController.text = widget.layer.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isActive
              ? ht.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: ht.borderThin,
            left: BorderSide(
              color: widget.isActive ? ht.primary : Colors.transparent,
              width: 3.0,
            ),
          ),
        ),
        child: Row(
          children: [
            // Visibility Toggle
            GestureDetector(
              onTap: widget.onToggleVisibility,
              child: Icon(
                widget.layer.isVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                size: 20,
                color: widget.layer.isVisible
                    ? ht.iconDefault
                    : ht.textDisabled,
              ),
            ),
            const SizedBox(width: 12),

            // Layer Name & Info
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
                        widget.layer.name,
                        style: TextStyle(
                          fontWeight: widget.isActive
                              ? ht.fontBold
                              : ht.fontMedium,
                          color: ht.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.layer.strokes.length} strokes, ${widget.layer.imageNodes.length} images',
                    style: TextStyle(fontSize: 10, color: ht.textSecondary),
                  ),
                ],
              ),
            ),

            // Edit Button
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
