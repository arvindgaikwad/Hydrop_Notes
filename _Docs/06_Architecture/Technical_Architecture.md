# 🏗️ Technical Architecture Decision: Infinite Canvas + Cloud Sync

> **Date:** 2026-05-30  
> **Status:** APPROVED  
> **Core Principle:** The canvas IS the product. If the canvas lags, the app dies.

---

## 1️⃣ The Canvas: How We Build It

### The Decision: Pure Flutter for V1 → Hybrid Native Upgrade in V1.1

**V1 MVP Stack:**
```
  Flutter (CustomPaint + perfect_freehand + InteractiveViewer)
  ├── Build time: ~2-3 weeks for the canvas
  ├── Total app time: ~5 months
  ├── Latency: ~20-35ms (acceptable for launch)
  └── Platform: Android + iOS from one codebase
```

**V1.1 Upgrade (If power users complain about latency):**
```
  Flutter UI + Native Canvas (Hybrid)
  ├── iOS: PencilKit (Apple Pencil perfection, ~9ms latency)
  ├── Android: SurfaceView + Canvas API + S-Pen SDK
  ├── Extra build time: +1-2 months
  └── Result: Same feel as Samsung Notes / GoodNotes
```

### Why This Approach:
- Ship fast with Flutter V1, get users, validate the product
- Only invest in native canvas rewrite AFTER proving product-market fit
- Don't over-engineer before you have paying users

---

## 2️⃣ Canvas Architecture: The 3-Layer Stack

### Layer 1: Platform Frameworks (Given to you for free)

| Platform | Framework | What It Provides |
|:---|:---|:---|
| **iOS** | PencilKit | Apple Pencil pressure/tilt, palm rejection, low-latency rendering, built-in tools |
| **Android** | Canvas API + SurfaceView | GPU-accelerated drawing, stylus events, hardware acceleration |
| **Flutter** | CustomPaint + InteractiveViewer | 2D drawing surface + built-in pan/zoom |

### Layer 2: Open-Source Libraries (The building blocks)

| Library | What It Does | Platform |
|:---|:---|:---|
| **`perfect_freehand`** | Generates beautiful, smooth strokes from raw input points | Cross-platform (Dart) |
| **`pencil_kit` Flutter plugin** | Embeds Apple's PencilKit inside Flutter | iOS via Flutter |
| **`flutter_drawing_board`** | Ready-made drawing canvas with tools | Flutter |
| **`InteractiveViewer`** | Built-in Flutter widget for infinite pan + zoom | Flutter |
| **Samsung S-Pen SDK** | Palm rejection + advanced stylus features on Galaxy devices | Android |

### Layer 3: What YOU Actually Code (~30% of canvas work)

```
  YOUR CODE:
  ├── Make canvas boundary = NONE (no edges, infinite in all directions)
  ├── Stroke rasterization (convert finished strokes to cached bitmap images)
  ├── Viewport culling (only render strokes visible on screen)
  ├── Level of Detail (simplified rendering when zoomed out far)
  ├── Save stroke data as JSON for cloud sync
  └── Connect your custom toolbar UI to the drawing engine
```

---

## 3️⃣ The 3 Performance Optimizations (MUST HAVE)

Without these, the canvas WILL lag on notebooks with 50+ pages:

### Optimization 1: Stroke Rasterization
```
  PROBLEM:  Each stroke = vector path = GPU must redraw it every frame
  SOLUTION: After pen is lifted, "bake" the stroke into a static bitmap
  RESULT:   Old strokes cost ZERO GPU cycles. Only the CURRENT stroke is live.
```

### Optimization 2: Viewport Culling
```
  PROBLEM:  500 strokes on canvas. GPU tries to render ALL of them every frame.
  SOLUTION: Calculate which strokes are inside the visible screen rectangle.
            Only render those. Ignore everything off-screen.
  RESULT:   Whether you have 100 or 10,000 strokes, performance is the same.
```

### Optimization 2.5: Dual-Page / Split-View Support
```
  PROBLEM:  User opens two infinite canvases side-by-side. 2x the rendering load.
  SOLUTION: Instantiate two separate `CustomPaint` canvases. To manage memory, the inactive page will freeze its `RepaintBoundary` and cache as an image until focused.
  RESULT:   Smooth UI and low memory footprint.
```

### Optimization 3: Level of Detail (LOD)
```
  PROBLEM:  When zoomed out to see full page, all strokes are tiny but still
            rendered at full vector detail.
  SOLUTION: At low zoom levels, swap vector strokes for low-res bitmap tiles.
            At high zoom levels, render full vector detail.
  RESULT:   Smooth zoom performance at any scale.
```

