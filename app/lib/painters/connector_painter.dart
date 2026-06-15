import 'package:flutter/material.dart';
import '../models/canvas_objects.dart';
import '../controllers/canvas_controller.dart';
import 'dart:math';

class ConnectorPainter extends CustomPainter {
  final List<ConnectorNode> connectors;
  final CanvasController controller;
  final bool isActiveLayer;

  ConnectorPainter({
    required this.connectors,
    required this.controller,
    required this.isActiveLayer,
    super.repaint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var connector in connectors) {
      _drawConnector(canvas, connector.startNodeId, connector.endNodeId, connector.startPoint, connector.endPoint, Color(connector.colorValue), connector.strokeWidth, connector.pathType);
    }

    if (isActiveLayer && controller.currentTool == DrawingTool.connector && (controller.activeConnectorStartNodeId != null || controller.activeConnectorStartPoint != null) && controller.activeConnectorEndPoint != null) {
      _drawConnector(
        canvas,
        controller.activeConnectorStartNodeId,
        null,
        controller.activeConnectorStartPoint,
        controller.activeConnectorEndPoint,
        controller.currentColor,
        controller.currentWidth,
        'curve',
      );
    }
  }

  void _drawConnector(Canvas canvas, String? startNodeId, String? endNodeId, Offset? startPoint, Offset? endPoint, Color color, double strokeWidth, String pathType) {
    Rect? startRect;
    Rect? endRect;

    if (startNodeId != null) {
      final startNode = controller.layersNotifier.value
          .expand((layer) => [...layer.textNodes, ...layer.imageNodes, ...layer.documentNodes])
          .whereType<TransformableNode>()
          .cast<TransformableNode?>()
          .firstWhere((node) => node?.id == startNodeId, orElse: () => null);

      if (startNode != null) {
        startRect = controller.getNodeBounds(startNode);
      }
    }

    if (endNodeId != null) {
      final endNode = controller.layersNotifier.value
          .expand((layer) => [...layer.textNodes, ...layer.imageNodes, ...layer.documentNodes])
          .whereType<TransformableNode>()
          .cast<TransformableNode?>()
          .firstWhere((node) => node?.id == endNodeId, orElse: () => null);

      if (endNode != null) {
        endRect = controller.getNodeBounds(endNode);
      }
    }

    final p1 = startRect?.center ?? startPoint;
    final p2 = endRect?.center ?? endPoint;

    if (p1 == null || p2 == null) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final actualStart = startRect != null ? _getIntersectionPoint(startRect, p1, p2) : p1;
    final actualEnd = endRect != null ? _getIntersectionPoint(endRect, p2, p1) : p2;

    if (pathType == 'curve') {
      final path = Path();
      path.moveTo(actualStart.dx, actualStart.dy);
      // Determine control points for a smooth Bezier curve
      final dx = (actualEnd.dx - actualStart.dx).abs();
      final dy = (actualEnd.dy - actualStart.dy).abs();
      
      // Basic smooth curve
      Offset cp1, cp2;
      if (dx > dy) {
        cp1 = Offset(actualStart.dx + (actualEnd.dx - actualStart.dx) / 2, actualStart.dy);
        cp2 = Offset(actualStart.dx + (actualEnd.dx - actualStart.dx) / 2, actualEnd.dy);
      } else {
        cp1 = Offset(actualStart.dx, actualStart.dy + (actualEnd.dy - actualStart.dy) / 2);
        cp2 = Offset(actualEnd.dx, actualStart.dy + (actualEnd.dy - actualStart.dy) / 2);
      }
      
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, actualEnd.dx, actualEnd.dy);
      canvas.drawPath(path, paint);
      _drawArrowhead(canvas, cp2, actualEnd, color, strokeWidth);
    } else {
      canvas.drawLine(actualStart, actualEnd, paint);
      _drawArrowhead(canvas, actualStart, actualEnd, color, strokeWidth);
    }
  }

  Offset _getIntersectionPoint(Rect rect, Offset inside, Offset outside) {
    // Simple line-rectangle intersection algorithm
    final dx = outside.dx - inside.dx;
    final dy = outside.dy - inside.dy;
    
    if (dx == 0 && dy == 0) return inside;
    
    final t1 = (rect.left - inside.dx) / dx;
    final t2 = (rect.right - inside.dx) / dx;
    final t3 = (rect.top - inside.dy) / dy;
    final t4 = (rect.bottom - inside.dy) / dy;
    
    final tminX = min(t1, t2);
    final tminY = min(t3, t4);
    
    final tmin = max(tminX, tminY);
    
    if (tmin > 0 && tmin < 1) {
      return Offset(inside.dx + dx * tmin, inside.dy + dy * tmin);
    }
    
    // Fallback
    final w = rect.width / 2;
    final h = rect.height / 2;
    final angle = atan2(dy, dx);
    
    double resultDx, resultDy;
    if (dx.abs() * h > dy.abs() * w) {
      resultDx = dx > 0 ? w : -w;
      resultDy = resultDx * tan(angle);
    } else {
      resultDy = dy > 0 ? h : -h;
      resultDx = resultDy / tan(angle);
    }
    
    return Offset(rect.center.dx + resultDx, rect.center.dy + resultDy);
  }

  void _drawArrowhead(Canvas canvas, Offset p1, Offset p2, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final angle = atan2(p2.dy - p1.dy, p2.dx - p1.dx);
    final arrowLength = max(10.0, strokeWidth * 3);
    final arrowAngle = pi / 6; // 30 degrees
    
    final path = Path();
    path.moveTo(p2.dx, p2.dy);
    path.lineTo(
      p2.dx - arrowLength * cos(angle - arrowAngle),
      p2.dy - arrowLength * sin(angle - arrowAngle),
    );
    path.lineTo(
      p2.dx - arrowLength * cos(angle + arrowAngle),
      p2.dy - arrowLength * sin(angle + arrowAngle),
    );
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectorPainter oldDelegate) {
    return true; // We can optimize this later
  }
}
