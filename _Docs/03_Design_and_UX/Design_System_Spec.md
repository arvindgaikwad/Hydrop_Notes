# 🎨 Horizon Notes — Design System Specification (Neo-Skeuomorphic)

> **Phase:** Implementation (Active Development)  
> **Status:** LIVE — Matches `lib/theme/theme.dart`  
> **Design Language:** Neo-Skeuomorphic ("Tactile Blueprint")  
> **Last Updated:** June 12, 2026

---

## 1️⃣ Design Philosophy

**"Tactile Blueprint."** The UI feels like a hand-drawn wireframe come to life on textured paper. Every surface has physical presence — buttons raise off the page, pressed tools sink into it, and panels sit in recessed wells. The palette is monochromatic: warm off-white paper and dark ink. No flashy gradients, no glassmorphism, no backdrop blur.

**Core Principles:**
- **Paper & Ink:** The entire UI is built on two materials — warm paper and dark ink. Nothing else.
- **Tactile States:** Every interactive element has a physical state: raised (default), pressed (inset), or recessed (panel).
- **Monochromatic Clarity:** One color for surfaces (paper), one for content (ink). Accent is muted grey. This forces hierarchy through weight, size, and depth — not color.
- **Crisp Borders:** 2px ink borders on all interactive surfaces. This is the defining visual trait of the system.

**Inspiration References:**
- Field Notes notebooks — textured paper, bold ink borders
- Dieter Rams (Braun) — honest materials, tactile controls
- Paper prototyping — the beauty of a wireframe before it becomes "designed"

---

## 2️⃣ Color Palette (Monochromatic — Light Only v1)

| Token | Hex | Dart Constant | Usage |
|:---|:---|:---|:---|
| `paperBackground` | `#F4F2EC` | `AppTheme.paperBackground` | Primary surface — app background, canvas, toolbars |
| `ink` | `#2D2D2D` | `AppTheme.ink` | All text, borders, icons, and active elements |
| `insetBackground` | `#E8E4D9` | `AppTheme.insetBackground` | Pressed/inset areas — active buttons, recessed panels |
| `accent` | `#6B7280` | `AppTheme.accent` | Muted grey for inactive/unselected tool icons |
| `primary` | `#2D2D2D` | `AppTheme.primary` | Alias for `ink` — used for primary actions |
| `gridLine` | `#DCD8CE` | `AppTheme.gridLine` | Subtle dividers, grid lines, borders on cards |
| `textSecondary` | `#64748B` | `AppTheme.textSecondary` | Descriptions, timestamps, metadata |
| `textDisabled` | `#94A3B8` | `AppTheme.textDisabled` | Placeholders, disabled text, section labels |
| `error` | `#EF4444` | `AppTheme.error` | Destructive actions (delete, trash) |

> [!NOTE]
> There is no dark mode in v1. A future dark variant would use a different skeuomorphic metaphor (chalkboard, dark leather) rather than simple color inversion.

---

## 3️⃣ Typography

**Font Family:** `Delicious Handrawn` (via Google Fonts). This font perfectly matches the Neo-Skeuomorphic "Tactile Blueprint" aesthetic by providing an organic, hand-sketched feel to all UI text. It is an open-source font licensed under the SIL Open Font License (OFL), making it 100% free for commercial use.

| Weight | Dart Constant | Token | Usage |
|:---|:---|:---|:---|
| 400 (Regular) | `AppTheme.fontRegular` | `fontRegular` | Body text, descriptions, labels |
| 500 (Medium) | `AppTheme.fontMedium` | `fontMedium` | Tool labels, inactive items, section headers |
| 700 (Bold) | `AppTheme.fontBold` | `fontBold` | Active tool labels, selected items, titles |

**Key Rules:**
- Tool button labels use 8px font size
- Layer info text uses 10px
- Card titles use 16px with `fontBold`
- Card subtitles use 12px
- Section headers (dashboard) use 18px with `w600`
- Page titles use 24px with `fontBold`

---

## 4️⃣ Spacing & Grid

### Spatial Scale (8pt Grid System)

