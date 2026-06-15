import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'stroke.dart';

part 'canvas_objects.g.dart';

abstract class TransformableNode {
  String get id;
  Offset get position;
  set position(Offset value);
  double get width;
  set width(double value);
  double get height;
  set height(double value);
  double get rotation;
  set rotation(double value);
  double get scale;
  set scale(double value);
}

@HiveType(typeId: 5)
class TextNode implements TransformableNode {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  @override
  Offset position;

  @HiveField(3)
  double fontSize;

  @HiveField(4)
  Color color;

  @HiveField(5, defaultValue: false)
  bool isBold;

  @HiveField(10, defaultValue: false)
  bool isItalic;

  @HiveField(11, defaultValue: false)
  bool isUnderline;

  @HiveField(12, defaultValue: 0) // 0=left, 1=center, 2=right
  int alignmentIndex;

  @override
  @HiveField(6, defaultValue: 200.0)
  double width;

  @override
  @HiveField(7, defaultValue: 50.0)
  double height;

  @override
  @HiveField(8, defaultValue: 0.0)
  double rotation;

  @override
  @HiveField(9, defaultValue: 1.0)
  double scale;

  TextNode({
    required this.id,
    required this.text,
    required this.position,
    this.fontSize = 24.0,
    this.color = Colors.black,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.alignmentIndex = 0,
    this.width = 200.0,
    this.height = 50.0,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  TextNode clone() {
    return TextNode(
      id: id,
      text: text,
      position: Offset(position.dx, position.dy),
      fontSize: fontSize,
      color: color,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      alignmentIndex: alignmentIndex,
      width: width,
      height: height,
      rotation: rotation,
      scale: scale,
    );
  }
}

@HiveType(typeId: 6)
class ImageNode implements TransformableNode {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  final String filePath;

  @HiveField(2)
  @override
  Offset position;

  @override
  @HiveField(3)
  double width;

  @override
  @HiveField(4)
  double height;

  @override
  @HiveField(5, defaultValue: 0.0)
  double rotation;

  @override
  @HiveField(6, defaultValue: 1.0)
  double scale;

  ImageNode({
    required this.id,
    required this.filePath,
    required this.position,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  ImageNode clone() {
    return ImageNode(
      id: id,
      filePath: filePath,
      position: Offset(position.dx, position.dy),
      width: width,
      height: height,
      rotation: rotation,
      scale: scale,
    );
  }
}

@HiveType(typeId: 8)
class DocumentNode implements TransformableNode {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  @override
  Offset position;

  @override
  @HiveField(3)
  double width;

  @override
  @HiveField(4)
  double height;

  @override
  @HiveField(5, defaultValue: 0.0)
  double rotation;

  @override
  @HiveField(6, defaultValue: 1.0)
  double scale;

  DocumentNode({
    required this.id,
    required this.text,
    required this.position,
    this.width = 600.0,
    this.height = 100.0,
    this.rotation = 0.0,
    this.scale = 1.0,
  });

  DocumentNode clone() {
    return DocumentNode(
      id: id,
      text: text,
      position: Offset(position.dx, position.dy),
      width: width,
      height: height,
      rotation: rotation,
      scale: scale,
    );
  }
}

@HiveType(typeId: 9)
class ConnectorNode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String? startNodeId;

  @HiveField(2)
  String? endNodeId;

  @HiveField(3)
  Offset? startPoint;

  @HiveField(4)
  Offset? endPoint;

  @HiveField(5, defaultValue: 'curve')
  String pathType; 

  @HiveField(6, defaultValue: 0xFF000000)
  int colorValue;

  @HiveField(7, defaultValue: 2.0)
  double strokeWidth;

  ConnectorNode({
    required this.id,
    this.startNodeId,
    this.endNodeId,
    this.startPoint,
    this.endPoint,
    this.pathType = 'curve',
    this.colorValue = 0xFF000000,
    this.strokeWidth = 2.0,
  });

  ConnectorNode clone() {
    return ConnectorNode(
      id: id,
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      startPoint: startPoint != null ? Offset(startPoint!.dx, startPoint!.dy) : null,
      endPoint: endPoint != null ? Offset(endPoint!.dx, endPoint!.dy) : null,
      pathType: pathType,
      colorValue: colorValue,
      strokeWidth: strokeWidth,
    );
  }
}

@HiveType(typeId: 7)
class CanvasLayer {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2, defaultValue: true)
  bool isVisible;

  @HiveField(3, defaultValue: false)
  bool isLocked;

  @HiveField(4, defaultValue: [])
  List<Stroke> strokes;

  @HiveField(5, defaultValue: [])
  List<TextNode> textNodes;

  @HiveField(6, defaultValue: [])
  List<ImageNode> imageNodes;

  @HiveField(7, defaultValue: [])
  List<DocumentNode> documentNodes;

  @HiveField(8, defaultValue: [])
  List<ConnectorNode> connectorNodes;

  CanvasLayer({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
    this.strokes = const [],
    this.textNodes = const [],
    this.imageNodes = const [],
    this.documentNodes = const [],
    this.connectorNodes = const [],
  });

  CanvasLayer clone() {
    return CanvasLayer(
      id: id,
      name: name,
      isVisible: isVisible,
      isLocked: isLocked,
      strokes: strokes.map((s) => s.clone()).toList(),
      textNodes: textNodes.map((t) => t.clone()).toList(),
      imageNodes: imageNodes.map((i) => i.clone()).toList(),
      documentNodes: documentNodes.map((d) => d.clone()).toList(),
      connectorNodes: connectorNodes.map((c) => c.clone()).toList(),
    );
  }
}

class CanvasScene {
  final String id;
  String name;
  final double x;
  final double y;
  final double scale;
  final DateTime createdAt;

  CanvasScene({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.scale,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'scale': scale,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CanvasScene.fromMap(Map<dynamic, dynamic> map) => CanvasScene(
        id: map['id'] as String,
        name: map['name'] as String,
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        scale: (map['scale'] as num).toDouble(),
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
      );
}

