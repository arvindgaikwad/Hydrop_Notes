import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../models/canvas_objects.dart';
import '../controllers/canvas_controller.dart';
import '../theme/hydrop_theme.dart';

class TextNodeWidget extends StatefulWidget {
  final TextNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(String) onTextChanged;
  final VoidCallback onDelete;
  final bool forceEditOnTap;
  final bool autofocus;
  final VoidCallback? onPanStart;
  final void Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback onStyleChanged;
  final CanvasController canvasController;

  const TextNodeWidget({
    super.key,
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.onTextChanged,
    required this.onDelete,
    required this.onStyleChanged,
    required this.canvasController,
    this.forceEditOnTap = false,
    this.autofocus = false,
    this.onPanStart,
    this.onPanUpdate,
  });

  @override
  State<TextNodeWidget> createState() => _TextNodeWidgetState();
}

class _TextNodeWidgetState extends State<TextNodeWidget> {
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
  void didUpdateWidget(TextNodeWidget oldWidget) {
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _isEditing
                        ? ht.surface.withValues(alpha: 0.8)
                        : Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isEditing)
                        Transform.translate(
                          offset: const Offset(0, -60), // Float above the text
                          child: ht.applyBackdrop(
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ht.surface,
                                borderRadius: BorderRadius.circular(ht.radiusXl),
                                border: Border.fromBorderSide(ht.borderThin),
                                boxShadow: ht.shadowSmall,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.format_bold, size: 20),
                                    color: widget.node.isBold
                                        ? ht.primary
                                        : ht.iconDefault,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        widget.node.isBold = !widget.node.isBold;
                                      });
                                      widget.onStyleChanged();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.format_italic, size: 20),
                                    color: widget.node.isItalic
                                        ? ht.primary
                                        : ht.iconDefault,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        widget.node.isItalic =
                                            !widget.node.isItalic;
                                      });
                                      widget.onStyleChanged();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.format_underlined,
                                      size: 20,
                                    ),
                                    color: widget.node.isUnderline
                                        ? ht.primary
                                        : ht.iconDefault,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        widget.node.isUnderline =
                                            !widget.node.isUnderline;
                                      });
                                      widget.onStyleChanged();
                                    },
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    color: ht.divider,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      widget.node.alignmentIndex == 0
                                          ? Icons.format_align_left
                                          : widget.node.alignmentIndex == 1
                                          ? Icons.format_align_center
                                          : Icons.format_align_right,
                                      size: 20,
                                    ),
                                    color: ht.iconDefault,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        widget.node.alignmentIndex =
                                            (widget.node.alignmentIndex + 1) % 3;
                                      });
                                      widget.onStyleChanged();
                                    },
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    color: ht.divider,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    color: ht.iconDefault,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        widget.node.fontSize =
                                            (widget.node.fontSize - 2).clamp(
                                              12.0,
                                              72.0,
                                            );
                                      });
                                      widget.onStyleChanged();
                                    },
                                  ),
                                  Text(
                                    widget.node.fontSize.toInt().toString(),
                                    style: GoogleFonts.getFont(
                                      ht.fontFamily,
                                      fontSize: 14,
                                      color: ht.textPrimary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    color: ht.iconDefault,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      if (!mounted) return;
                                      setState(() {
                                        widget.node.fontSize =
                                            (widget.node.fontSize + 2).clamp(
                                              12.0,
                                              72.0,
                                            );
                                      });
                                      widget.onStyleChanged();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            borderRadius: BorderRadius.circular(ht.radiusXl),
                          ),
                        ),
                      _isEditing
                          ? IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: 100, // Minimum width so it's not squished
                                  maxWidth: MediaQuery.sizeOf(context).width * 0.8, // Prevent overflow
                                ),
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  textAlign: widget.node.alignmentIndex == 0
                                      ? TextAlign.left
                                      : widget.node.alignmentIndex == 1
                                      ? TextAlign.center
                                      : TextAlign.right,
                                  style: GoogleFonts.getFont(
                                    ht.fontFamily,
                                    fontSize: widget.node.fontSize,
                                    color: widget.node.color,
                                    fontWeight: widget.node.isBold
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontStyle: widget.node.isItalic
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    decoration: widget.node.isUnderline
                                        ? TextDecoration.underline
                                        : TextDecoration.none,
                                    height: 1.2,
                                  ),
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    hintText: 'Type something...',
                                    hintStyle: GoogleFonts.getFont(
                                      ht.fontFamily,
                                      color: ht.textDisabled,
                                      fontSize: widget.node.fontSize,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    // Let intrinsic width handle resizing naturally
                                  },
                                  onSubmitted: (_) => _finishEditing(),
                                ),
                              ),
                            )
                          : IntrinsicWidth(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: 100,
                                  maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    widget.node.text.isEmpty
                                        ? "Double tap to edit"
                                        : widget.node.text,
                                    textAlign: widget.node.alignmentIndex == 0
                                        ? TextAlign.left
                                        : widget.node.alignmentIndex == 1
                                        ? TextAlign.center
                                        : TextAlign.right,
                                    style: GoogleFonts.getFont(
                                      ht.fontFamily,
                                      fontSize: widget.node.fontSize,
                                      color: widget.node.color,
                                      fontWeight: widget.node.isBold
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontStyle: widget.node.isItalic
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      decoration: widget.node.isUnderline
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
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
