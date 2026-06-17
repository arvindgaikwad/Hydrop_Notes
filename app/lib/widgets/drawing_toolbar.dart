import 'package:flutter/material.dart';
import '../controllers/canvas_controller.dart';
import 'color_picker.dart';
import '../theme/hydrop_theme.dart';
import 'export_dialog.dart';

class DrawingToolbar extends StatefulWidget {
  final CanvasController controller;

  const DrawingToolbar({super.key, required this.controller});

  @override
  State<DrawingToolbar> createState() => _DrawingToolbarState();
}

enum ToolbarDock { left, right, top, bottom }

class _DrawingToolbarState extends State<DrawingToolbar> {
  ToolbarDock _dock = ToolbarDock.left;
  final GlobalKey _colorButtonKey = GlobalKey();

  bool get _isVertical =>
      _dock == ToolbarDock.left || _dock == ToolbarDock.right;

  @override
  Widget build(BuildContext context) {
    Alignment alignment;
    switch (_dock) {
      case ToolbarDock.left:
        alignment = Alignment.centerLeft;
        break;
      case ToolbarDock.right:
        alignment = Alignment.centerRight;
        break;
      case ToolbarDock.top:
        alignment = Alignment.topCenter;
        break;
      case ToolbarDock.bottom:
        alignment = Alignment.bottomCenter;
        break;
    }

    return AnimatedAlign(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final ht = HydropTheme.of(context);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(ht.space8),
              decoration: ht.toolbarDecoration,
              child: _isVertical
                  ? _buildVerticalLayout(ht)
                  : _buildHorizontalLayout(ht),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(HydropTheme ht) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: _buildTools(ht)),
    );
  }

  Widget _buildHorizontalLayout(HydropTheme ht) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisSize: MainAxisSize.min, children: _buildTools(ht)),
    );
  }

  List<Widget> _buildTools(HydropTheme ht) {
    final c = widget.controller;
    bool showColors =
        c.currentTool == DrawingTool.inkPen ||
        c.currentTool == DrawingTool.normalPen ||
        c.currentTool == DrawingTool.tape ||
        c.currentTool == DrawingTool.connector;
    bool showSlider = showColors || c.currentTool == DrawingTool.pixelEraser;

    List<Widget> tools = [
      // Dock Handle
      PopupMenuButton<ToolbarDock>(
        icon: Icon(Icons.dock, color: ht.iconDefault),
        tooltip: 'Dock Toolbar',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ht.radiusLg),
        ),
        offset: const Offset(0, 40),
        onSelected: (dock) {
          setState(() => _dock = dock);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: ToolbarDock.left,
            child: ListTile(
              leading: Icon(Icons.align_horizontal_left),
              title: Text('Dock Left'),
            ),
          ),
          PopupMenuItem(
            value: ToolbarDock.right,
            child: ListTile(
              leading: Icon(Icons.align_horizontal_right),
              title: Text('Dock Right'),
            ),
          ),
          PopupMenuItem(
            value: ToolbarDock.top,
            child: ListTile(
              leading: Icon(Icons.align_vertical_top),
              title: Text('Dock Top'),
            ),
          ),
          PopupMenuItem(
            value: ToolbarDock.bottom,
            child: ListTile(
              leading: Icon(Icons.align_vertical_bottom),
              title: Text('Dock Bottom'),
            ),
          ),
        ],
      ),
      _spacer(ht),

      // Actions
      IconButton(
        icon: const Icon(Icons.undo),
        color: c.undoStack.isNotEmpty ? ht.iconActive : ht.textDisabled,
        onPressed: c.undoStack.isNotEmpty ? c.undo : null,
      ),
      IconButton(
        icon: const Icon(Icons.redo),
        color: c.redoStack.isNotEmpty ? ht.iconActive : ht.textDisabled,
        onPressed: c.redoStack.isNotEmpty ? c.redo : null,
      ),
      IconButton(
        icon: const Icon(Icons.ios_share),
        color: ht.iconDefault,
        tooltip: 'Export Note',
        onPressed: () {
          // Temporarily show the floating modal variant by default.
          // You can change `isSidePanel: true` to test the side panel variant.
          showDialog(
            context: context,
            barrierColor: Colors.black.withValues(alpha: 0.5),
            builder: (_) => const ExportOptionsPanel(isSidePanel: false),
          );
        },
      ),
      _divider(ht),

      // Tools
      _SelectFlyout(controller: c, isVertical: _isVertical, dock: _dock),
      _ToolButton(
        icon: Icons.edit,
        label: 'Normal Pen',
        isSelected: c.currentTool == DrawingTool.normalPen,
        onTap: () => c.setTool(DrawingTool.normalPen),
      ),
      _ToolButton(
        icon: Icons.brush,
        label: 'Ink Pen',
        isSelected: c.currentTool == DrawingTool.inkPen,
        onTap: () => c.setTool(DrawingTool.inkPen),
      ),
      _EraserFlyout(controller: c, isVertical: _isVertical, dock: _dock),
      _ToolButton(
        icon: Icons.text_fields,
        label: 'Text',
        isSelected: c.currentTool == DrawingTool.text,
        onTap: () => c.setTool(DrawingTool.text),
      ),
      _ToolButton(
        icon: Icons.article,
        label: 'Document',
        isSelected: c.currentTool == DrawingTool.document,
        onTap: () => c.setTool(DrawingTool.document),
      ),
      _ToolButton(
        icon: Icons.timeline,
        label: 'Connector',
        isSelected: c.currentTool == DrawingTool.connector,
        onTap: () => c.setTool(DrawingTool.connector),
      ),
      _ToolButton(
        icon: Icons.image,
        label: 'Image',
        isSelected: c.currentTool == DrawingTool.image,
        onTap: () => c.setTool(DrawingTool.image),
      ),
      _ToolButton(
        icon: Icons.pan_tool,
        label: 'Pan',
        isSelected: c.currentTool == DrawingTool.pan,
        onTap: () => c.setTool(DrawingTool.pan),
      ),
      _ToolButton(
        icon: Icons.visibility_off,
        label: 'Tape',
        isSelected: c.currentTool == DrawingTool.tape,
        onTap: () => c.setTool(DrawingTool.tape),
      ),
    ];

    if (showColors) {
      tools.add(_divider(ht));
      tools.add(
        IconButton(
          key: _colorButtonKey,
          icon: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: c.currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: ht.divider),
            ),
          ),
          onPressed: () {
            ColorDialOverlay.show(
              context: context,
              buttonKey: _colorButtonKey,
              dock: _dock,
              controller: c,
            );
          },
        ),
      );
    }

    if (showSlider) {
      tools.add(_spacer(ht));
      tools.add(
        RotatedBox(
          quarterTurns: _isVertical ? 3 : 0,
          child: SizedBox(
            width: 120,
            height: 36,
            child: Slider(
              value: c.currentWidth,
              min: 1.0,
              max: 20.0,
              activeColor: ht.primary,
              inactiveColor: ht.primary.withValues(alpha: 0.1),
              onChanged: (val) => c.setWidth(val),
            ),
          ),
        ),
      );
    }

    return tools;
  }

  Widget _spacer(HydropTheme ht) => SizedBox(
    width: _isVertical ? 0 : ht.space8,
    height: _isVertical ? ht.space8 : 0,
  );

  Widget _divider(HydropTheme ht) => Container(
    width: _isVertical ? ht.space24 : 1,
    height: _isVertical ? 1 : ht.space24,
    color: ht.divider,
    margin: EdgeInsets.symmetric(
      horizontal: _isVertical ? 0 : ht.space8,
      vertical: _isVertical ? ht.space8 : 0,
    ),
  );
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: isSelected
              ? BoxDecoration(
                  color: ht.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ht.radiusLg),
                  border: Border.all(color: ht.primary),
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(ht.radiusLg),
                  border: Border.all(color: Colors.transparent),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? ht.iconActive : ht.iconDefault,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected ? ht.textPrimary : ht.textSecondary,
                  fontWeight: isSelected ? ht.fontBold : ht.fontMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectFlyout extends StatefulWidget {
  final CanvasController controller;
  final bool isVertical;
  final ToolbarDock dock;

  const _SelectFlyout({
    required this.controller,
    required this.isVertical,
    required this.dock,
  });

  @override
  State<_SelectFlyout> createState() => _SelectFlyoutState();
}