| Token | Value | Dart Constant | Usage |
|:---|:---|:---|:---|
| `space4` | 4px | `AppTheme.space4` | Tight padding (color picker items, flyout panels) |
| `space8` | 8px | `AppTheme.space8` | Inner toolbar padding, tool spacing |
| `space12` | 12px | `AppTheme.space12` | Icon-to-text gaps |
| `space16` | 16px | `AppTheme.space16` | Card inner padding, sidebar padding |
| `space24` | 24px | `AppTheme.space24` | Divider width, grid cross-axis spacing |
| `space32` | 32px | `AppTheme.space32` | Dashboard page padding, section gaps |
| `space48` | 48px | `AppTheme.space48` | Tool button dimensions (48×48px) |

### Border Radii

| Token | Value | Dart Constant | Usage |
|:---|:---|:---|:---|
| `radiusSm` | 4px | `AppTheme.radiusSm` | Small elements, drag feedback |
| `radiusMd` | 8px | `AppTheme.radiusMd` | Note card icon containers |
| `radiusLg` | 12px | `AppTheme.radiusLg` | Buttons, inset panels, pressed states |
| `radiusXl` | 20px | `AppTheme.radiusXl` | Floating toolbars, raised surfaces |

### Border Weights

| Token | Value | Dart Constant | Usage |
|:---|:---|:---|:---|
| `borderSide1px` | 1px ink | `AppTheme.borderSide1px` | Color swatches, subtle borders |
| `borderSide2px` | 2px ink | `AppTheme.borderSide2px` | **Primary border** — all interactive surfaces |
| `borderSide4px` | 4px ink | `AppTheme.borderSide4px` | Heavy emphasis (reserved) |

---

## 5️⃣ Surface Decorators (Tactile States)

These are the four core `BoxDecoration` presets that define the Neo-Skeuomorphic language. All interactive surfaces must use one of these — never raw `Material` elevation or backdrop blur.

### `raisedSurface` — Floating Panels & Toolbars
```
Background: paperBackground (#F4F2EC)
Border:     2px solid ink (#2D2D2D)
Radius:     radiusXl (20px)
Shadow:     level2 — ink at 20% alpha, blur 8, offset (0, 4)
```
Used by: Drawing toolbar, eraser flyout, select flyout

### `buttonDefault` — Unpressed Buttons
```
Background: paperBackground (#F4F2EC)
Border:     2px solid ink (#2D2D2D)
Radius:     radiusLg (12px)
Shadow:     level1 — ink at 15% alpha, blur 4, offset (0, 2)
```
Used by: Default button state (reserved for future use)

### `buttonPressed` — Active/Pressed Buttons
```
Background: insetBackground (#E8E4D9)
Border:     2px solid ink (#2D2D2D)
Radius:     radiusLg (12px)
Shadow:     NONE (simulates pushing down into the paper)
```
Used by: Active tool indicator in the toolbar

### `insetSurface` — Recessed Panels
```
Background: insetBackground (#E8E4D9)
Border:     2px solid ink (#2D2D2D)
Radius:     radiusLg (12px)
Shadow:     NONE (relies on darker bg + border for depth)
```
Used by: Minimap, active layer indicator in layers panel

---

## 6️⃣ Elevation (Shadow System)

| Level | Alpha | Blur | Offset | Usage |
|:---|:---|:---|:---|:---|
| `level1Shadow` | ink @ 15% | 4px | (0, 2) | Subtle lift — default buttons |
| `level2Shadow` | ink @ 20% | 8px | (0, 4) | Medium lift — floating toolbars |
| `level3Shadow` | ink @ 25% | 16px | (0, 8) | Heavy lift — drag feedback, overlays |

> [!IMPORTANT]
> Never use Flutter's `Material` widget elevation system. All elevation is achieved through the `BoxShadow` system defined above. This ensures visual consistency with the ink-border aesthetic.

---

## 7️⃣ Iconography

- **Source:** Flutter Material Icons (`Icons.*`)
- **Size:** 20px default (tool buttons), 16px compact (sidebar actions), 24px standard (color swatches)
- **Color (active):** `ink` (`#2D2D2D`)
- **Color (inactive):** `accent` (`#6B7280`)
- **Color (disabled):** `ink` at 20% alpha

---

## 8️⃣ Component Styles

### Floating Toolbar (Canvas)
```
┌──────────────────────────────────────────┐
│  ☰  ↩  ↪  │  ☞  ✏  ✦  T  🖼  ✋  │  ● ▬ │
└──────────────────────────────────────────┘

Decoration:  raisedSurface
Padding:     8px (space8)
Position:    Dockable — left, right, top, or bottom
Tool Size:   48×48px per tool button
Active Tool: buttonPressed decoration (inset bg, no shadow)
Inactive:    Transparent bg, accent-colored icon
Dividers:    1px ink at 10% alpha
```