---

## 4️⃣ Cloud Sync Architecture

### The Decision: Eventual Sync (Page-Level)

**NOT Real-Time Collaborative Sync** (like Figma):
- That requires WebSockets, CRDTs, constant server pinging
- Costs too much, too complex for a solo dev
- Users don't need it — this is a personal note app, not a team whiteboard

**YES Eventual Sync** (like GoodNotes / Apple Notes):
- User draws for 45 minutes on their tablet
- App saves strokes locally on-device
- On notebook close (or every 5 minutes in background), uploads to Supabase
- When user opens the same notebook on another device, it downloads the latest version

### Sync Trigger Points:
```
  WHEN does the app sync?
  ├── User closes a notebook           → Sync immediately
  ├── Every 5 minutes in background    → Sync silently
  ├── App goes to background           → Sync immediately
  ├── User manually pulls to refresh   → Sync immediately
  └── App opens on any device          → Check for updates, download if newer
```

### Conflict Resolution Strategy: Page-Level Sync

```
  PROBLEM: User edits "Biology Notes" on BOTH tablet and phone while offline.
           Both come online. Which version wins?

  SOLUTION: Don't sync entire notebooks as one file.
            Sync individual PAGES as separate files.

  EXAMPLE:
  ├── Tablet edited Page 3 (offline)
  ├── Phone edited Page 7 (offline)
  ├── Both come online
  ├── Page 3 → uploaded from tablet    ✅ No conflict
  ├── Page 7 → uploaded from phone     ✅ No conflict
  └── Only conflicts if SAME page edited on both devices (rare)

  IF same-page conflict occurs:
  └── Create a duplicate: "Page 3 (Conflict Copy)"
      Let user manually merge. Safe, no data loss.
```

### Data Format:
```
  Each page is stored as:
  ├── page_[uuid].json       ← Stroke data (X, Y, pressure, color, tool)
  ├── page_[uuid]_cache.png  ← Rasterized preview thumbnail
  └── metadata.json          ← Page order, notebook info, last modified timestamp
```

---

## 5️⃣ Competitor Tech Comparison

| App | Canvas Tech | Sync Model | Our Advantage |
|:---|:---|:---|:---|
| **Samsung Notes** | Native (Wacom SDK) | Samsung Cloud only | We sync to ALL devices, not just Galaxy |
| **GoodNotes** | Native (PencilKit + Metal) | iCloud only | We sync cross-platform (Android + iOS) |
| **Notability** | Native (Custom Metal) | iCloud only | Same as GoodNotes |
| **OneNote** | Native + C++ core | OneDrive (real-time) | We have better organization + cleaner UX |
| **Infinite Note (Us)** | Flutter V1 → Hybrid V1.1 | Supabase (eventual, page-level) | Cross-platform + affordable + capped lifetime |

---

## 6️⃣ Build Priority Stack

```
  V1 MVP (Month 1-5):
  ├── CustomPaint canvas with stroke rasterization
  ├── Page-level eventual sync to Supabase
  ├── Folder system with infinite nesting
  ├── PDF export (watermarked free, clean for Pro)
  └── Basic pen, pencil, eraser, text tools

  V1.1 Post-Launch (Month 6-8):
  ├── Viewport culling + LOD for large notebooks
  ├── OCR handwriting search (Pro feature)
  ├── Background auto-sync every 5 minutes
  └── Highlighter + full color wheel (Pro features)

  V2 (If App Takes Off):
  ├── Native canvas rewrite (PencilKit on iOS, SurfaceView on Android)
  ├── CRDT-based real-time collaborative sync
  └── Template Marketplace launch
```

---

## 7️⃣ Summary

```
  ┌────────────────────────────────────────────────────────┐
  │                                                        │
  │   CANVAS:    Flutter CustomPaint + perfect_freehand    │
  │              (Upgrade to native PencilKit in V1.1)     │
  │                                                        │
  │   SYNC:      Eventual, page-level, to Supabase         │
  │              (NOT real-time collaborative)             │
  │                                                        │
  │   CONFLICT:  Page-level isolation + fork on conflict   │
  │                                                        │
  │   BUILD:     You are NOT building from zero.           │
  │              You are assembling existing Lego blocks   │
  │              + adding the "infinite" logic on top.     │
  │                                                        │
  │   TIMELINE:  5 months (V1 MVP)                         │
  │              6-7 months (with native canvas upgrade)   │
  │                                                        │
  └────────────────────────────────────────────────────────┘
```

---
#architecture #technical #canvas #sync #approved
