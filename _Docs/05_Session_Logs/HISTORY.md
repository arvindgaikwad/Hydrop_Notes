# 🏰 Horizon Notes: The Archive of Ascension

> *"The mind that can retrieve, synthesize, and connect — while the masses outsource their thinking to machines — that mind is the most dangerous weapon on Earth."* - Sherlock

This ledger documents the architectural milestones and system evolutions of **Horizon Notes**.

---

## 📅 June 12, 2026: The Neo-Skeuomorphic Pivot (Leonardo & Daedalus Protocol)
**Objective:** Complete visual overhaul — abandon the original "Expansive Minimalism" / glassmorphic dark-mode aesthetic and replace with a **Neo-Skeuomorphic** design language.

### Design System Transformation
- **Old System ("Horizon Premium"):**
  - Dark-mode-first (`#0A0A0A` backgrounds)
  - Glassmorphic toolbars (85% opacity + 24px backdrop blur)
  - Indigo accent color (`#6366F1`)
  - Outfit font family
  - Frosted glass floating panels
- **New System ("Neo-Skeuomorphic Ink Kit"):**
  - Warm paper background (`#F4F2EC`)
  - Monochromatic palette (ink `#2D2D2D` on paper)
  - Tactile surface states: raised, pressed (inset), and recessed
  - 2px ink borders on all interactive surfaces
  - System-native font, Material Icons
  - Zero glassmorphism — every surface is opaque paper

### Key Implementations
1. **`theme.dart` Token System**: `AppTheme` class with `raisedSurface`, `buttonDefault`, `buttonPressed`, `insetSurface` BoxDecoration presets.
2. **All widgets refactored**: Drawing toolbar, color picker, editable cards, layers panel, minimap — all using the new surface states.
3. **Documentation sync**: All research, design, strategy, and handoff documentation updated to match the implemented design.

---

## 📅 June 11, 2026: The Canvas Object Expansion (Daedalus & Demiurge Protocol)
**Objective:** Evolve the pure sketching surface into a unified Canvas Object System without compromising the 60fps rendering pipeline.

### Core Architectural Upgrades
- **The Native Stack Architecture (`canvas_native.dart`)**: 
  - Overhauled the infinite canvas to utilize Flutter's native `InteractiveViewer`.
  - Layered rendering system established: Images (Bottom) -> Strokes (Middle) -> Text (Top) -> Selection Bounds (Overlay).
- **Interactive Widgets**:
  - Implemented `TextNodeWidget` and `ImageNodeWidget` as native Flutter widgets embedded directly onto the canvas, guaranteeing infinite scalability and hardware-accelerated crispness.
- **Local File System Integration**:
  - Images are saved directly to the local Windows file system via `file_picker` to prevent catastrophic RAM spikes from Hive box bloat.

### Feature Implementations
1. **Text Nodes (The Scribe)**: 
   - Double-tap text to inline edit on the canvas. 
   - Native `TextField` auto-scaling based on canvas zoom.
2. **Image Insertion (The Canvas)**:
   - File picker integration (`image_node_widget.dart`).
   - Image scaling and error boundary protection.
3. **Lasso Selection (The Conductor)**:
   - Ray-casting algorithm implemented in `canvas_controller.dart` (`_isPointInPolygon`) to calculate which strokes, text, and images fall within a drawn polygon.
   - Bounding box rendering.
   - Unified pan-gesture translation (moving all selected objects simultaneously).

---

## 📅 June 11, 2026: Note Management & Data Preservation (Demiurge Protocol)
**Objective:** Build enterprise-grade file operations with a focus on data security (anti-loss).

### Feature Implementations
1. **Soft Deletion (The Trash Bin)**:
   - Altered `Folder` and `NoteDocument` Hive schemas to include `@HiveField(isTrashed)`.
   - Created a persistent **Trash** view in the Sidebar.
   - Trashed items are hidden from normal views but retain their infinite-hierarchy metadata for perfect restoration.
2. **Inline Renaming (Native UX)**:
   - Removed interruptive dialog boxes for renaming files.
   - Created `EditableFolderCard` and `EditableNoteCard` to transform text into `TextFields` dynamically.
3. **Context Menus**:
   - Implemented Right-Click/Long-Press menus for Sidebar folders.
   - Implemented `...` menus for main view cards.

---

## 📅 June 10-11, 2026: The Foundation (Daedalus & Leonardo Protocol)
**Objective:** Establish the Core Infinite Canvas and Hive Local Database.

### System Deployments
- **Hive Persistence (`workspace.dart`)**:
  - Registered TypeAdapters for complex objects (`Offset`, `Color`, `Stroke`, `Folder`).
  - Built `WorkspaceController` for `Provider` state management.
- **The Infinite Canvas (`canvas_page.dart`)**:
  - `CustomPainter` with `PointMode.polygon` for hyper-efficient 60fps stroke rendering.
  - Hybrid Canvas interface preparing for Web (`globalCompositeOperation`) vs Native (`saveLayer`) erasing differences.
- **The Drawing Tools (`drawing_toolbar.dart`)**:
  - Glassmorphic floating toolbar.
  - Pixel Eraser (BlendMode.clear) vs Stroke Eraser (Point-intersection math).
  - Premium predefined color palettes.

---
*End of Archive. The Palace continues to grow.*
