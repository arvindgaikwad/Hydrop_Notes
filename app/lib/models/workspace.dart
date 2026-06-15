import 'package:hive_ce/hive_ce.dart';
import 'canvas_objects.dart';

part 'workspace.g.dart';

@HiveType(typeId: 1)
class NoteDocument {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final String? folderId;

  @HiveField(3, defaultValue: [])
  List<CanvasLayer> layers;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6, defaultValue: false)
  final bool isTrashed;

  @HiveField(7, defaultValue: 'infinite')
  final String canvasType;

  @HiveField(8, defaultValue: [])
  List<dynamic> scenes;

  // Transient state for Undo/Redo persistence across page navigation
  List<dynamic> undoStack = [];
  List<dynamic> redoStack = [];

  NoteDocument({
    required this.id,
    required this.title,
    this.folderId,
    this.layers = const [],
    this.isTrashed = false,
    this.canvasType = 'infinite',
    this.scenes = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
}

@HiveType(typeId: 2)
class Folder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final String? parentId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4, defaultValue: false)
  final bool isTrashed;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    this.isTrashed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
