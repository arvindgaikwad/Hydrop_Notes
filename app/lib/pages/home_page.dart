import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/workspace.dart';
import '../controllers/workspace_controller.dart';
import 'canvas_page.dart';
import 'mobile_home_page.dart';
import '../widgets/editable_cards.dart';

import '../theme/hydrop_theme.dart';
import '../theme/theme_controller.dart';

void _showInstantMenu({
  required BuildContext context,
  required List<PopupMenuEntry<String>> items,
  required Function(String) onSelected,
}) async {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );
  final value = await showMenu<String>(
    context: context,
    position: position,
    items: items,
    popUpAnimationStyle: AnimationStyle(
      curve: Curves.easeOutQuart,
      duration: const Duration(milliseconds: 250),
    ),
  );
  if (value != null) {
    onSelected(value);
  }
}

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
  bool _isFirstBuild = true;

  String? _editingItemId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isFirstBuild) {
      _isFirstBuild = false;
      if (MediaQuery.of(context).size.width < 900) {
        _showSidebar = false;
      }
    }
  }

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
          appBar: null, /* AppBar(
            leading: IconButton(
              icon: Icon(Icons.menu, color: ht.textPrimary),
              onPressed: () {
                setState(() {
                  _showSidebar = !_showSidebar;
                });
              },
            ),
            title: Row(
              children: [
                Text(
                  'Hydrop',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ht.textPrimary,
                  ),
                ),
                if (!_showTrash) ...[
                  const SizedBox(width: 16),
                  Container(
                    height: 20,
                    width: 1.5,
                    color: ht.divider,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.home_outlined, size: 20, color: ht.textSecondary),
                  const SizedBox(width: 8),
                  Text('Root', style: TextStyle(color: ht.textSecondary, fontSize: 14)),
                  ...widget.workspace.currentFolderPath.map((f) => Row(
                        children: [
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: ht.divider),
                          const SizedBox(width: 4),
                          Text(f.name, style: TextStyle(color: ht.textSecondary, fontSize: 14)),
                        ],
                      )),
                ],
                if (_showTrash) ...[
                  const SizedBox(width: 16),
                  Container(
                    height: 20,
                    width: 1.5,
                    color: ht.divider,
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.delete_outline, size: 20, color: ht.error),
                  const SizedBox(width: 8),
                  Text('Trash', style: TextStyle(color: ht.error, fontSize: 14)),
                ],
                const Spacer(),
                // Filter Bar
                Container(
                  width: 250,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ht.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ht.divider),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(color: ht.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Filter...',
                      hintStyle: TextStyle(color: ht.sidebarTextSecondary, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 18, color: ht.sidebarTextSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
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
          ), */
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return MobileHomePage(
                  workspace: widget.workspace,
                  themeController: widget.themeController,
                );
              }
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
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.menu, color: ht.textPrimary),
                                            onPressed: () => setState(() => _showSidebar = !_showSidebar),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Hydrop',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 20,
                                              color: ht.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
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
                                          IconButton(
                                            icon: Icon(
                                              widget.workspace.isMultiSelectMode ? Icons.checklist : Icons.checklist_rtl,
                                              color: widget.workspace.isMultiSelectMode ? ht.primary : ht.sidebarTextSecondary,
                                              size: 18,
                                            ),
                                            onPressed: () => widget.workspace.toggleMultiSelectMode(),
                                            tooltip: widget.workspace.isMultiSelectMode ? 'Cancel Selection' : 'Select Multiple',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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
                                                  trailing: Builder(
                                                    builder: (context) => InkResponse(
                                                      radius: 16,
                                                      onTapDown: (_) {
                                                        _showInstantMenu(
                                                          context: context,
                                                          items: [
                                                            const PopupMenuItem(
                                                              value: 'add_folder',
                                                              child: Text('Add Ocean'),
                                                            ),
                                                            const PopupMenuItem(
                                                              value: 'add_note',
                                                              child: Text('Add Drop'),
                                                            ),
                                                          ],
                                                          onSelected: (value) {
                                                            widget.workspace.setCurrentFolder(null);
                                                            if (value == 'add_folder') {
                                                              _createNewFolder(context);
                                                            } else if (value == 'add_note') {
                                                              _createAndOpenNote('infinite');
                                                            }
                                                          },
                                                        );
                                                      },
                                                      onTap: () {},
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4.0),
                                                        child: Icon(Icons.more_vert, size: 16),
                                                      ),
                                                    ),
                                                  ),
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
                                                  onAddNote: () =>
                                                      _createAndOpenNote('infinite'),
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
                                    if (widget.workspace.isMultiSelectMode)
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: ht.surface,
                                          border: Border(top: BorderSide(color: ht.divider)),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              '${widget.workspace.selectedFolderIds.length + widget.workspace.selectedNoteIds.length} Selected',
                                              style: TextStyle(fontSize: 12, color: ht.textSecondary),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.delete, size: 18),
                                                  color: ht.error,
                                                  tooltip: 'Delete Selected',
                                                  onPressed: widget.workspace.bulkMoveToTrash,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.drive_file_move, size: 18),
                                                  color: ht.primary,
                                                  tooltip: 'Move Selected to Root',
                                                  onPressed: () => widget.workspace.bulkMove(null),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    const Divider(height: 1),
                                    PopupMenuButton<String>(
                                      tooltip: 'Select Theme',
                                      color: ht.surface,
                                      offset: const Offset(250, -50),
                                      onSelected: (val) {
                                        if (val == 'ink') widget.themeController.setInk();
                                        if (val == 'glass') widget.themeController.setGlass();
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'ink',
                                          child: Text('Ink Theme', style: TextStyle(color: ht.textPrimary)),
                                        ),
                                        PopupMenuItem(
                                          value: 'glass',
                                          child: Text('Glass Theme', style: TextStyle(color: ht.textPrimary)),
                                        ),
                                      ],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                                        color: ht.sidebarBackground,
                                        child: Row(
                                          children: [
                                            Icon(Icons.palette_outlined, color: ht.sidebarTextSecondary, size: 20),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Theme',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: ht.sidebarText,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              widget.themeController.isGlass ? 'Glass' : 'Ink',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: ht.sidebarTextSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.unfold_more, color: ht.sidebarTextSecondary, size: 16),
                                          ],
                                        ),
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
                            IconButton(
                              icon: Icon(Icons.menu, color: ht.textPrimary),
                              onPressed: () => setState(() => _showSidebar = !_showSidebar),
                            ),
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
                            // Theme menu
                            PopupMenuButton<String>(
                              tooltip: 'Select Theme',
                              color: ht.surface,
                              offset: const Offset(64, -50),
                              onSelected: (val) {
                                if (val == 'ink') widget.themeController.setInk();
                                if (val == 'glass') widget.themeController.setGlass();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'ink',
                                  child: Text('Ink Theme', style: TextStyle(color: ht.textPrimary)),
                                ),
                                PopupMenuItem(
                                  value: 'glass',
                                  child: Text('Glass Theme', style: TextStyle(color: ht.textPrimary)),
                                ),
                              ],
                              icon: Icon(
                                Icons.palette_outlined,
                                color: ht.sidebarTextSecondary,
                                size: 20,
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
                  if (widget.themeController.isInk)
                    Builder(
                      builder: (context) => InkResponse(
                        radius: 16,
                        onTapDown: (_) {
                          _showInstantMenu(
                            context: context,
                            items: const [
                              PopupMenuItem(value: 'Kalam', child: Text('Kalam (Default)')),
                              PopupMenuItem(value: 'Caveat', child: Text('Caveat')),
                              PopupMenuItem(value: 'Patrick Hand', child: Text('Patrick Hand')),
                              PopupMenuItem(value: 'Indie Flower', child: Text('Indie Flower')),
                              PopupMenuItem(value: 'Shadows Into Light', child: Text('Shadows Into Light')),
                              PopupMenuItem(value: 'Gochi Hand', child: Text('Gochi Hand')),
                            ],
                            onSelected: (val) => widget.themeController.setInkFont(val),
                          );
                        },
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.font_download_outlined,
                            color: ht.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (widget.themeController.isInk) const SizedBox(width: 8),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: ht.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
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
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 32.0, right: 32.0, top: 32.0),
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
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                                maxCrossAxisExtent: 400,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 3.5,
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
                        SliverMasonryGrid.extent(
                          maxCrossAxisExtent: 250,
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
          ),
        ],
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
  final VoidCallback? onAddNote;

  const _FolderTreeItem({
    required this.folder,
    required this.workspace,
    this.depth = 0,
    this.editingItemId,
    required this.onClearEditing,
    this.onFolderSelected,
    this.onAddFolder,
    this.onAddNote,
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
        Builder(
          builder: (context) => InkResponse(
            radius: 16,
            onTapDown: (_) {
              _showInstantMenu(
                context: context,
                items: [
                  const PopupMenuItem(
                    value: 'add_folder',
                    child: Text('Add Sub-Ocean'),
                  ),
                  const PopupMenuItem(
                    value: 'add_note',
                    child: Text('Add Drop'),
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
                onSelected: (value) {
                  if (value == 'add_folder') {
                    widget.workspace.setCurrentFolder(widget.folder.id);
                    widget.onAddFolder?.call();
                  } else if (value == 'add_note') {
                    widget.workspace.setCurrentFolder(widget.folder.id);
                    widget.onAddNote?.call();
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
              );
            },
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.more_vert, size: 16),
            ),
          ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (widget.workspace.isMultiSelectMode) {
              widget.workspace.toggleFolderSelection(widget.folder.id);
            } else {
              widget.onFolderSelected?.call();
              widget.workspace.setCurrentFolder(widget.folder.id);
              if (widget.workspace.primaryNoteId != null) {
                widget.workspace.closeNote(widget.workspace.primaryNoteId!);
              }
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
              if (showActions)
                widget.workspace.isMultiSelectMode
                    ? Checkbox(
                        value: widget.workspace.selectedFolderIds.contains(widget.folder.id),
                        onChanged: (val) => widget.workspace.toggleFolderSelection(widget.folder.id),
                        visualDensity: VisualDensity.compact,
                        activeColor: ht.primary,
                      )
                    : _buildTrailingActions(),
            ],
          ),
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
                      onAddNote: widget.onAddNote,
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
    return Builder(
      builder: (context) => InkResponse(
        radius: 16,
        onTapDown: (_) {
          _showInstantMenu(
            context: context,
            items: [
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
          );
        },
        onTap: () {},
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: Icon(Icons.more_vert, size: 16),
        ),
      ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (widget.workspace.isMultiSelectMode) {
              widget.workspace.toggleNoteSelection(widget.note.id);
            } else {
              widget.workspace.openNote(widget.note.id);
            }
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
                widget.workspace.isMultiSelectMode
                    ? Checkbox(
                        value: widget.workspace.selectedNoteIds.contains(widget.note.id),
                        onChanged: (val) => widget.workspace.toggleNoteSelection(widget.note.id),
                        visualDensity: VisualDensity.compact,
                        activeColor: ht.primary,
                      )
                    : _buildTrailingActions(),
              ],
            ),
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
