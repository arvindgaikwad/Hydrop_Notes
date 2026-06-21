import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/workspace_controller.dart';
import '../models/workspace.dart';
import '../theme/hydrop_theme.dart';
import '../theme/theme_controller.dart';
import '../widgets/editable_cards.dart';
import 'canvas_page.dart';

class MobileHomePage extends StatefulWidget {
  final WorkspaceController workspace;
  final ThemeController themeController;

  const MobileHomePage({
    super.key,
    required this.workspace,
    required this.themeController,
  });

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  bool _showTrash = false;
  String _searchQuery = '';

  void _createNewFolder() async {
    await widget.workspace.createFolder('New Ocean');
    setState(() {
      _showTrash = false;
    });
  }

  void _createAndOpenNote(String canvasType) {
    String title = 'Drop';
    if (canvasType == 'infinite') title = 'Complete Infinite Drop';
    if (canvasType == 'limited_infinite') title = 'Limited Infinite Drop';
    if (canvasType == 'a4') title = 'A4 Size Drop';
    
    final newNote = widget.workspace.createNote(title, canvasType: canvasType);
    widget.workspace.openNote(newNote.id);
  }

  void _showNewItemBottomSheet() {
    final ht = HydropTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: ht.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: ht.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.folder, color: ht.primary),
                  title: Text('New Sub-Ocean', style: TextStyle(color: ht.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _createNewFolder();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.note_alt, color: ht.primary),
                  title: Text('New Drop (A4)', style: TextStyle(color: ht.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _createAndOpenNote('a4');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.all_out, color: ht.primary),
                  title: Text('New Drop (Infinite)', style: TextStyle(color: ht.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    _createAndOpenNote('infinite');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(HydropTheme ht) {
    return Drawer(
      backgroundColor: ht.sidebarBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Hydrop',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ht.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: !_showTrash ? ht.primary : ht.textSecondary),
              title: Text(
                'Root Oceans',
                style: TextStyle(
                  color: !_showTrash ? ht.primary : ht.textPrimary,
                  fontWeight: !_showTrash ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() => _showTrash = false);
                widget.workspace.setCurrentFolder(null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: _showTrash ? ht.error : ht.textSecondary),
              title: Text(
                'Trash',
                style: TextStyle(
                  color: _showTrash ? ht.error : ht.textPrimary,
                  fontWeight: _showTrash ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                setState(() => _showTrash = true);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            if (widget.themeController.isInk)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: PopupMenuButton<String>(
                  child: Row(
                    children: [
                      Icon(Icons.font_download_outlined, color: ht.textSecondary),
                      const SizedBox(width: 16),
                      Text('Change Font', style: TextStyle(color: ht.textPrimary)),
                    ],
                  ),
                  onSelected: (val) => widget.themeController.setInkFont(val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'Kalam', child: Text('Kalam (Default)')),
                    PopupMenuItem(value: 'Caveat', child: Text('Caveat')),
                    PopupMenuItem(value: 'Patrick Hand', child: Text('Patrick Hand')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);

    return ListenableBuilder(
      listenable: widget.workspace,
      builder: (context, child) {
        // --- Full Screen Canvas View ---
        if (widget.workspace.primaryNoteId != null) {
          final note = widget.workspace.notes.firstWhere(
            (n) => n.id == widget.workspace.primaryNoteId,
            orElse: () => widget.workspace.trashedNotes.firstWhere(
              (n) => n.id == widget.workspace.primaryNoteId,
            )
          );
          
          return Scaffold(
            backgroundColor: ht.background,
            appBar: AppBar(
              backgroundColor: ht.surface,
              elevation: 0,
              iconTheme: IconThemeData(color: ht.textPrimary),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => widget.workspace.closeNote(note.id),
              ),
              title: Text(
                note.title, 
                style: GoogleFonts.getFont(
                  ht.fontFamily,
                  color: ht.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => widget.workspace.closeNote(note.id), // Simple action
                )
              ],
            ),
            body: ClipRect(
              child: CanvasPage(workspace: widget.workspace, note: note),
            ),
          );
        }

        // --- Dashboard View ---
        final displayedFolders = _showTrash
            ? widget.workspace.trashedFolders
            : widget.workspace.folders
                  .where((f) => f.parentId == widget.workspace.currentFolderId)
                  .toList();

        final displayedNotes = _showTrash
            ? widget.workspace.trashedNotes
            : widget.workspace.notes
                  .where((n) => n.folderId == widget.workspace.currentFolderId)
                  .toList();

        String appBarTitle = _showTrash ? 'Trash' : 'Root Oceans';
        bool isSubFolder = false;
        String? parentId;
        
        if (!_showTrash && widget.workspace.currentFolderId != null) {
           final f = widget.workspace.folders.firstWhere((f) => f.id == widget.workspace.currentFolderId);
           appBarTitle = f.name;
           isSubFolder = true;
           parentId = f.parentId;
        }

        return Scaffold(
          backgroundColor: ht.background,
          appBar: AppBar(
            backgroundColor: ht.surface,
            elevation: 0,
            iconTheme: IconThemeData(color: ht.textPrimary),
            leading: isSubFolder
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      widget.workspace.setCurrentFolder(parentId);
                    },
                  )
                : null, // Default drawer icon
            title: Text(
              appBarTitle, 
              style: GoogleFonts.getFont(
                ht.fontFamily,
                color: ht.textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Focus search (placeholder)
                },
              )
            ],
          ),
          drawer: _buildDrawer(ht),
          floatingActionButton: FloatingActionButton(
            backgroundColor: ht.primary,
            onPressed: _showNewItemBottomSheet,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                
                if (displayedFolders.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Sub-Oceans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ht.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final folder = displayedFolders[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: EditableFolderCard(
                            title: folder.name,
                            isTrashed: folder.isTrashed,
                            onTap: () {
                              if (!folder.isTrashed) {
                                widget.workspace.setCurrentFolder(folder.id);
                              }
                            },
                            onDoubleTap: () {
                              if (!folder.isTrashed) {
                                widget.workspace.setCurrentFolder(folder.id);
                              }
                            },
                            onRename: (newName) => widget.workspace.renameFolder(folder.id, newName),
                            onDelete: () {
                              if (folder.isTrashed) {
                                widget.workspace.permanentlyDelete(folder.id, true);
                              } else {
                                widget.workspace.moveToTrash(folder.id, true);
                              }
                            },
                            onRestore: () => widget.workspace.restoreFromTrash(folder.id, true),
                            onMove: () {
                              widget.workspace.startMove(folder.id, 'folder');
                            },
                          ),
                        );
                      },
                      childCount: displayedFolders.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],

                if (displayedNotes.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Drops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: ht.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SliverMasonryGrid.extent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: displayedNotes.length,
                    itemBuilder: (context, index) {
                      final note = displayedNotes[index];
                      return EditableNoteCard(
                        note: note,
                        onTap: () {
                          if (!note.isTrashed) {
                            widget.workspace.openNote(note.id);
                          }
                        },
                        onRename: (newName) => widget.workspace.renameNote(note.id, newName),
                        onDelete: () {
                          if (note.isTrashed) {
                            widget.workspace.permanentlyDelete(note.id, false);
                          } else {
                            widget.workspace.moveToTrash(note.id, false);
                          }
                        },
                        onRestore: () => widget.workspace.restoreFromTrash(note.id, false),
                        onMove: () {
                          widget.workspace.startMove(note.id, 'note');
                        },
                        isTrashed: note.isTrashed,
                      );
                    },
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding for FAB
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
