import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import '../models/workspace.dart';
import '../models/canvas_objects.dart';

class WorkspaceController extends ChangeNotifier {
  List<Folder> _folders = [];
  List<NoteDocument> _notes = [];

  List<Folder> get folders => _folders.where((f) => !f.isTrashed).toList();
  List<NoteDocument> get notes => _notes.where((n) => !n.isTrashed).toList();

  List<Folder> get trashedFolders =>
      _folders.where((f) => f.isTrashed).toList();
  List<NoteDocument> get trashedNotes =>
      _notes.where((n) => n.isTrashed).toList();

  String? _currentFolderId;
  String? get currentFolderId => _currentFolderId;

  String? _primaryNoteId;
  String? get primaryNoteId => _primaryNoteId;

  String? _secondaryNoteId;
  String? get secondaryNoteId => _secondaryNoteId;

  String? _movingItemId;
  String? get movingItemId => _movingItemId;

  String? _movingItemType; // 'folder' or 'note'
  String? get movingItemType => _movingItemType;

  late Box<Folder> _folderBox;
  late Box<NoteDocument> _noteBox;

  WorkspaceController();

  Future<void> init() async {
    _folderBox = await Hive.openBox<Folder>('folders');
    _noteBox = await Hive.openBox<NoteDocument>('notes');

    _folders = _folderBox.values.toList();
    _notes = _noteBox.values.toList();

    // Seed if empty
    if (_folders.isEmpty) {
      final f1 = Folder(id: 'root-1', name: 'Personal Ideas');
      final f2 = Folder(id: 'root-2', name: 'Work');
      await _folderBox.put(f1.id, f1);
      await _folderBox.put(f2.id, f2);
      _folders.addAll([f1, f2]);
    }

    notifyListeners();
  }

  void setCurrentFolder(String? folderId) {
    _currentFolderId = folderId;
    notifyListeners();
  }

  void openNote(String noteId, {bool asSecondary = false}) {
    if (asSecondary) {
      if (_primaryNoteId == null) {
        _primaryNoteId = noteId;
      } else if (_primaryNoteId != noteId) {
        _secondaryNoteId = noteId;
      }
    } else {
      _primaryNoteId = noteId;
      _secondaryNoteId = null; // Close secondary if opening a new primary
    }
    notifyListeners();
  }

  void closeNote(String noteId) {
    if (_primaryNoteId == noteId) {
      _primaryNoteId = _secondaryNoteId;
      _secondaryNoteId = null;
    } else if (_secondaryNoteId == noteId) {
      _secondaryNoteId = null;
    }
    notifyListeners();
  }

  Future<Folder> createFolder(String name, {String? parentId}) async {
    final newFolder = Folder(
      id: 'folder-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      parentId: parentId ?? _currentFolderId,
    );
    _folders.add(newFolder);
    await _folderBox.put(newFolder.id, newFolder);
    notifyListeners();
    return newFolder;
  }

  NoteDocument createNote(String title, {String canvasType = 'infinite'}) {
    final newNote = NoteDocument(
      id: 'note-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      folderId: _currentFolderId,
      canvasType: canvasType,
    );
    _notes.add(newNote);
    _noteBox.put(newNote.id, newNote);
    notifyListeners();
    return newNote;
  }

