# 2.5D Vibe Canvas User Flow

## The Core Concept
The user is presented with a canvas that acts like a physical drawing board slightly tilted away from them. When they draw, the ink extrudes out of the canvas like thick paint or clay.

---

### Step 1: Entering the Canvas
1. User opens a note or creates a new one.
2. The canvas renders immediately with the **Isometric Camera Tilt (Phase 3)**. The grid lines converge slightly in the distance, establishing the 2.5D depth.

### Step 2: The Live Drawing Experience
1. User selects the Pen tool and touches the screen.
2. As they drag, the `CanvasController` registers the raw touch points (with pressure).
3. The engine renders the stroke live. *Because the user is actively drawing, the stroke is drawn flat (no extrusion) to maintain 120Hz responsiveness.*
4. The ink line smoothly expands and contracts based on stylus pressure using `perfect_freehand`.

### Step 3: Stroke Finalization & Extrusion
1. The user lifts the stylus.
2. **Phase 1 Action:** The engine instantly runs the raw stroke points through the **RDP Simplifier**, deleting invisible micro-points.
3. **Phase 2 Action:** The engine switches the rendering of that specific stroke to the **Pseudo-3D Extrusion Engine**.
4. Visually, the moment the pen lifts, the flat ink instantly "pops up" from the canvas, gaining thick 3D side walls. This micro-interaction feels satisfying and physical.

### Step 4: Navigation and Caching
1. The user places two fingers on the screen to pan the canvas.
2. The `TransformationController` updates the matrix.
3. Because the finished 3D strokes are cached in memory via `PictureRecorder`, the entire 2.5D scene pans and zooms butter-smooth at 60-120 FPS.

### Step 5: Scene Interactivity
1. The user selects the `Select Tool` and taps an extruded stroke.
2. The hit-testing algorithm mathematically reverses the 3D tilt, successfully selecting the vector stroke.
3. The user rotates the stroke; the 3D walls visually adapt to the new angle in real-time.
