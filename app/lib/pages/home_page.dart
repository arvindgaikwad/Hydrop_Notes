import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/workspace.dart';
import '../controllers/workspace_controller.dart';
import 'canvas_page.dart';
import '../widgets/editable_cards.dart';

import '../theme/hydrop_theme.dart';
import '../theme/theme_controller.dart';

class HomePage extends StatefulWidget {
  final WorkspaceController workspace;
  final ThemeController themeController;

  const HomePage({
    super.key,
    required this.workspace,
    required this.themeController,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showTrash = false;
  bool _showSidebar = true;
  double _splitRatio = 0.5;

  String? _editingItemId;

  void _createNewFolder(BuildContext context) async {
    final newFolder = await widget.workspace.createFolder('New Ocean');
    setState(() {
      _showTrash = false;
      _editingItemId = newFolder.id;
    });
  }

  void _createAndOpenNote(String canvasType) {
    String title = 'Drop';
    if (canvasType == 'infinite') {
      title = 'Complete Infinite Drop';
    } else if (canvasType == 'limited_infinite') {
      title = 'Limited Infinite Drop';
    } else if (canvasType == 'a4') {
      title = 'A4 Size Drop';
    }
    final newNote = widget.workspace.createNote(title, canvasType: canvasType);
    widget.workspace.openNote(newNote.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.workspace,
      builder: (context, child) {
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

        final ht = HydropTheme.of(context);
        return Container(
          decoration: ht.appBackgroundDecoration,
          child: Scaffold(
            backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.menu, color: ht.textPrimary),
              onPressed: () {
                setState(() {
                  _showSidebar = !_showSidebar;
                });
              },
            ),
            title: Text(
              'Hydrop',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ht.textPrimary,
              ),
            ),
            backgroundColor: ht.surface,
            flexibleSpace: ht.applyBackdrop(Container()),
            actions: [
              if (widget.themeController.isInk)
                PopupMenuButton<String>(
                  tooltip: 'Change Handwriting Font',
                  icon: Icon(
                    Icons.font_download_outlined,
                    color: ht.textPrimary,
                  ),
                  onSelected: (val) => widget.themeController.setInkFont(val),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'Kalam',
                      child: Text('Kalam (Default)'),
                    ),
                    PopupMenuItem(value: 'Caveat', child: Text('Caveat')),
                    PopupMenuItem(
                      value: 'Patrick Hand',
                      child: Text('Patrick Hand'),
                    ),
                    PopupMenuItem(
                      value: 'Indie Flower',
                      child: Text('Indie Flower'),
                    ),
                    PopupMenuItem(
                      value: 'Shadows Into Light',
                      child: Text('Shadows Into Light'),
                    ),
                    PopupMenuItem(
                      value: 'Gochi Hand',
                      child: Text('Gochi Hand'),
                    ),
                  ],
                ),
            ],
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              ClipRect(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _showSidebar ? 251.0 : 64.0,
                  height: constraints.maxHeight,
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  firstCurve: Curves.easeInOut,
                  secondCurve: Curves.easeInOut,
                  crossFadeState: _showSidebar
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  // ── FULL SIDEBAR ──────────────────────────────────────────
                  firstChild: SizedBox(
                    height: constraints.maxHeight,
                    child: OverflowBox(
                      minWidth: 251,
                      maxWidth: 251,
                      minHeight: constraints.maxHeight,
                      maxHeight: constraints.maxHeight,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 251,
                        height: constraints.maxHeight,
                        child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ht.applyBackdrop(
                            Material(
                              color: ht.sidebarBackground,
                              child: SizedBox(
                                width: 250,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16.0,
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Oceans',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: ht.sidebarTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView(
                                        children: [
                                          DragTarget<Map<String, dynamic>>(
                                            onAcceptWithDetails: (details) {
                                              final data = details.data;
                                              if (data['type'] == 'folder') {
                                                widget.workspace.moveFolder(
                                                  data['id'],
                                                  null,
                                                );
                                              } else if (data['type'] == 'note') {
                                                widget.workspace.moveNote(
                                                  data['id'],
                                                  null,
                                                );
                                              }
                                              widget.workspace.cancelMove();
                                            },
                                            builder: (context, candidateData, rejectedData) {
                                              return Container(
                                                color: candidateData.isNotEmpty
                                                    ? ht.sidebarSelected.withValues(
                                                        alpha: 0.1,
                                                      )
                                                    : null,
                                                child: ListTile(
                                                  leading: Icon(
                                                    widget.workspace.currentFolderId ==
                                                                null &&
                                                            !_showTrash
                                                        ? Icons.home
                                                        : Icons.home_outlined,
                                                    color:
                                                        widget
                                                                    .workspace
                                                                    .currentFolderId ==
                                                                null &&
                                                            !_showTrash
                                                        ? ht.sidebarSelected
                                                        : ht.sidebarTextSecondary,
                                                  ),
                                                  title: Text(
                                                    'Root',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          widget
                                                                      .workspace
                                                                      .currentFolderId ==
                                                                  null &&
                                                              !_showTrash
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                      color:
                                                          widget
                                                                      .workspace
                                                                      .currentFolderId ==
                                                                  null &&
                                                              !_showTrash
                                                          ? ht.sidebarSelected
                                                          : ht.sidebarText,
                                                    ),
                                                  ),
                                                  selected:
                                                      widget
                                                              .workspace
                                                              .currentFolderId ==
                                                          null &&
                                                      !_showTrash,
                                                  selectedTileColor: ht.sidebarSelected
                                                      .withValues(alpha: 0.1),
                                                  onTap: () {
                                                    setState(() => _showTrash = false);
                                                    widget.workspace.setCurrentFolder(
                                                      null,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          ...(widget.workspace.folders
                                                  .where(
                                                    (f) =>
                                                        f.parentId == null &&
                                                        !f.isTrashed,
                                                  )
                                                  .toList()
                                                ..sort(
                                                  (a, b) => a.name
                                                      .toLowerCase()
                                                      .compareTo(b.name.toLowerCase()),
                                                ))
                                              .map(
                                                (f) => _FolderTreeItem(
                                                  folder: f,
                                                  workspace: widget.workspace,
                                                  editingItemId: _editingItemId,
                                                  onClearEditing: () => setState(
                                                    () => _editingItemId = null,
                                                  ),
                                                  onFolderSelected: () => setState(
                                                    () => _showTrash = false,
                                                  ),
                                                  onAddFolder: () =>
                                                      _createNewFolder(context),
                                                ),
                                              ),
                                          ...(widget.workspace.notes
                                                  .where(
                                                    (n) =>
                                                        n.folderId == null &&
                                                        !n.isTrashed,
                                                  )
                                                  .toList()
                                                ..sort(
                                                  (a, b) => a.title
                                                      .toLowerCase()
                                                      .compareTo(b.title.toLowerCase()),
                                                ))
                                              .map(
                                                (n) => _NoteTreeItem(
                                                  note: n,
                                                  workspace: widget.workspace,
                                                  depth: 0,
                                                  editingItemId: _editingItemId,
                                                  onClearEditing: () => setState(
                                                    () => _editingItemId = null,
                                                  ),
                                                ),
                                              ),
                                          const Divider(),
                                          ListTile(
                                            leading: Icon(
                                              _showTrash
                                                  ? Icons.delete
                                                  : Icons.delete_outline,
                                              color: _showTrash
                                                  ? ht.error
                                                  : ht.sidebarTextSecondary,
                                            ),
                                            title: Text(
                                              'Trash',
                                              style: TextStyle(
                                                fontWeight: _showTrash
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                                color: _showTrash
                                                    ? ht.error
                                                    : ht.sidebarText,
                                              ),
                                            ),
                                            selected: _showTrash,
                                            selectedTileColor: ht.error.withValues(
                                              alpha: 0.05,
                                            ),
                                            onTap: () {
                                              setState(() => _showTrash = true);
                                              widget.workspace.setCurrentFolder(null);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(height: 1),
                                    Container(
                                      padding: const EdgeInsets.all(16.0),
                                      color: ht.sidebarBackground,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Theme',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: ht.sidebarTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: SegmentedButton<bool>(
                                              segments: const [
                                                ButtonSegment(
                                                  value: false,
                                                  label: Text(
                                                    'Ink',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  icon: Icon(Icons.edit, size: 16),
                                                ),
                                                ButtonSegment(
                                                  value: true,
                                                  label: Text(
                                                    'Glass',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  icon: Icon(
                                                    Icons.water_drop,
                                                    size: 16,
                                                  ),
                                                ),
                                              ],
                                              selected: {
                                                widget.themeController.isGlass,
                                              },
                                              onSelectionChanged:
                                                  (Set<bool> newSelection) {
                                                    if (newSelection.first !=
                                                        widget
                                                            .themeController
                                                            .isGlass) {
                                                      widget.themeController.toggle();
                                                    }
                                                  },
                                              style: ButtonStyle(
                                                visualDensity: VisualDensity.compact,
                                                backgroundColor:
                                                    WidgetStateProperty.resolveWith<
                                                      Color
                                                    >((states) {
                                                      if (states.contains(
                                                        WidgetState.selected,
                                                      )) {
                                                        return ht.primary.withValues(
                                                          alpha: 0.15,
                                                        );
                                                      }
                                                      return Colors.transparent;
                                                    }),
                                                foregroundColor:
                                                    WidgetStateProperty.resolveWith<
                                                      Color
                                                    >((states) {
                                                      if (states.contains(
                                                        WidgetState.selected,
                                                      )) {
                                                        return ht.primary;
                                                      }
                                                      return ht.sidebarText;
                                                    }),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        VerticalDivider(width: 1, thickness: 1, color: ht.divider),
                      ],
                    ),
                  ),
                  ),
                  ),
                  // ── ICON RAIL (collapsed) ────────────────────────────────
                  secondChild: SizedBox(
                    height: constraints.maxHeight,
                    child: OverflowBox(
                      minWidth: 64,
                      maxWidth: 64,
                      minHeight: constraints.maxHeight,
                      maxHeight: constraints.maxHeight,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 64,
                        height: constraints.maxHeight,
                        child: ht.applyBackdrop(
                      Material(
                        color: ht.sidebarBackground,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // Home
                            Tooltip(
                              message: 'Root',
                              child: IconButton(
                                icon: Icon(
                                  widget.workspace.currentFolderId == null && !_showTrash
                                      ? Icons.home
                                      : Icons.home_outlined,
                                  color: widget.workspace.currentFolderId == null && !_showTrash
                                      ? ht.sidebarSelected
                                      : ht.sidebarTextSecondary,
                                ),
                                onPressed: () {
                                  setState(() => _showTrash = false);
                                  widget.workspace.setCurrentFolder(null);
                                },
                              ),
                            ),
                            // Root-level folder icons
                            ...widget.workspace.folders
                                .where((f) => f.parentId == null && !f.isTrashed)
                                .take(6)
                                .map(
                                  (f) => Tooltip(
                                    message: f.name,
                                    child: IconButton(
                                      icon: Icon(
                                        widget.workspace.currentFolderId == f.id
                                            ? Icons.folder
                                            : Icons.folder_outlined,
                                        color: widget.workspace.currentFolderId == f.id
                                            ? ht.sidebarSelected
                                            : ht.sidebarTextSecondary,
                                        size: 22,
                                      ),
                                      onPressed: () {
                                        setState(() => _showTrash = false);
                                        widget.workspace.setCurrentFolder(f.id);
                                      },
                                    ),
                                  ),
                                ),
                            const Spacer(),
                            // Trash
                            Tooltip(
                              message: 'Trash',
                              child: IconButton(
                                icon: Icon(
                                  _showTrash ? Icons.delete : Icons.delete_outline,
                                  color: _showTrash ? ht.error : ht.sidebarTextSecondary,
                                ),
                                onPressed: () {
                                  setState(() => _showTrash = true);
                                  widget.workspace.setCurrentFolder(null);
                                },
                              ),
                            ),
                            // Theme toggle
                            Tooltip(
                              message: widget.themeController.isGlass ? 'Switch to Ink' : 'Switch to Glass',
                              child: IconButton(
                                icon: Icon(
                                  widget.themeController.isGlass
                                      ? Icons.water_drop
                                      : Icons.edit_outlined,
                                  color: ht.sidebarTextSecondary,
                                  size: 20,
                                ),
                                onPressed: () => widget.themeController.toggle(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            VerticalDivider(width: 1, thickness: 1, color: ht.divider),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ), // OverflowBox
                  ),
                ),
              ),
              ), // ClipRect

              Expanded(
                child: widget.workspace.primaryNoteId != null
                    ? _buildCanvasView()
                    : _buildDashboard(
                        displayedFolders,
                        displayedNotes,
                        context,
                      ),
              ),
            ],
          );
          }),
          floatingActionButton: widget.workspace.primaryNoteId != null
              ? (widget.workspace.movingItemId != null
                  ? FloatingActionButton.extended(
                      onPressed: () => widget.workspace.cancelMove(),
                      label: const Text('Cancel Move'),
                      icon: const Icon(Icons.cancel),
                      backgroundColor: HydropTheme.of(context).error,
                      foregroundColor: Colors.white,
                    )
                  : null)
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.workspace.movingItemId != null)
                FloatingActionButton.extended(
                  onPressed: () => widget.workspace.cancelMove(),
                  label: const Text('Cancel Move'),
                  icon: const Icon(Icons.cancel),
                  backgroundColor: HydropTheme.of(context).error,
                  foregroundColor: Colors.white,
                ),
              if (widget.workspace.movingItemId == null)
                Builder(
                  builder: (ctx) => FloatingActionButton(
                    onPressed: () async {
                      final RenderBox button = ctx.findRenderObject() as RenderBox;
                      final RenderBox overlay = Navigator.of(ctx).overlay!.context.findRenderObject() as RenderBox;
                      final RelativeRect position = RelativeRect.fromRect(
                        Rect.fromPoints(
                          button.localToGlobal(Offset.zero, ancestor: overlay),
                          button.localToGlobal(
                            button.size.bottomRight(Offset.zero),
                            ancestor: overlay,
                          ),
                        ),
                        Offset.zero & overlay.size,
                      );
                      final String? selected = await showMenu<String>(
                        context: ctx,
                        position: position,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        items: [
                          PopupMenuItem<String>(
                            value: 'infinite',
                            child: Row(
                              children: [
                                Icon(Icons.all_out, size: 20, color: HydropTheme.of(ctx).primary),
                                const SizedBox(width: 12),
                                const Text('Infinite Canvas'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'limited_infinite',
                            child: Row(
                              children: [
                                Icon(Icons.crop_free, size: 20, color: HydropTheme.of(ctx).primary),
                                const SizedBox(width: 12),
                                const Text('Limited Infinite Canvas'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'a4',
                            child: Row(
                              children: [
                                Icon(Icons.description_outlined, size: 20, color: HydropTheme.of(ctx).primary),
                                const SizedBox(width: 12),
                                const Text('A4 Size Page'),
                              ],
                            ),
                          ),
                        ],
                      );
                      if (selected != null) {
                        _createAndOpenNote(selected);
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                ),
            ],
          ),
        ),);
      },
    );
  }

  Widget _buildCanvasView() {
    final primaryNote = widget.workspace.notes.firstWhere(
      (n) => n.id == widget.workspace.primaryNoteId,
      orElse: () => NoteDocument(id: '', title: 'Error'),
    );

    if (widget.workspace.secondaryNoteId != null) {
      final secondaryNote = widget.workspace.notes.firstWhere(
        (n) => n.id == widget.workspace.secondaryNoteId,
        orElse: () => NoteDocument(id: '', title: 'Error'),
      );
      return LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final dividerWidth = 16.0;
          final availableWidth = totalWidth - dividerWidth;

          final leftWidth = availableWidth * _splitRatio;
          final rightWidth = availableWidth * (1 - _splitRatio);

          return Row(
            children: [
              SizedBox(
                width: leftWidth,
                child: _buildCanvasWrapper(primaryNote),
              ),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    final newRatio =
                        _splitRatio + (details.delta.dx / availableWidth);
                    final minRatio = 100.0 / availableWidth;
                    final maxRatio = 1.0 - minRatio;
                    _splitRatio = newRatio.clamp(minRatio, maxRatio);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    width: dividerWidth,
                    color: HydropTheme.of(
                      context,
                    ).divider.withValues(alpha: 0.1),
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 32,
                        decoration: BoxDecoration(
                          color: HydropTheme.of(context).divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: rightWidth,
                child: _buildCanvasWrapper(secondaryNote),
              ),
            ],
          );
        },
      );
    }

    return _buildCanvasWrapper(primaryNote);
  }

  void _selectNoteForSplitView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final availableNotes = widget.workspace.notes
            .where(
              (n) => n.id != widget.workspace.primaryNoteId && !n.isTrashed,
            )
            .toList();
        return AlertDialog(
          title: const Text('Select Note for Split View'),
          content: SizedBox(
            width: double.maxFinite,
            child: availableNotes.isEmpty
                ? const Text('No other notes available.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableNotes.length,
                    itemBuilder: (context, index) {
                      final n = availableNotes[index];
                      return ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(n.title),
                        onTap: () {
                          widget.workspace.openNote(n.id, asSecondary: true);
                          setState(() {
                            _showSidebar = false;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCanvasWrapper(NoteDocument note) {
    final isPrimary = widget.workspace.primaryNoteId == note.id;
    final isSplit = widget.workspace.secondaryNoteId != null;
    final ht = HydropTheme.of(context);

    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: ht.surface,
            border: Border(bottom: BorderSide(color: ht.divider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Back button (only shown on primary non-split view)
                  if (isPrimary && !isSplit)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: ht.textPrimary,
                      ),
                      tooltip: 'Back to dashboard',
                      onPressed: () => widget.workspace.closeNote(note.id),
                    ),
                  if (isSplit)
                    Icon(
                      isPrimary ? Icons.looks_one : Icons.looks_two,
                      size: 16,
                      color: ht.sidebarTextSecondary,
                    ),
                  if (isSplit) const SizedBox(width: 8),
                  _CanvasHeaderTitle(note: note, workspace: widget.workspace),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPrimary && !isSplit)
                    Tooltip(
                      message: 'Split View',
                      child: InkWell(
                        onTap: () => _selectNoteForSplitView(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: ht.divider),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.vertical_split_rounded, size: 15, color: ht.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Split',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: ht.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (isSplit) const SizedBox(width: 4),
                  if (isSplit)
                    Tooltip(
                      message: 'Close panel',
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: ht.textSecondary,
                        ),
                        onPressed: () => widget.workspace.closeNote(note.id),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: ClipRect(
            child: CanvasPage(workspace: widget.workspace, note: note),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(
    List<Folder> displayedFolders,
    List<NoteDocument> displayedNotes,
    BuildContext context,
  ) {
    final ht = HydropTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showTrash
                    ? 'Trash Bin'
                    : widget.workspace.currentFolderId == null
                    ? 'Root Oceans'
                    : widget.workspace.folders
                          .firstWhere(
                            (f) => f.id == widget.workspace.currentFolderId,
                            orElse: () => Folder(id: '', name: 'Deleted'),
                          )
                          .name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ht.textPrimary,
                ),
              ),
              if (!_showTrash)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _createNewFolder(context),
                      icon: const Icon(Icons.waves),
                      label: const Text('New Ocean'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: displayedFolders.isEmpty && displayedNotes.isEmpty
                ? Center(
                    child: Text(
                      'This Ocean is empty. Create a Sub-Ocean or Drop!',
                      style: TextStyle(
                        color: ht.textSecondary,
                      ),
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      if (displayedFolders.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Sub-Oceans',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: HydropTheme.of(context).textSecondary,
                              ),
                            ),
                          ),
                        ),
                        SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 250,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 2.5,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final folder = displayedFolders[index];
                            final isMovingThis =
                                widget.workspace.movingItemId == folder.id;
                            Widget card = EditableFolderCard(
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
                                if (widget.workspace.primaryNoteId != null) {
                                  widget.workspace.closeNote(
                                    widget.workspace.primaryNoteId!,
                                  );
                                }
                              },
                              onRename: (newName) => widget.workspace
                                  .renameFolder(folder.id, newName),
                              onDelete: () {
                                if (folder.isTrashed) {
                                  widget.workspace.permanentlyDelete(
                                    folder.id,
                                    true,
                                  );
                                } else {
                                  widget.workspace.moveToTrash(folder.id, true);
                                }
                              },
                              onRestore: () => widget.workspace
                                  .restoreFromTrash(folder.id, true),
                              onMove: () {
                                widget.workspace.startMove(folder.id, 'folder');
                              },
                            );

                            if (isMovingThis) {
                              card = Draggable<Map<String, dynamic>>(
                                data: {'type': 'folder', 'id': folder.id},
                                feedback: Opacity(
                                  opacity: 0.7,
                                  child: SizedBox(width: 200, child: card),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: card,
                                ),
                                child: card,
                              );
                            }

                            return DragTarget<Map<String, dynamic>>(
                              onAcceptWithDetails: (details) {
                                final data = details.data;
                                if (data['type'] == 'folder') {
                                  widget.workspace.moveFolder(
                                    data['id'],
                                    folder.id,
                                  );
                                } else if (data['type'] == 'note') {
                                  widget.workspace.moveNote(
                                    data['id'],
                                    folder.id,
                                  );
                                }
                                widget.workspace.cancelMove();
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: candidateData.isNotEmpty
                                        ? Border.all(
                                            color: HydropTheme.of(
                                              context,
                                            ).primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: card,
                                );
                              },
                            );
                          }, childCount: displayedFolders.length),
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
                                color: HydropTheme.of(context).textSecondary,
                              ),
                            ),
                          ),
                        ),
                        SliverMasonryGrid.count(
                          crossAxisCount: 3,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childCount: displayedNotes.length,
                          itemBuilder: (context, index) {
                            final note = displayedNotes[index];
                            final isMovingThis = widget.workspace.movingItemId == note.id;
                            
                            Widget card = EditableNoteCard(
                              note: note,
                              onTap: () {
                                if (!note.isTrashed) {
                                  widget.workspace.openNote(note.id);
                                  setState(() {
                                    _showSidebar = false;
                                  });
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

                            if (isMovingThis) {
                              card = Draggable<Map<String, dynamic>>(
                                data: {'type': 'note', 'id': note.id},
                                feedback: Opacity(
                                  opacity: 0.7,
                                  child: SizedBox(width: 200, child: card),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: card,
                                ),
                                child: card,
                              );
                            }

                            return DragTarget<Map<String, dynamic>>(
                              onAcceptWithDetails: (details) {
                                final data = details.data;
                                if (data['type'] == 'folder') {
                                  widget.workspace.moveFolder(data['id'], note.folderId);
                                } else if (data['type'] == 'note') {
                                  widget.workspace.moveNote(data['id'], note.folderId);
                                }
                                widget.workspace.cancelMove();
                              },
                              builder: (context, candidateData, rejectedData) {
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: candidateData.isNotEmpty
                                        ? Border.all(
                                            color: HydropTheme.of(context).primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: card,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FolderTreeItem extends StatefulWidget {
  final Folder folder;
  final WorkspaceController workspace;
  final int depth;
  final String? editingItemId;
  final VoidCallback onClearEditing;
  final VoidCallback? onFolderSelected;
  final VoidCallback? onAddFolder;

  const _FolderTreeItem({
    required this.folder,
    required this.workspace,
    this.depth = 0,
    this.editingItemId,
    required this.onClearEditing,
    this.onFolderSelected,
    this.onAddFolder,
  });

  @override
  State<_FolderTreeItem> createState() => _FolderTreeItemState();
}

class _FolderTreeItemState extends State<_FolderTreeItem> {
  bool _isExpanded = true;
  late bool _isEditing;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editingItemId == widget.folder.id;
    _textController = TextEditingController(text: widget.folder.name);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitRename();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _FolderTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingItemId != oldWidget.editingItemId) {
      final shouldEdit = widget.editingItemId == widget.folder.id;
      if (_isEditing != shouldEdit) {
        _isEditing = shouldEdit;
        if (_isEditing) {
          _textController.text = widget.folder.name;
          _focusNode.requestFocus();
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _textController.text = widget.folder.name;
    });
    _focusNode.requestFocus();
  }

  void _commitRename() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    final newName = _textController.text.trim();
    if (newName.isNotEmpty && newName != widget.folder.name) {
      widget.workspace.renameFolder(widget.folder.id, newName);
    } else {
      _textController.text = widget.folder.name;
    }
    widget.onClearEditing();
  }

  Widget _buildTrailingActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          padding: EdgeInsets.zero,
          tooltip: 'Options',
          onSelected: (value) {
            if (value == 'add_folder') {
              widget.workspace.setCurrentFolder(widget.folder.id);
              widget.onAddFolder?.call();
            } else if (value == 'rename') {
              _startEditing();
            } else if (value == 'delete') {
              widget.workspace.moveToTrash(widget.folder.id, true);
              if (widget.workspace.currentFolderId == widget.folder.id) {
                widget.workspace.setCurrentFolder(null);
              }
            } else if (value == 'move') {
              widget.workspace.startMove(widget.folder.id, 'folder');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add_folder',
              child: Text('Add Sub-Ocean'),
            ),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(value: 'move', child: Text('Move')),
            PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete',
                style: TextStyle(color: HydropTheme.of(context).error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final children =
        widget.workspace.folders
            .where((f) => f.parentId == widget.folder.id && !f.isTrashed)
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final childNotes =
        widget.workspace.notes
            .where((n) => n.folderId == widget.folder.id && !n.isTrashed)
            .toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
    final isSelected = widget.folder.id == widget.workspace.currentFolderId;
    final showActions = true;
    final ht = HydropTheme.of(context);

    final titleWidget = _isEditing
        ? TextField(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: true,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? ht.sidebarSelected : ht.sidebarText,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _commitRename(),
          )
        : Text(
            widget.folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? ht.sidebarSelected : ht.sidebarText,
              fontSize: 14,
            ),
          );

    final rowContent = Material(
      color: isSelected
          ? ht.sidebarSelected.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onFolderSelected?.call();
          widget.workspace.setCurrentFolder(widget.folder.id);
        },
        onDoubleTap: () {
          if (widget.workspace.primaryNoteId != null) {
            widget.workspace.closeNote(widget.workspace.primaryNoteId!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Row(
            children: [
              SizedBox(width: widget.depth * 16.0),
              if (children.isNotEmpty || childNotes.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      color: ht.sidebarTextSecondary,
                      size: 18,
                    ),
                  ),
                )
              else
                const SizedBox(width: 24, height: 24),
              const SizedBox(width: 4),
              Icon(
                _isExpanded && (children.isNotEmpty || childNotes.isNotEmpty)
                    ? Icons.folder_open_rounded
                    : Icons.folder_rounded,
                color: isSelected
                    ? ht.sidebarSelected
                    : ht.sidebarTextSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: titleWidget),
              if (showActions) _buildTrailingActions(),
            ],
          ),
        ),
      ),
    );

    Widget content;

    if (children.isEmpty && childNotes.isEmpty) {
      content = rowContent;
    } else {
      content = Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            rowContent,
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Column(
                children: [
                  ...children.map(
                    (childFolder) => _FolderTreeItem(
                      folder: childFolder,
                      workspace: widget.workspace,
                      depth: widget.depth + 1,
                      editingItemId: widget.editingItemId,
                      onClearEditing: widget.onClearEditing,
                      onFolderSelected: widget.onFolderSelected,
                      onAddFolder: widget.onAddFolder,
                    ),
                  ),
                  ...childNotes.map(
                    (childNote) => _NoteTreeItem(
                      note: childNote,
                      workspace: widget.workspace,
                      depth: widget.depth + 1,
                      editingItemId: widget.editingItemId,
                      onClearEditing: widget.onClearEditing,
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 100),
            ),
          ],
        ),
      );
    }

    final isMovingThis = widget.workspace.movingItemId == widget.folder.id;
    Widget draggableContent = isMovingThis
        ? Draggable<Map<String, dynamic>>(
            data: {'type': 'folder', 'id': widget.folder.id},
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.7,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ht.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ht.primary),
                  ),
                  child: Text(
                    widget.folder.name,
                    style: TextStyle(color: ht.textPrimary),
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: content),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: ht.primary, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: content,
            ),
          )
        : content;

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final data = details.data;
        if (data['type'] == 'folder') {
          widget.workspace.moveFolder(data['id'], widget.folder.id);
        } else if (data['type'] == 'note') {
          widget.workspace.moveNote(data['id'], widget.folder.id);
        }
        widget.workspace.cancelMove();
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: candidateData.isNotEmpty
              ? ht.sidebarSelected.withValues(alpha: 0.1)
              : null,
          child: draggableContent,
        );
      },
    );
  }
}

class _NoteTreeItem extends StatefulWidget {
  final NoteDocument note;
  final WorkspaceController workspace;
  final int depth;
  final String? editingItemId;
  final VoidCallback onClearEditing;

  const _NoteTreeItem({
    required this.note,
    required this.workspace,
    this.depth = 0,
    this.editingItemId,
    required this.onClearEditing,
  });

  @override
  State<_NoteTreeItem> createState() => _NoteTreeItemState();
}

class _NoteTreeItemState extends State<_NoteTreeItem> {
  late bool _isEditing;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editingItemId == widget.note.id;
    _textController = TextEditingController(text: widget.note.title);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitRename();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NoteTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingItemId != oldWidget.editingItemId) {
      final shouldEdit = widget.editingItemId == widget.note.id;
      if (_isEditing != shouldEdit) {
        _isEditing = shouldEdit;
        if (_isEditing) {
          _textController.text = widget.note.title;
          _focusNode.requestFocus();
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _textController.text = widget.note.title;
    });
    _focusNode.requestFocus();
  }

  void _commitRename() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    final newName = _textController.text.trim();
    if (newName.isNotEmpty && newName != widget.note.title) {
      widget.workspace.renameNote(widget.note.id, newName);
    } else {
      _textController.text = widget.note.title;
    }
    widget.onClearEditing();
  }

  Widget _buildTrailingActions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 16),
      padding: EdgeInsets.zero,
      tooltip: 'Options',
      onSelected: (value) {
        if (value == 'split_view') {
          widget.workspace.openNote(widget.note.id, asSecondary: true);
        } else if (value == 'rename') {
          _startEditing();
        } else if (value == 'move') {
          widget.workspace.startMove(widget.note.id, 'note');
        } else if (value == 'delete') {
          widget.workspace.moveToTrash(widget.note.id, false);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'split_view',
          child: Text('Open in Split View'),
        ),
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'move', child: Text('Move')),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: HydropTheme.of(context).error),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    final isSelected = widget.note.id == widget.workspace.primaryNoteId ||
        widget.note.id == widget.workspace.secondaryNoteId;

    final titleWidget = _isEditing
        ? TextField(
            controller: _textController,
            focusNode: _focusNode,
            autofocus: true,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? ht.sidebarSelected : ht.sidebarText,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _commitRename(),
          )
        : Text(
            widget.note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? ht.sidebarSelected : ht.sidebarText,
              fontSize: 14,
            ),
          );

    Widget content = Material(
      color: isSelected
          ? ht.sidebarSelected.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.workspace.openNote(widget.note.id);
        },
        onDoubleTap: _startEditing,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Row(
            children: [
              SizedBox(width: widget.depth * 16.0),
              const SizedBox(width: 24, height: 24), // Chevron placeholder
              const SizedBox(width: 4),
              Icon(
                Icons.description_outlined,
                color: isSelected ? ht.sidebarSelected : ht.sidebarTextSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: titleWidget),
              _buildTrailingActions(),
            ],
          ),
        ),
      ),
    );

    final isMovingThis = widget.workspace.movingItemId == widget.note.id;
    if (isMovingThis) {
      content = Draggable<Map<String, dynamic>>(
        data: {'type': 'note', 'id': widget.note.id},
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.7,
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ht.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ht.primary),
              ),
              child: Text(
                widget.note.title,
                style: TextStyle(color: ht.textPrimary),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: content),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: ht.primary, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _CanvasHeaderTitle extends StatefulWidget {
  final NoteDocument note;
  final WorkspaceController workspace;

  const _CanvasHeaderTitle({required this.note, required this.workspace});

  @override
  State<_CanvasHeaderTitle> createState() => _CanvasHeaderTitleState();
}

class _CanvasHeaderTitleState extends State<_CanvasHeaderTitle> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.note.title);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitRename();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CanvasHeaderTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.note.title != widget.note.title) {
      _controller.text = widget.note.title;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitRename() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    final newName = _controller.text.trim();
    if (newName.isNotEmpty && newName != widget.note.title) {
      widget.workspace.renameNote(widget.note.id, newName);
    } else {
      _controller.text = widget.note.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ht = HydropTheme.of(context);
    if (_isEditing) {
      return SizedBox(
        width: 200,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          style: TextStyle(fontWeight: FontWeight.w600, color: ht.textPrimary),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _commitRename(),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _isEditing = true);
        _focusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Text(
          widget.note.title,
          style: TextStyle(fontWeight: FontWeight.w600, color: ht.textPrimary),
        ),
      ),
    );
  }
}
