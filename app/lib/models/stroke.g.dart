// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroke.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StrokePointAdapter extends TypeAdapter<StrokePoint> {
  @override
  final typeId = 3;

  @override
  StrokePoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrokePoint(fields[0] as Offset, (fields[1] as num).toDouble());
  }

  @override
  void write(BinaryWriter writer, StrokePoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.point)
      ..writeByte(1)
      ..write(obj.pressure);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokePointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StrokeAdapter extends TypeAdapter<Stroke> {
  @override
  final typeId = 4;

  @override
  Stroke read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Stroke(
      points: (fields[0] as List).cast<StrokePoint>(),
      color: fields[1] == null ? Colors.black : fields[1] as Color,
      baseWidth: fields[2] == null ? 2.0 : (fields[2] as num).toDouble(),
      isPixelEraser: fields[3] == null ? false : fields[3] as bool,
      isInkPen: fields[4] == null ? true : fields[4] as bool,
      isTape: fields[5] == null ? false : fields[5] as bool,
      isTapeRevealed: fields[6] == null ? false : fields[6] as bool,
      startNodeId: fields[7] as String?,
      endNodeId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Stroke obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.points)
      ..writeByte(1)
      ..write(obj.color)
      ..writeByte(2)
      ..write(obj.baseWidth)
      ..writeByte(3)
      ..write(obj.isPixelEraser)
      ..writeByte(4)
      ..write(obj.isInkPen)
      ..writeByte(5)
      ..write(obj.isTape)
      ..writeByte(6)
      ..write(obj.isTapeRevealed)
      ..writeByte(7)
      ..write(obj.startNodeId)
      ..writeByte(8)
      ..write(obj.endNodeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrokeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
