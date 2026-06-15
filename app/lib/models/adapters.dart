import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

class OffsetAdapter extends TypeAdapter<Offset> {
  @override
  final int typeId = 100;

  @override
  Offset read(BinaryReader reader) {
    return Offset(reader.readDouble(), reader.readDouble());
  }

  @override
  void write(BinaryWriter writer, Offset obj) {
    writer.writeDouble(obj.dx);
    writer.writeDouble(obj.dy);
  }
}
