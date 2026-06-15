# Phase 3: Isometric Camera Rotation & Hit-Testing

## Goal
To tilt the drawing canvas in 3D space, creating an isometric tabletop perspective, while ensuring the user can accurately select the distorted 3D strokes.

## Technical Context
Flutter's `Transform` widget allows us to apply a `Matrix4`. By applying an X and Y axis rotation alongside a perspective value, the 2D drawing space leans backward.

## Implementation Steps

1. **Update the Rendering Matrix**
   - Before applying the user's pan/zoom matrix, inject the 3D tilt matrix.
   - `Matrix4 tilt = Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(0.4)..rotateY(0.1);`
   - Multiply the panning matrix by the tilt matrix: `final Matrix4 finalMatrix = tilt * panZoomMatrix;`

2. **Reverse Hit-Testing (Mathematical Correction)**
   - When the screen is tilted, tapping `(100, 100)` on the glass no longer maps to `(100, 100)` on the virtual canvas.
   - The incoming local screen coordinates must be multiplied by the **inverse** of the `finalMatrix` using `Matrix4.invert()`.

3. **Hit-Testing the Extrusion Walls**
   - A stroke now has a 3D wall protruding downwards.
   - If a user taps the wall, standard 2D path hit-testing will fail because the wall is outside the original `Path`.
   - The hit-test collision box MUST be artificially expanded vertically by the `extrusionDepth` amount to ensure the user can reliably select the physical 3D object without missing.

## Success Criteria
- [ ] The canvas is permanently tilted.
- [ ] The user can successfully select a stroke by tapping on its extruded side-wall, not just the top cap.
- [ ] Hit-testing remains 100% accurate regardless of camera zoom or pan.