  void saveNoteCanvas(String noteId, List<CanvasLayer> layers) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final oldNote = _notes[index];
      final updatedNote = NoteDocument(
        id: oldNote.id,
        title: oldNote.title,
        folderId: oldNote.folderId,
        layers: List.from(layers),
        isTrashed: oldNote.isTrashed,
        canvasType: oldNote.canvasType,
        scenes: oldNote.scenes,
        createdAt: oldNote.createdAt,
        updatedAt: DateTime.now(),
      );
      _notes[index] = updatedNote;
      _noteBox.put(updatedNote.id, updatedNote);
      notifyListeners();
    }
  }

  void renameFolder(String folderId, String newName) {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index != -1) {
      final old = _folders[index];
      final updated = Folder(
        id: old.id,
        name: newName,
        parentId: old.parentId,
        isTrashed: old.isTrashed,
        createdAt: old.createdAt,
      );
      _folders[index] = updated;
      _folderBox.put(updated.id, updated);
      notifyListeners();
    }
  }

  void renameNote(String noteId, String newTitle) {
    final index = _notes.indexWhere((n) => n.id == noteId);
    if (index != -1) {
      final old = _notes[index];
      final updated = NoteDocument(
        id: old.id,
        title: newTitle,
        folderId: old.folderId,
        layers: old.layers,
        isTrashed: old.isTrashed,
        canvasType: old.canvasType,
        scenes: old.scenes,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      _notes[index] = updated;
      _noteBox.put(updated.id, updated);
      notifyListeners();
    }
  }

  void setNoteCanvasType(String noteId, String canvasType) {
    final idx = _notes.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      final old = _notes[idx];
      final updated = NoteDocument(
        id: old.id,
        title: old.title,
        folderId: old.folderId,
        layers: old.layers,
        isTrashed: old.isTrashed,
        canvasType: canvasType,
        scenes: old.scenes,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      updated.undoStack = List.from(old.undoStack);
      updated.redoStack = List.from(old.redoStack);
      _notes[idx] = updated;
      _noteBox.put(noteId, updated);
      notifyListeners();
    }
  }

  void startMove(String id, String type) {
    _movingItemId = id;
    _movingItemType = type;
    notifyListeners();
  }

  void cancelMove() {
    if (_movingItemId != null) {
      _movingItemId = null;
      _movingItemType = null;
      notifyListeners();
    }
  }

  void moveNote(String noteId, String? newFolderId) {
    final idx = _notes.indexWhere((n) => n.id == noteId);
    if (idx != -1) {
      final old = _notes[idx];
      if (old.folderId == newFolderId) return;

      final updated = NoteDocument(
        id: old.id,
        title: old.title,
        folderId: newFolderId,
        layers: old.layers,
        isTrashed: old.isTrashed,
        canvasType: old.canvasType,
        scenes: old.scenes,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      updated.undoStack = List.from(old.undoStack);
      updated.redoStack = List.from(old.redoStack);
      _notes[idx] = updated;
      _noteBox.put(noteId, updated);
      notifyListeners();
    }
  }

  bool _isDescendant(String potentialDescendantId, String ancestorId) {
    String? currentParentId = _folders
        .firstWhere(
          (f) => f.id == potentialDescendantId,
          orElse: () => Folder(id: '', name: ''),
        )
        .parentId;
    while (currentParentId != null) {
      if (currentParentId == ancestorId) return true;
      currentParentId = _folders
          .firstWhere(
            (f) => f.id == currentParentId,
            orElse: () => Folder(id: '', name: ''),
          )
          .parentId;
    }
    return false;
  }

  void moveFolder(String folderId, String? newParentId) {
    if (folderId == newParentId) return; // Cannot move into itself
    if (newParentId != null && _isDescendant(newParentId, folderId)) {
      return; // Cannot move into its own descendant
    }

    final idx = _folders.indexWhere((f) => f.id == folderId);
    if (idx != -1) {
      final old = _folders[idx];
      if (old.parentId == newParentId) return;

      final updated = Folder(id: old.id, name: old.name, parentId: newParentId);
      _folders[idx] = updated;
      _folderBox.put(folderId, updated);
      notifyListeners();
    }
  }

  void moveToTrash(String id, bool isFolder) {
    if (isFolder) {
      final index = _folders.indexWhere((f) => f.id == id);
      if (index != -1) {
        final old = _folders[index];
        final updated = Folder(
          id: old.id,
          name: old.name,
          parentId: old.parentId,
          isTrashed: true,
          createdAt: old.createdAt,
        );
        _folders[index] = updated;
        _folderBox.put(updated.id, updated);
      }
    } else {
      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final old = _notes[index];
        final updated = NoteDocument(
          id: old.id,
          title: old.title,
          folderId: old.folderId,
          layers: old.layers,
          isTrashed: true,
          canvasType: old.canvasType,
          scenes: old.scenes,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        _notes[index] = updated;
        _noteBox.put(updated.id, updated);
      }
    }
    notifyListeners();
  }

  void restoreFromTrash(String id, bool isFolder) {
    if (isFolder) {
      final index = _folders.indexWhere((f) => f.id == id);
      if (index != -1) {
        final old = _folders[index];
        final updated = Folder(
          id: old.id,
          name: old.name,
          parentId: old.parentId,
          isTrashed: false,
          createdAt: old.createdAt,
        );
        _folders[index] = updated;
        _folderBox.put(updated.id, updated);
      }
    } else {
      final index = _notes.indexWhere((n) => n.id == id);
      if (index != -1) {
        final old = _notes[index];
        final updated = NoteDocument(
          id: old.id,
          title: old.title,
          folderId: old.folderId,
          layers: old.layers,
          isTrashed: false,
          canvasType: old.canvasType,
          scenes: old.scenes,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        _notes[index] = updated;
        _noteBox.put(updated.id, updated);
      }
    }
    notifyListeners();
  }

  void permanentlyDelete(String id, bool isFolder) {
    if (isFolder) {
      _folders.removeWhere((f) => f.id == id);
      _folderBox.delete(id);
    } else {
      _notes.removeWhere((n) => n.id == id);
      _noteBox.delete(id);
    }
    notifyListeners();
  }
}
