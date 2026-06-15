# Phase 4: Extreme Performance & Data Constraints

## Goal
To absolutely guarantee **low RAM usage, zero lag, and low battery heating** (The Operator's primary mandate). Visuals must never compromise hardware stability.

## Technical Context
Storing thousands of vectors, applying 3D matrices, and rendering multi-layer extrusions will destroy mobile CPUs/GPUs if left unchecked. We must implement defensive fallbacks and aggressive memory management.

## Implementation Steps

1. **The Battery / Performance Kill-Switch**
   - Implement a "Vibe Mode" toggle in the UI (Flat 2D vs Isometric 2.5D).
   - If the device drops below 30 FPS or RAM usage spikes, the app must gracefully fallback to Flat 2D Mode. The 3D Matrix and Extrusion loops are instantly bypassed.

2. **RAM-Optimized Picture Flattening**
   - **The Danger:** Caching every single stroke into its own `Picture` object will eat hundreds of megabytes of RAM.
   - **The Solution:** We will flatten inactive background strokes into a single, unified `CanvasLayer` Picture. Instead of rendering 5,000 extruded strokes, the GPU renders exactly **one** flattened image for the background, while only the active/selected strokes remain as dynamic vector paths.

3. **Data Persistence (Hive Schema)**
   - Update `Stroke` model in `lib/models/stroke.dart`.
   - Add `@HiveField(9, defaultValue: 0) final int extrusionDepth;`
   - Add `@HiveField(10, defaultValue: false) final bool isExtruded;`
   - This ensures that if the user toggles Flat Mode, the structural data of the note remains intact and syncs safely to the database without data loss.

## Success Criteria
- [ ] RAM usage remains under 150MB regardless of canvas size.
- [ ] The device does not overheat during prolonged drawing sessions.
- [ ] The Kill-Switch instantly disables all expensive GPU mathematics.
