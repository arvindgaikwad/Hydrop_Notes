# Horizon Notes: Architecture Blueprint

This document defines the core architecture for the Horizon Notes Infinite Canvas application. It establishes the "skeleton" to ensure that future vibe-coding and agentic iterations build upon a solid, scalable foundation rather than accruing technical debt.

## 1. Core State Management Strategy
We are avoiding heavy third-party dependencies (like Riverpod or Bloc) to keep the application lean and native. We use Flutter's built-in reactive primitives.

- **Global State (`ChangeNotifier`)**: Used for data that affects the entire application lifecycle (e.g., `WorkspaceController` managing folders, notes, and routing between documents).
- **Canvas State (`ChangeNotifier` + `ValueNotifier`)**: The `CanvasController` acts as the brain for the active document.
  - **Granular Rebuilds**: We use `ValueNotifier` for high-frequency updates (e.g., `layersNotifier`, `selectionNotifier`) so only specific UI components rebuild during interactions.
  - **Real-Time Performance**: `ActiveStrokeNotifier` isolates the drawing of the *current* stroke to prevent the entire canvas from repainting at 60fps/120fps.

## 2. Data Persistence (Hive CE)
Hive CE (Community Edition) is our local NoSQL database. 
- **Models**: `Folder`, `NoteDocument`, `CanvasLayer`, `Stroke`, `StrokePoint`, `TextNode`, `ImageNode`.
- **Flow**: The `WorkspaceController` reads/writes to Hive boxes (`folders`, `notes`). The `CanvasController` operates entirely in-memory for performance (Undo/Redo stacks) and only commits its final `layers` array to the `WorkspaceController` on save or exit.

## 3. Directory Structure (The Skeleton)
The project is strictly separated to prevent UI from handling business logic:

```text
lib/
├── models/             # Pure Dart data classes and Hive TypeAdapters
├── controllers/        # State Management (WorkspaceController, CanvasController)
├── pages/              # Full-screen route views (HomePage, CanvasPage)
├── painters/           # CustomPaint delegates (CanvasPainter, MinimapPainter)
├── widgets/            # Reusable UI components (Toolbar, BoundingBoxOverlay)
├── theme/              # Design Tokens: Colors, Typography, Spacing (theme.dart)
└── main.dart           # App entry point and Hive initialization
```

## 4. UI vs Logic Separation Rule
- **Widgets are Dumb**: UI components (like `CanvasNative` or `CanvasPage`) should **never** manipulate stroke data directly or calculate bounding boxes. They listen to `ValueNotifier`s and pass user input (Gestures) directly to the `CanvasController`.
- **Controllers are Smart**: The `CanvasController` handles all math (matrix transformations, lasso intersections, bounding box calculations).

## 5. Design Tokens & Dual-Theme Architecture (HydropTheme)
We use a dynamic theming system that supports both the classic "Neo-Skeuomorphic Ink" and modern "Fluid Glass" aesthetics.

### Architecture Rules
1. **Never use static theme constants** (e.g., `AppTheme.color`).
2. **Never use raw magic hex values** like `Color(0xFF...)` in UI code.
3. **Always use the injected theme context**: All colors, radii, borders, shadows, and spacing must be pulled dynamically using `HydropTheme.of(context)`.

### Theme Layers
- `HydropTheme` (Abstract Interface): Defines all the design tokens (e.g., `surface`, `primary`, `background`, `divider`, `textPrimary`).
- `InkTheme` (Concrete Implementation): Fills the blueprint with neo-skeuomorphic paper textures, sharp borders, and flat styling.
- `GlassTheme` (Concrete Implementation): Fills the blueprint with vibrant gradients, translucent surfaces, and modern soft styling.
- `ThemeController` (`ChangeNotifier`): Manages the currently active theme state. The app root uses `HydropThemeProvider` (an `InheritedWidget`) to inject the theme down the widget tree.

### Decorators (Mandatory for all interactive UI)
Instead of manually building BoxDecorations, use the getters provided by `HydropTheme.of(context)`:
- `ht.toolbarDecoration` — For floating toolbars and panels.
- `ht.buttonDefault` — For default button states.
- `ht.buttonPressed` — For active/pressed states.
- `ht.insetSurface` — For recessed/inner panels (like the minimap).

> **RULE:** UI components must remain agnostic to *which* theme is active. The widget tree simply asks for `ht.surface` and the active theme implementation dictates whether it's a flat paper color or a glassy translucent gradient.