class _SelectFlyoutState extends State<_SelectFlyout> {
  final GlobalKey _buttonKey = GlobalKey();
  final GlobalKey<_SelectFlyoutOverlayState> _overlayKey =
      GlobalKey<_SelectFlyoutOverlayState>();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _overlayKey.currentState?.closeWithAnimation();
    } else {
      final RenderBox renderBox =
          _buttonKey.currentContext!.findRenderObject() as RenderBox;
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) => _SelectFlyoutOverlay(
          key: _overlayKey,
          origin: position,
          size: size,
          dock: widget.dock,
          controller: widget.controller,
          onClose: () {
            _overlayEntry?.remove();
            setState(() {
              _overlayEntry = null;
            });
          },
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSelect = widget.controller.currentTool == DrawingTool.select;
    bool isLasso = widget.controller.currentTool == DrawingTool.lasso;
    bool isActive = isSelect || isLasso;

    return _ToolButton(
      key: _buttonKey,
      icon: Icons.pan_tool_alt,
      label: 'Select',
      isSelected: isActive,
      onTap: () {
        if (widget.controller.currentTool == DrawingTool.lasso) {
          widget.controller.setTool(DrawingTool.select);
        } else if (widget.controller.currentTool == DrawingTool.select) {
          _toggleMenu();
        } else {
          widget.controller.setTool(DrawingTool.select);
        }
      },
    );
  }
}

