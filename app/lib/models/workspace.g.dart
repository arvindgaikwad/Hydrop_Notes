// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteDocumentAdapter extends TypeAdapter<NoteDocument> {
  @override
  final typeId = 1;

  @override
  NoteDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteDocument(
      id: fields[0] as String,
      title: fields[1] as String,
      folderId: fields[2] as String?,
      layers: fields[3] == null ? [] : (fields[3] as List).cast<CanvasLayer>(),
      isTrashed: fields[6] == null ? false : fields[6] as bool,
      canvasType: fields[7] == null ? 'infinite' : fields[7] as String,
      scenes: fields[8] == null ? [] : (fields[8] as List).cast<dynamic>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteDocument obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.folderId)
      ..writeByte(3)
      ..write(obj.layers)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isTrashed)
      ..writeByte(7)
      ..write(obj.canvasType)
      ..writeByte(8)
      ..write(obj.scenes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final typeId = 2;

  @override
  Folder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Folder(
      id: fields[0] as String,
      name: fields[1] as String,
      parentId: fields[2] as String?,
      isTrashed: fields[4] == null ? false : fields[4] as bool,
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isTrashed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
