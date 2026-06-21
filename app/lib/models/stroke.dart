import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:perfect_freehand/perfect_freehand.dart' as pf;

part 'stroke.g.dart';

@HiveType(typeId: 3)
class StrokePoint {
  @HiveField(0)
  Offset point;

  @HiveField(1)
  final double pressure;

  StrokePoint(this.point, this.pressure);

  StrokePoint clone() {
    return StrokePoint(Offset(point.dx, point.dy), pressure);
  }
}

@HiveType(typeId: 4)
class Stroke {
  @HiveField(0)
  final List<StrokePoint> points;

  @HiveField(1)
  final Color color;

  @HiveField(2)
  double baseWidth;

  @HiveField(3, defaultValue: false)
  final bool isPixelEraser;

  @HiveField(4, defaultValue: true)
  final bool isInkPen;

  @HiveField(5, defaultValue: false)
  final bool isTape;

  @HiveField(6, defaultValue: false)
  bool isTapeRevealed;

  @HiveField(7)
  String? startNodeId;

  @HiveField(8)
  String? endNodeId;

  List<Offset>? _cachedOffsets;
  Path? _cachedPath;
  int _cachedPathLength = 0;

  List<Offset> get offsets {
    if (_cachedOffsets != null && _cachedOffsets!.length == points.length) {
      return _cachedOffsets!;
    }
    _cachedOffsets = points.map((p) => p.point).toList(growable: false);
    return _cachedOffsets!;
  }

  void invalidateCache() {
    _cachedPath = null;
    _cachedOffsets = null;
  }

  List<Offset>? _cachedOutlinePolygon;

  List<Offset> get outlinePolygon {
    // Generate it if path is called, or calculate directly
    if (_cachedOutlinePolygon != null && _cachedPathLength == points.length) {
      return _cachedOutlinePolygon!;
    }
    _generatePathAndPolygon();
    return _cachedOutlinePolygon!;
  }

  Path get path {
    if (_cachedPath != null && _cachedPathLength == points.length) {
      return _cachedPath!;
    }
    _generatePathAndPolygon();
    return _cachedPath!;
  }

  void _generatePathAndPolygon() {
    _cachedPath = Path();
    _cachedOutlinePolygon = [];

    if (points.isNotEmpty) {
      if (isInkPen) {
        bool isMouse = true;
        for (int i = 0; i < points.length && i < 20; i++) {
          if (points[i].pressure != 1.0 && points[i].pressure != 0.0) {
            isMouse = false;
            break;
          }
        }

        final outlinePoints = pf.getStroke(
          points
              .map((p) => pf.PointVector(p.point.dx, p.point.dy, p.pressure))
              .toList(),
          options: pf.StrokeOptions(
            size: baseWidth * 2,
            thinning: 0.7,
            smoothing: 0.5,
            streamline: 0.5,
            simulatePressure: isMouse,
          ),
        );

        if (outlinePoints.isNotEmpty) {
          _cachedPath!.moveTo(outlinePoints.first.dx, outlinePoints.first.dy);
          _cachedOutlinePolygon!.add(Offset(outlinePoints.first.dx, outlinePoints.first.dy));
          
          if (outlinePoints.length == 2) {
            final pt = Offset(outlinePoints[1].dx, outlinePoints[1].dy);
            _cachedPath!.lineTo(pt.dx, pt.dy);
            _cachedOutlinePolygon!.add(pt);
          } else if (outlinePoints.length > 2) {
            for (int i = 1; i < outlinePoints.length - 1; i++) {
              final p0 = Offset(outlinePoints[i].dx, outlinePoints[i].dy);
              final p1 = Offset(outlinePoints[i + 1].dx, outlinePoints[i + 1].dy);
              final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
              _cachedPath!.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
              _cachedOutlinePolygon!.add(mid);
            }
            final last = Offset(outlinePoints.last.dx, outlinePoints.last.dy);
            _cachedPath!.lineTo(last.dx, last.dy);
            _cachedOutlinePolygon!.add(last);
          }
          _cachedPath!.close();
        }
      } else {
        // For Normal Pen and Tape, generate a perfectly smooth quadratic bezier path
        _cachedPath!.moveTo(points.first.point.dx, points.first.point.dy);
        _cachedOutlinePolygon!.add(points.first.point);

        if (points.length == 2) {
          _cachedPath!.lineTo(points[1].point.dx, points[1].point.dy);
          _cachedOutlinePolygon!.add(points[1].point);
        } else if (points.length > 2) {
          for (int i = 1; i < points.length - 1; i++) {
            final p0 = points[i].point;
            final p1 = points[i + 1].point;
            final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
            _cachedPath!.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
            _cachedOutlinePolygon!.add(mid);
          }
          final last = points.last.point;
          _cachedPath!.lineTo(last.dx, last.dy);
          _cachedOutlinePolygon!.add(last);
        }
      }
    }

    _cachedPathLength = points.length;
  }

  Stroke({
    required this.points,
    this.color = Colors.black,
    this.baseWidth = 2.0,
    this.isPixelEraser = false,
    this.isInkPen = true,
    this.isTape = false,
    this.isTapeRevealed = false,
    this.startNodeId,
    this.endNodeId,
  });

  Stroke clone() {
    return Stroke(
      points: points.map((p) => p.clone()).toList(),
      color: color,
      baseWidth: baseWidth,
      isPixelEraser: isPixelEraser,
      isInkPen: isInkPen,
      isTape: isTape,
      isTapeRevealed: isTapeRevealed,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
    );
  }
}