### Notebook Card (Home Grid)
```
┌─────────────────────────┐
│  [Icon]          [···]  │  ← 40×40 icon container (radiusMd)
│                         │
│                         │
│  Biology 301            │  ← 16px, fontBold
│  12 strokes             │  ← 12px, black54
└─────────────────────────┘

Background:  surface (paperBackground)
Border:      1px solid gridLine
Radius:      16px
Shadow:      black at 3% alpha, blur 10, offset (0, 4)
Aspect:      0.8 (portrait)
```

### Folder Card (Home Grid)
```
┌──────────────────────────────────────┐
│  📁  │  Project Alpha        [···]  │
└──────────────────────────────────────┘

Background:  surface (paperBackground)
Border:      1px solid gridLine
Radius:      16px
Padding:     16px left/top/bottom, 8px right
Aspect:      2.5 (landscape)
```

### Layers Panel
```
Header:      Bottom border 2px ink
Layer Item:  Bottom border 1px ink (inactive) / insetSurface (active)
Visibility:  ink (visible) / ink at 30% (hidden)
Width:       280px fixed
```

### Minimap
```
Decoration:  insetSurface
Size:        200×150px
Clip:        radiusLg (12px) via ClipRRect
Viewport:    2px ink stroke rectangle
```

### Color Picker (Radial Dial)
```
Swatch:      40×40 circle, 2px ink border, raisedSurface shadow
Inner Ring:  80×80 circle, 4px ink border
Indicator:   16×16 circle, paperBackground fill, 2px ink border
Animation:   300ms easeOutBack, radius expands to 80px
```

---

## 9️⃣ Motion & Animation

| Animation | Duration | Easing | Usage |
|:---|:---|:---|:---|
| Toolbar dock transition | 300ms | `easeOutCubic` | Toolbar moves between docked positions |
| Tool container state | 200ms | linear | `AnimatedContainer` for active/inactive tool switch |
| Button press | 150ms | linear | `AnimatedContainer` for button state transitions |
| Flyout expand/collapse | 200ms | `easeOutCubic` | Select/Eraser sub-menus opening |
| Color dial burst | 300ms | `easeOutBack` | Radial color picker expansion |
| Toolbar alignment | 300ms | `easeOutCubic` | `AnimatedAlign` for dock position changes |

---

## 🔟 Canvas-Specific Design Rules

1. **Canvas background:** `paperBackground` (`#F4F2EC`) — warm, paper-like. No dot grid, no dark background.
2. **Default ink color:** `ink` (`#2D2D2D`) — near-black on warm paper for maximum contrast.
3. **Eraser modes:** Pixel Eraser (`BlendMode.clear`) and Stroke Eraser (point-intersection math).
4. **Selection:** Lasso tool draws polygon, ray-casting calculates enclosed objects. Bounding box rendered with ink.
5. **Minimap:** `insetSurface` decoration — sits recessed into the paper. Viewport shown as 2px ink rectangle.
6. **Zoom/Pan:** Native `InteractiveViewer` with constrained scale (0.1x–5.0x).
7. **Layer system:** Multi-layer support with per-layer visibility toggle. Active layer highlighted with `insetSurface`.

---

## 1️⃣1️⃣ Screen Implementation Status

| Priority | Screen | Status |
|:---|:---|:---|
| 1 | Canvas — Active State (Drawing) | ✅ Built |
| 2 | Canvas — Empty State | ✅ Built |
| 3 | Home / Notebooks Grid | ✅ Built |
| 4 | Tool Palette — Dockable Toolbar | ✅ Built |
| 5 | Layers Panel | ✅ Built |
| 6 | Minimap | ✅ Built |
| 7 | Color Picker (Radial Dial) | ✅ Built |
| 8 | Split View (Dual Canvas) | ✅ Built |
| 9 | Sidebar (Folder Tree + Trash) | ✅ Built |
| 10 | Pro Upgrade / Paywall | ⏳ Pending |
| 11 | Onboarding (3 Screens) | ⏳ Pending |
| 12 | Settings / Account | ⏳ Pending |

---
#design-system #neo-skeuomorphic #horizon-notes #live