class _SelectFlyoutOverlay extends StatefulWidget {
  final Offset origin;
  final Size size;
  final ToolbarDock dock;
  final CanvasController controller;
  final VoidCallback onClose;

  const _SelectFlyoutOverlay({
    required Key key,
    required this.origin,
    required this.size,
    required this.dock,
    required this.controller,
    required this.onClose,
  }) : super(key: key);

  @override
  State<_SelectFlyoutOverlay> createState() => _SelectFlyoutOverlayState();
}

class _SelectFlyoutOverlayState extends State<_SelectFlyoutOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void closeWithAnimation() {
    if (_anim.isAnimating) return;
    _anim.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    double? left, right, top, bottom;
    bool isPanelHorizontal = false;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    switch (widget.dock) {
      case ToolbarDock.left:
        left = widget.origin.dx + widget.size.width + 8;
        top = widget.origin.dy;
        isPanelHorizontal = true;
        break;
      case ToolbarDock.right:
        right = (screenWidth - widget.origin.dx) + 8;
        top = widget.origin.dy;
        isPanelHorizontal = true;
        break;
      case ToolbarDock.top:
        left = widget.origin.dx;
        top = widget.origin.dy + widget.size.height + 8;
        isPanelHorizontal = false;
        break;
      case ToolbarDock.bottom:
        left = widget.origin.dx;
        bottom = (screenHeight - widget.origin.dy) + 8;
        isPanelHorizontal = false;
        break;
    }

    return GestureDetector(
      onTap: closeWithAnimation,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: ScaleTransition(
                scale: _expandAnimation,
                alignment: widget.dock == ToolbarDock.left
                    ? Alignment.centerLeft
                    : (widget.dock == ToolbarDock.right
                          ? Alignment.centerRight
                          : (widget.dock == ToolbarDock.top
                                ? Alignment.topCenter
                                : Alignment.bottomCenter)),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(24),
                  color: HydropTheme.of(
                    context,
                  ).surface.withValues(alpha: 0.95),
                  child: HydropTheme.of(context).applyBackdrop(
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: HydropTheme.of(context).divider,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          bool isSelect =
                              widget.controller.currentTool ==
                              DrawingTool.select;
                          bool isLasso =
                              widget.controller.currentTool ==
                              DrawingTool.lasso;
                          return isPanelHorizontal
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildPanelButtons(
                                    isSelect,
                                    isLasso,
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildPanelButtons(
                                    isSelect,
                                    isLasso,
                                  ),
                                );
                        },
                      ),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPanelButtons(bool isSelect, bool isLasso) {
    return [
      _ToolButton(
        icon: Icons.gesture,
        label: 'Lasso',
        isSelected: isLasso,
        onTap: () {
          widget.controller.setTool(DrawingTool.lasso);
          closeWithAnimation();
        },
      ),
    ];
  }
}

class _EraserFlyout extends StatefulWidget {
  final CanvasController controller;
  final bool isVertical;
  final ToolbarDock dock;

  const _EraserFlyout({
    required this.controller,
    required this.isVertical,
    required this.dock,
  });

