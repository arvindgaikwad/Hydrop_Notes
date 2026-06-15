import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/canvas_objects.dart';
import '../controllers/canvas_controller.dart';
import '../theme/hydrop_theme.dart';

class DocumentNodeWidget extends StatefulWidget {
  final DocumentNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String) onTextChanged;
  final VoidCallback onDelete;
  final bool forceEditOnTap;
  final bool autofocus;
  final VoidCallback? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final CanvasController canvasController;

  const DocumentNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onTextChanged,
    required this.onDelete,
    required this.canvasController,
    this.forceEditOnTap = false,
    this.autofocus = false,
    this.onPanStart,
    this.onPanUpdate,
  });

  @override
  State<DocumentNodeWidget> createState() => _DocumentNodeWidgetState();
}

class _DocumentNodeWidgetState extends State<DocumentNodeWidget> {
  bool _isEditing = false;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.autofocus;
    _controller = TextEditingController(text: widget.node.text);
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _finishEditing() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    setState(() {
      _isEditing = false;
    });
    if (_controller.text.trim().isEmpty) {
      widget.onDelete();
    } else {
      widget.onTextChanged(_controller.text);
    }
  }

  @override
  void didUpdateWidget(DocumentNodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.text != oldWidget.node.text && !_isEditing) {
      _controller.text = widget.node.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);

    Offset visualPosition = widget.node.position;
    double visualScale = widget.node.scale;
    double visualRotation = widget.node.rotation;

    if (widget.isSelected &&
        widget.canvasController.isTransforming &&
        widget.canvasController.transformCenter != null) {
      final center = widget.canvasController.transformCenter!;
      final translate = widget.canvasController.pendingTranslate;
      final scale = widget.canvasController.pendingScale;
      final rotation = widget.canvasController.pendingRotation;

      final Offset nodeCenter = Offset(
        widget.node.position.dx + widget.node.width / 2,
        widget.node.position.dy + widget.node.height / 2,
      );

      double dx = nodeCenter.dx - center.dx;
      double dy = nodeCenter.dy - center.dy;

      dx *= scale;
      dy *= scale;

      if (rotation != 0.0) {
        final double s = math.sin(rotation);
        final double c = math.cos(rotation);
        final double nx = dx * c - dy * s;
        final double ny = dx * s + dy * c;
        dx = nx;
        dy = ny;
      }

      final Offset newCenter = Offset(
        center.dx + dx + translate.dx,
        center.dy + dy + translate.dy,
      );

      visualScale = widget.node.scale * scale;
      visualRotation = widget.node.rotation + rotation;
      visualPosition = Offset(
        newCenter.dx - widget.node.width / 2,
        newCenter.dy - widget.node.height / 2,
      );
    }

    return Positioned(
      left: visualPosition.dx,
      top: visualPosition.dy,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(visualRotation)
          ..multiply(
            Matrix4.diagonal3Values(visualScale, visualScale, 1.0),
          ),
        child: TapRegion(
          onTapOutside: (event) {
            if (_isEditing) {
              _finishEditing();
            }
          },
          child: GestureDetector(
            onTap: () {
              widget.onTap();
              if (widget.forceEditOnTap && !_isEditing) {
                setState(() {
                  _isEditing = true;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _focusNode.requestFocus();
                });
              }
            },
            onDoubleTap: () {
              setState(() {
                _isEditing = true;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _focusNode.requestFocus();
              });
            },
            onPanStart: (_) {
              if (!_isEditing) widget.onPanStart?.call();
            },
            onPanUpdate: (details) {
              if (!_isEditing) widget.onPanUpdate?.call(details);
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: widget.node.width,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ht.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected ? ht.primary : ht.divider,
                    width: widget.isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isEditing
                    ? TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: ht.textPrimary,
                          height: 1.5,
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: "Type '/' for commands...",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 16,
                            color: ht.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : Text(
                        widget.node.text.isEmpty
                            ? "Type '/' for commands..."
                            : widget.node.text,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: widget.node.text.isEmpty
                              ? ht.textPrimary.withValues(alpha: 0.5)
                              : ht.textPrimary,
                          height: 1.5,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
