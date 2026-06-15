import 'package:flutter/material.dart';
import 'dart:math';
import '../controllers/canvas_controller.dart';
import '../theme/theme.dart';
import 'drawing_toolbar.dart';

class HueRingPicker extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;

  const HueRingPicker({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<HueRingPicker> createState() => _HueRingPickerState();
}

class _HueRingPickerState extends State<HueRingPicker> {
  late HSVColor currentHsv;

  @override
  void initState() {
    super.initState();
    currentHsv = HSVColor.fromColor(widget.initialColor);
  }

  void _handleGesture(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Calculate angle from 0 to 360
    double angle = atan2(dy, dx) * 180 / pi;
    if (angle < 0) angle += 360;

    // Distance from center
    double radius = sqrt(dx * dx + dy * dy);
    double maxRadius = size.width / 2;

    // Determine Saturation/Value based on radius if we want, or just set Hue.
    // Let's just set Hue on the ring.
    if (radius <= maxRadius) {
      setState(() {
        currentHsv = currentHsv.withHue(angle);
        widget.onColorChanged(currentHsv.toColor());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The hue ring
          GestureDetector(
            onPanDown: (details) =>
                _handleGesture(details.localPosition, const Size(200, 200)),
            onPanUpdate: (details) =>
                _handleGesture(details.localPosition, const Size(200, 200)),
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _HueRingPainter(),
            ),
          ),

          // Inner saturation/value control (simplified to just show the color for now)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentHsv.toColor(),
              border: Border.all(color: AppTheme.ink, width: 4),
              boxShadow: AppTheme.raisedSurface.boxShadow,
            ),
          ),

          // Selection indicator dot
          Transform.translate(
            offset: Offset(
              (200 / 2 - 20) * cos(currentHsv.hue * pi / 180),
              (200 / 2 - 20) * sin(currentHsv.hue * pi / 180),
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.paperBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.ink, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HueRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 40.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius - strokeWidth / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ColorDialOverlay extends StatefulWidget {
  final Offset origin;
  final ToolbarDock dock;
  final CanvasController controller;
  final VoidCallback onClose;

  const ColorDialOverlay({
    super.key,
    required this.origin,
    required this.dock,
    required this.controller,
    required this.onClose,
  });

  static void show({
    required BuildContext context,
    required GlobalKey buttonKey,
    required ToolbarDock dock,
    required CanvasController controller,
  }) {
    final RenderBox renderBox =
        buttonKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final Offset origin = Offset(
      position.dx + size.width / 2,
      position.dy + size.height / 2,
    );

    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => ColorDialOverlay(
        origin: origin,
        dock: dock,
        controller: controller,
        onClose: () {
          entry?.remove();
        },
      ),
    );

    Overlay.of(context).insert(entry);
  }

  @override
  State<ColorDialOverlay> createState() => _ColorDialOverlayState();
}

class _ColorDialOverlayState extends State<ColorDialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  final List<Color> _baseColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

  Color? _selectedBaseColor;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _close() {
    _anim.reverse().then((_) => widget.onClose());
  }

  List<Color> _getShades(Color base) {
    HSVColor hsv = HSVColor.fromColor(base);
    return [
      hsv.withValue(0.9).withSaturation(0.3).toColor(),
      hsv.withValue(0.8).withSaturation(0.6).toColor(),
      hsv.withValue(0.7).withSaturation(1.0).toColor(),
      hsv.withValue(0.5).withSaturation(1.0).toColor(),
      hsv.withValue(0.3).withSaturation(1.0).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: Stack(children: [_buildDialItems()]),
    );
  }

  Widget _buildDialItems() {
    List<Color> colorsToShow = _selectedBaseColor == null
        ? _baseColors
        : _getShades(_selectedBaseColor!);
    int itemCount = colorsToShow.length + 1; // +1 for custom or back

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Stack(
          children: List.generate(itemCount, (index) {
            bool isSpecial = index == itemCount - 1;

            double startAngle = 0;
            double sweepAngle = pi;

            if (widget.dock == ToolbarDock.left) {
              startAngle = -pi / 2;
            } else if (widget.dock == ToolbarDock.right) {
              startAngle = pi / 2;
            } else if (widget.dock == ToolbarDock.top) {
              startAngle = 0;
            } else if (widget.dock == ToolbarDock.bottom) {
              startAngle = pi;
            }

            // Adjust angle to spread evenly
            double angleStep = sweepAngle / (itemCount - 1);
            double angle = startAngle + (index * angleStep);

            // Radius expands
            double radius = Curves.easeOutBack.transform(_anim.value) * 80;

            double dx = cos(angle) * radius;
            double dy = sin(angle) * radius;

            return Positioned(
              left: widget.origin.dx + dx - 20,
              top: widget.origin.dy + dy - 20,
              child: Transform.scale(
                scale: _anim.value,
                child: GestureDetector(
                  onTap: () {
                    if (_selectedBaseColor == null) {
                      if (isSpecial) {
                        _close();
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            content: HueRingPicker(
                              initialColor: widget.controller.currentColor,
                              onColorChanged: (col) =>
                                  widget.controller.setColor(col),
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          _selectedBaseColor = colorsToShow[index];
                        });
                      }
                    } else {
                      if (isSpecial) {
                        setState(() {
                          _selectedBaseColor = null;
                        });
                      } else {
                        widget.controller.setColor(colorsToShow[index]);
                        _close();
                      }
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSpecial
                          ? AppTheme.paperBackground
                          : colorsToShow[index],
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.ink, width: 2),
                      boxShadow: AppTheme.raisedSurface.boxShadow,
                    ),
                    child: isSpecial
                        ? Icon(
                            _selectedBaseColor == null
                                ? Icons.palette
                                : Icons.arrow_back,
                            size: 20,
                            color: AppTheme.ink,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