  @override
  State<_EraserFlyout> createState() => _EraserFlyoutState();
}

class _EraserFlyoutState extends State<_EraserFlyout> {
  final GlobalKey _buttonKey = GlobalKey();
  final GlobalKey<_EraserFlyoutOverlayState> _overlayKey =
      GlobalKey<_EraserFlyoutOverlayState>();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _overlayKey.currentState?.closeWithAnimation();
    } else {
      final RenderBox renderBox =
          _buttonKey.currentContext!.findRenderObject() as RenderBox;
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;

      _overlayEntry = OverlayEntry(
        builder: (context) => _EraserFlyoutOverlay(
          key: _overlayKey,
          origin: position,
          size: size,
          dock: widget.dock,
          controller: widget.controller,
          onClose: () {
            _overlayEntry?.remove();
            setState(() {
              _overlayEntry = null;
            });
          },
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPixel = widget.controller.currentTool == DrawingTool.pixelEraser;
    bool isStroke = widget.controller.currentTool == DrawingTool.strokeEraser;
    bool isActive = isPixel || isStroke;

    return _ToolButton(
      key: _buttonKey,
      icon: Icons.auto_fix_high,
      label: 'Eraser',
      isSelected: isActive,
      onTap: () {
        if (widget.controller.currentTool == DrawingTool.strokeEraser) {
          widget.controller.setTool(DrawingTool.pixelEraser);
        } else if (widget.controller.currentTool == DrawingTool.pixelEraser) {
          _toggleMenu();
        } else {
          widget.controller.setTool(DrawingTool.pixelEraser);
        }
      },
    );
  }
}

class _EraserFlyoutOverlay extends StatefulWidget {
  final Offset origin;
  final Size size;
  final ToolbarDock dock;
  final CanvasController controller;
  final VoidCallback onClose;

  const _EraserFlyoutOverlay({
    required Key key,
    required this.origin,
    required this.size,
    required this.dock,
    required this.controller,
    required this.onClose,
  }) : super(key: key);

  @override
  State<_EraserFlyoutOverlay> createState() => _EraserFlyoutOverlayState();
}

class _EraserFlyoutOverlayState extends State<_EraserFlyoutOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _anim,
      curve: Curves.easeOutCubic,
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void closeWithAnimation() {
    if (_anim.isAnimating) return;
    _anim.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    double? left, right, top, bottom;
    bool isPanelHorizontal = false;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    switch (widget.dock) {
      case ToolbarDock.left:
        left = widget.origin.dx + widget.size.width + 8;
        top = widget.origin.dy;
        isPanelHorizontal = true;
        break;
      case ToolbarDock.right:
        right = (screenWidth - widget.origin.dx) + 8;
        top = widget.origin.dy;
        isPanelHorizontal = true;
        break;
      case ToolbarDock.top:
        left = widget.origin.dx;
        top = widget.origin.dy + widget.size.height + 8;
        isPanelHorizontal = false;
        break;
      case ToolbarDock.bottom:
        left = widget.origin.dx;
        bottom = (screenHeight - widget.origin.dy) + 8;
        isPanelHorizontal = false;
        break;
    }

    return GestureDetector(
      onTap: closeWithAnimation,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: ScaleTransition(
                scale: _expandAnimation,
                alignment: widget.dock == ToolbarDock.left
                    ? Alignment.centerLeft
                    : (widget.dock == ToolbarDock.right
                          ? Alignment.centerRight
                          : (widget.dock == ToolbarDock.top
                                ? Alignment.topCenter
                                : Alignment.bottomCenter)),
                child: Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: HydropTheme.of(context).applyBackdrop(
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: HydropTheme.of(context).toolbarDecoration,
                      child: ListenableBuilder(
                        listenable: widget.controller,
                        builder: (context, _) {
                          bool isStroke =
                              widget.controller.currentTool ==
                              DrawingTool.strokeEraser;
                          return isPanelHorizontal
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildPanelButtons(isStroke),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: _buildPanelButtons(isStroke),
                                );
                        },
                      ),
                    ),
                    borderRadius: BorderRadius.circular(
                      HydropTheme.of(context).radiusXl,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPanelButtons(bool isStroke) {
    return [
      _ToolButton(
        icon: Icons.delete_sweep,
        label: 'Stroke',
        isSelected: isStroke,
        onTap: () {
          widget.controller.setTool(DrawingTool.strokeEraser);
          closeWithAnimation();
        },
      ),
    ];
  }
}
