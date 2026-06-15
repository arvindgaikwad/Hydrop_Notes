import 'package:flutter/material.dart';
import '../theme/hydrop_theme.dart';
import '../models/workspace.dart';
import '../models/stroke.dart';

class ThumbnailPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Rect boundingBox;

  ThumbnailPainter(this.strokes, this.boundingBox);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(-boundingBox.left, -boundingBox.top);
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.fill;
      if (stroke.isPixelEraser) {
        paint.blendMode = BlendMode.clear;
      }
      canvas.drawPath(stroke.path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ThumbnailPainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.boundingBox != boundingBox;
  }
}

class EditableFolderCard extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Function(String) onRename;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onMove;
  final bool isTrashed;

  const EditableFolderCard({
    super.key,
    required this.title,
    required this.onTap,
    this.onDoubleTap,
    required this.onRename,
    required this.onDelete,
    this.onRestore,
    this.onMove,
    this.isTrashed = false,
  });

  @override
  State<EditableFolderCard> createState() => _EditableFolderCardState();
}

class _EditableFolderCardState extends State<EditableFolderCard> {
  DateTime? _lastTapTime;
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.title);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _submit();
      }
    });
  }

  void _submit() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    final newTitle = _controller.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.title) {
      widget.onRename(newTitle);
    } else {
      _controller.text = widget.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    return InkWell(
      onTap: _isEditing
          ? null
          : () {
              final now = DateTime.now();
              widget.onTap();

              if (widget.onDoubleTap != null) {
                if (_lastTapTime != null &&
                    now.difference(_lastTapTime!) <
                        const Duration(milliseconds: 300)) {
                  widget.onDoubleTap!();
                  _lastTapTime = null;
                } else {
                  _lastTapTime = now;
                }
              }
            },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: ht.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ht.divider),
        ),
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16, right: 8),
        child: Row(
          children: [
            Icon(Icons.folder, color: ht.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: ht.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _submit(),
                    )
                  : Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: ht.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black54),
              onSelected: (val) {
                if (val == 'rename') {
                  setState(() {
                    _isEditing = true;
                    _focusNode.requestFocus();
                  });
                } else if (val == 'delete') {
                  widget.onDelete();
                } else if (val == 'restore') {
                  widget.onRestore?.call();
                } else if (val == 'move') {
                  widget.onMove?.call();
                }
              },
              itemBuilder: (context) {
                if (widget.isTrashed) {
                  return [
                    const PopupMenuItem(
                      value: 'restore',
                      child: Text('Restore'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete Permanently',
                        style: TextStyle(color: ht.error),
                      ),
                    ),
                  ];
                }
                return [
                  const PopupMenuItem(value: 'move', child: Text('Move')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Move to Trash',
                      style: TextStyle(color: ht.error),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EditableNoteCard extends StatefulWidget {
  final NoteDocument note;
  final VoidCallback onTap;
  final Function(String) onRename;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onMove;
  final bool isTrashed;

  const EditableNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    this.onRestore,
    this.onMove,
    this.isTrashed = false,
  });

  @override
  State<EditableNoteCard> createState() => _EditableNoteCardState();
}

class _EditableNoteCardState extends State<EditableNoteCard> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.title);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _submit();
      }
    });
  }

  void _submit() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    final newTitle = _controller.text.trim();
    if (newTitle.isNotEmpty && newTitle != widget.note.title) {
      widget.onRename(newTitle);
    } else {
      _controller.text = widget.note.title;
    }
  }

  Rect _calculateBoundingBox() {
    Rect? bbox;
    for (var layer in widget.note.layers) {
      if (!layer.isVisible) continue;
      for (var stroke in layer.strokes) {
        if (stroke.points.isEmpty) continue;
        final pathBounds = stroke.path.getBounds();
        if (pathBounds.width == 0 && pathBounds.height == 0) continue;
        if (bbox == null) {
          bbox = pathBounds;
        } else {
          bbox = bbox.expandToInclude(pathBounds);
        }
      }
    }
    // Default size for empty notes
    if (bbox == null || bbox.width == 0 || bbox.height == 0) {
      return const Rect.fromLTWH(0, 0, 200, 150);
    }
    // Add some padding to the bounding box so strokes don't touch the edges
    return bbox.inflate(20);
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    final bbox = _calculateBoundingBox();
    final aspectRatio = (bbox.width / bbox.height).clamp(0.5, 2.0); // Keep reasonable bounds

    final allStrokes = widget.note.layers
        .where((l) => l.isVisible)
        .expand((l) => l.strokes)
        .toList();

    return InkWell(
      onTap: _isEditing ? null : widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: ht.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ht.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Title and Menu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isEditing)
                          TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: ht.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _submit(),
                          )
                        else
                          Text(
                            widget.note.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: ht.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}', // Dummy date for aesthetics
                          style: TextStyle(color: ht.sidebarTextSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black54),
                    padding: EdgeInsets.zero,
                    onSelected: (val) {
                      if (val == 'rename') {
                        setState(() {
                          _isEditing = true;
                          _focusNode.requestFocus();
                        });
                      } else if (val == 'delete') {
                        widget.onDelete();
                      } else if (val == 'restore') {
                        widget.onRestore?.call();
                      } else if (val == 'move') {
                        widget.onMove?.call();
                      }
                    },
                    itemBuilder: (context) {
                      if (widget.isTrashed) {
                        return [
                          const PopupMenuItem(
                            value: 'restore',
                            child: Text('Restore'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete Permanently',
                              style: TextStyle(color: ht.error),
                            ),
                          ),
                        ];
                      }
                      return [
                        const PopupMenuItem(value: 'move', child: Text('Move')),
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Move to Trash',
                            style: TextStyle(color: ht.error),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),
            
            // Preview Canvas Area
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 120,
                maxHeight: 250,
              ),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Container(
                  color: ht.background, // Slightly different color for the "canvas" area
                  child: allStrokes.isEmpty
                      ? Center(
                          child: Icon(Icons.edit_document, size: 48, color: ht.divider),
                        )
                      : ClipRect(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: bbox.width,
                              height: bbox.height,
                              child: CustomPaint(
                                painter: ThumbnailPainter(allStrokes, bbox),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
