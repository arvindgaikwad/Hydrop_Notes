# HYDROP_NOTES - AI AGENT RULES

You are an AI Agent assisting in the development of the Hydrop_Notes Flutter application.
You MUST strictly adhere to the architecture defined in `architecture.md`.

## 🚨 ZERO-TRUST ARCHITECTURE COMPLIANCE 🚨
Before generating ANY code, you must read and comply with the following rules:

1. **Strict Directory Separation**:
   - `lib/models/`: ONLY pure Dart data classes and Hive CE TypeAdapters. NO State Management or UI.
   - `lib/controllers/`: ONLY State Management (`ChangeNotifier`, `ValueNotifier`). This is the "Brain".
   - `lib/widgets/`: ONLY reusable, stateless, or locally-stateful UI components.
   - `lib/pages/`: ONLY full-screen structural views.
   - `lib/painters/`: ONLY CustomPainter logic for rendering canvas graphics.
   - `lib/theme/`: ONLY UI tokens (colors, typography, spacing).

2. **No Business/Heavy Logic in UI**:
   - UI widgets must NOT contain business, export, or heavy processing logic. They must delegate actions to Controllers.
   - Do not pass heavy models directly into Deep UI trees if a localized ValueNotifier is sufficient.
   - Heavily side-effecting operations (like PDF generation or file system operations) must be placed in specialized utility controllers (e.g., `ExportController` in `lib/controllers/`).

3. **Two-Phase Interactive Transformations (Performance & Rendering)**:
   - High-frequency canvas operations (e.g., dragging, resizing, or rotating selections) MUST be split into a two-phase pipeline to maintain 60/120fps rendering:
     - **Phase 1 (Live Drag)**: Update *only* the bounding box `Rect` and accumulate `_pending` transformations. Use `selectionDragOffsetNotifier` and a lightweight `SelectionDragPainter` to render visual offset shifts without mutating the underlying data points.
     - **Phase 2 (Commit)**: Apply the accumulated translation, scaling, and rotation to the underlying model structures (`Stroke`, `TextNode`, `ImageNode`) *only* when the gesture completes (`onTransformEnd`).
     - **Cache Invalidation**: When mutating geometry on a model that caches its path representation (like `Stroke`), you must invoke `invalidateCache()` to ensure the painter renders the updated geometric path.

4. **Self-Auditing**:
   - If you are asked to "build a feature", first verify which files are needed.
   - If your generated code places a Controller in `lib/models/` or UI logic in `lib/controllers/`, you have FAILED. Correct it immediately.

5. **Dual-Theme Architecture Compliance**:
   - The app uses a dual-theme system (`HydropTheme`) supporting both `InkTheme` (Neo-Skeuomorphic) and `GlassTheme` (Fluid Glass).
   - NEVER use static theme constants (like `AppTheme.color`) or raw hex values (`Color(0xFF...)`) in UI code.
   - ALWAYS use the injected theme context (`HydropTheme.of(context)`) for all colors, decorations, and radii.
   - For backdrop blurs, ALWAYS use `HydropTheme.of(context).applyBackdrop()` which automatically handles theme-specific rendering (pass-through for Ink, blurred for Glass).

Always acknowledge these rules when undertaking a new sprint.

6. **Render Pipeline & Accessibility Stability (`AXTree`)**:
   - Flutter's Windows Accessibility Bridge (`AXTree`) is exceptionally sensitive to layout exceptions and rapid semantic tree rebuilds.
   - **Constraint Integrity**: NEVER allow layout constraints to become impossibly tight or negative (e.g., animating a `SizedBox` to 0 width without an `OverflowBox` and `ClipRect`). Layout exceptions mid-frame abort the rendering pipeline and permanently corrupt the `AXTree` state, requiring a full app restart.
   - **Semantic Pruning**: For high-frequency interactive surfaces containing thousands of visual elements (like the infinite canvas), ALWAYS wrap the structural boundaries in `ExcludeSemantics`. This prevents the engine from traversing and rebuilding massive semantic trees 120 times a second.
   - **Repaint Isolation**: Prefer `CustomPaint` with isolated repainting over broad `ListenableBuilder` rebuilds for continuous inputs (cursors, selection marquees) to preserve the structural integrity of the widget tree during live drag operations.
