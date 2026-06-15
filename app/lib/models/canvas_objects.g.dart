// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_objects.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TextNodeAdapter extends TypeAdapter<TextNode> {
  @override
  final typeId = 5;

  @override
  TextNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TextNode(
      id: fields[0] as String,
      text: fields[1] as String,
      position: fields[2] as Offset,
      fontSize: fields[3] == null ? 24.0 : (fields[3] as num).toDouble(),
      color: fields[4] == null ? Colors.black : fields[4] as Color,
      isBold: fields[5] == null ? false : fields[5] as bool,
      isItalic: fields[10] == null ? false : fields[10] as bool,
      isUnderline: fields[11] == null ? false : fields[11] as bool,
      alignmentIndex: fields[12] == null ? 0 : (fields[12] as num).toInt(),
      width: fields[6] == null ? 200.0 : (fields[6] as num).toDouble(),
      height: fields[7] == null ? 50.0 : (fields[7] as num).toDouble(),
      rotation: fields[8] == null ? 0.0 : (fields[8] as num).toDouble(),
      scale: fields[9] == null ? 1.0 : (fields[9] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, TextNode obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.fontSize)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.isBold)
      ..writeByte(6)
      ..write(obj.width)
      ..writeByte(7)
      ..write(obj.height)
      ..writeByte(8)
      ..write(obj.rotation)
      ..writeByte(9)
      ..write(obj.scale)
      ..writeByte(10)
      ..write(obj.isItalic)
      ..writeByte(11)
      ..write(obj.isUnderline)
      ..writeByte(12)
      ..write(obj.alignmentIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ImageNodeAdapter extends TypeAdapter<ImageNode> {
  @override
  final typeId = 6;

  @override
  ImageNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageNode(
      id: fields[0] as String,
      filePath: fields[1] as String,
      position: fields[2] as Offset,
      width: (fields[3] as num).toDouble(),
      height: (fields[4] as num).toDouble(),
      rotation: fields[5] == null ? 0.0 : (fields[5] as num).toDouble(),
      scale: fields[6] == null ? 1.0 : (fields[6] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ImageNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.width)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.rotation)
      ..writeByte(6)
      ..write(obj.scale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DocumentNodeAdapter extends TypeAdapter<DocumentNode> {
  @override
  final typeId = 8;

  @override
  DocumentNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentNode(
      id: fields[0] as String,
      text: fields[1] as String,
      position: fields[2] as Offset,
      width: fields[3] == null ? 600.0 : (fields[3] as num).toDouble(),
      height: fields[4] == null ? 100.0 : (fields[4] as num).toDouble(),
      rotation: fields[5] == null ? 0.0 : (fields[5] as num).toDouble(),
      scale: fields[6] == null ? 1.0 : (fields[6] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, DocumentNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.width)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.rotation)
      ..writeByte(6)
      ..write(obj.scale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConnectorNodeAdapter extends TypeAdapter<ConnectorNode> {
  @override
  final typeId = 9;

  @override
  ConnectorNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConnectorNode(
      id: fields[0] as String,
      startNodeId: fields[1] as String?,
      endNodeId: fields[2] as String?,
      startPoint: fields[3] as Offset?,
      endPoint: fields[4] as Offset?,
      pathType: fields[5] == null ? 'curve' : fields[5] as String,
      colorValue: fields[6] == null ? 4278190080 : (fields[6] as num).toInt(),
      strokeWidth: fields[7] == null ? 2.0 : (fields[7] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ConnectorNode obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startNodeId)
      ..writeByte(2)
      ..write(obj.endNodeId)
      ..writeByte(3)
      ..write(obj.startPoint)
      ..writeByte(4)
      ..write(obj.endPoint)
      ..writeByte(5)
      ..write(obj.pathType)
      ..writeByte(6)
      ..write(obj.colorValue)
      ..writeByte(7)
      ..write(obj.strokeWidth);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectorNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CanvasLayerAdapter extends TypeAdapter<CanvasLayer> {
  @override
  final typeId = 7;

  @override
  CanvasLayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CanvasLayer(
      id: fields[0] as String,
      name: fields[1] as String,
      isVisible: fields[2] == null ? true : fields[2] as bool,
      isLocked: fields[3] == null ? false : fields[3] as bool,
      strokes: fields[4] == null ? [] : (fields[4] as List).cast<Stroke>(),
      textNodes: fields[5] == null ? [] : (fields[5] as List).cast<TextNode>(),
      imageNodes: fields[6] == null
          ? []
          : (fields[6] as List).cast<ImageNode>(),
      documentNodes: fields[7] == null
          ? []
          : (fields[7] as List).cast<DocumentNode>(),
      connectorNodes: fields[8] == null
          ? []
          : (fields[8] as List).cast<ConnectorNode>(),
    );
  }

  @override
  void write(BinaryWriter writer, CanvasLayer obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isVisible)
      ..writeByte(3)
      ..write(obj.isLocked)
      ..writeByte(4)
      ..write(obj.strokes)
      ..writeByte(5)
      ..write(obj.textNodes)
      ..writeByte(6)
      ..write(obj.imageNodes)
      ..writeByte(7)
      ..write(obj.documentNodes)
      ..writeByte(8)
      ..write(obj.connectorNodes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasLayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
