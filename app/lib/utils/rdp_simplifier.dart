import 'package:flutter/material.dart';
import '../models/stroke.dart';

class RDPSimplifier {
  /// Simplifies a list of StrokePoints using the Ramer-Douglas-Peucker algorithm.
  /// Custom modification: Also respects pressure deviation, so we don't drop
  /// points that represent sudden spikes in pressure, even if the line is straight.
  static List<StrokePoint> simplify(List<StrokePoint> points, double tolerance, {double pressureTolerance = 0.15}) {
    if (points.length <= 2) return points;

    double maxDistance = 0.0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(points[i].point, points.first.point, points.last.point);
      
      // Check for pressure deviation
      double t = i / (points.length - 1);
      double expectedPressure = points.first.pressure + t * (points.last.pressure - points.first.pressure);
      double pressureDelta = (points[i].pressure - expectedPressure).abs();
      
      // If pressure deviates beyond tolerance, inflate the 'distance' to force RDP to split here
      if (pressureDelta > pressureTolerance) {
        distance += (pressureDelta * 20.0); // heavily weight the pressure spike
      }

      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > tolerance) {
      List<StrokePoint> left = simplify(points.sublist(0, index + 1), tolerance, pressureTolerance: pressureTolerance);
      List<StrokePoint> right = simplify(points.sublist(index), tolerance, pressureTolerance: pressureTolerance);
      
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  static double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
    double area = ((lineEnd.dy - lineStart.dy) * point.dx -
            (lineEnd.dx - lineStart.dx) * point.dy +
            lineEnd.dx * lineStart.dy -
            lineEnd.dy * lineStart.dx)
        .abs();
    double bottom = (lineEnd - lineStart).distance;
    return bottom == 0 ? (point - lineStart).distance : area / bottom;
  }
}
