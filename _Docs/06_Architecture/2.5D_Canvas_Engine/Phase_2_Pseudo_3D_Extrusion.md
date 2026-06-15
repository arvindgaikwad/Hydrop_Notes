# Phase 2: Pseudo-3D Extrusion Engine

## Goal
To transform flat 2D vector brush strokes into thick, 3D-looking extruded blocks using layered `CustomPainter` drawing operations, while strictly guarding against GPU overload.

## Technical Context
We simulate 3D by drawing a darkened "wall" layer several times, shifting the coordinates slightly down and to the right, and capping it off with the bright, original top layer. 

> [!WARNING]
> Because the Operator's top priority is **zero lag and low battery heating**, this phase must be heavily optimized.

## Implementation Steps

1. **Y-Sorting Collision (The Painter's Algorithm)**
   - Before painting, the engine MUST sort all strokes by their physical Y-coordinate on the canvas. 
   - Without this, strokes lower on the screen might be drawn first, causing strokes "behind" them to overlap incorrectly and shatter the 3D illusion.

2. **Modify the Native Painter (`lib/painters/canvas_painter.dart`)**
   - Update `_drawStroke` to handle the layered loop.
   - Calculate shadow color: Multiply `stroke.color` RGB by 0.6.
   - Limit the loop. Do not exceed `extrusionDepth = 5`. (e.g., `for (int i = 5; i > 0; i--)`).
   - Inside the loop, `canvas.save()`, `canvas.translate(0, i * 1.0)`, `canvas.drawPath(stroke.path, shadowPaint)`, `canvas.restore()`.
   - Draw the original top cap at `(0, 0)`.

3. **Modify the Web Painter (`lib/pages/hybrid_canvas/canvas_web.dart`)**
   - Adapt the HTML5 `_ctx!.lineTo` loop to draw the darkened shadow lines shifted down, followed by the bright top line.

## Success Criteria
- [ ] Strokes look like thick 3D blocks.
- [ ] Y-sorting correctly layers strokes to maintain depth perspective.
- [ ] The extrusion loop is hard-capped to prevent excessive draw calls.
