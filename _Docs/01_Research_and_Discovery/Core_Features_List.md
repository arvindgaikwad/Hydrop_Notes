# Horizon Notes: Core Features List

> **Phase:** 1 — Research & Discovery  
> **Status:** FINALIZED (Updated June 12, 2026 — reflects implemented features)  

This document serves as the master list of all features planned and built for the Horizon Notes application, derived from our competitive analysis and technical architecture.

---

## 1. Core Note-Taking (The Canvas)
- **Infinite Canvas:** A borderless, zoomable workspace that expands automatically as you write. Uses Flutter's native `InteractiveViewer`.
- **Dual-Page Split View:** Ability to open two separate notes side-by-side (active editing on one, reference on the other). ✅ Built.
- **Vector-Based Ink Engine:** High-performance, ultra-low latency drawing (using custom Flutter `CustomPaint` and `RepaintBoundary`). ✅ Built.
- **Pressure Sensitivity:** Support for Apple Pencil, S-Pen, and other styluses with variable stroke width based on pressure.
- **Neo-Skeuomorphic Floating Toolbar:** A dockable toolbar (left/right/top/bottom) with raised paper surface and crisp 2px ink borders. Active tools show a tactile pressed/inset state. ✅ Built.
- **Text Nodes:** Double-tap to add inline-editable text objects directly on the canvas. Native `TextField` auto-scaling with zoom. ✅ Built.
- **Image Insertion:** File picker integration for adding images to the canvas. Images saved to local filesystem to prevent RAM bloat. ✅ Built.
- **Lasso Selection:** Ray-casting polygon selection that calculates which strokes, text, and images fall within a drawn region. Bounding box with unified pan-gesture translation. ✅ Built.
- **Multi-Layer System:** Multiple canvas layers with per-layer visibility toggle, add/remove layers, and a dedicated Layers Panel. ✅ Built.
- **Minimap:** Real-time overview of canvas content with viewport indicator. Uses `insetSurface` (recessed panel) decoration. ✅ Built.
- **Radial Color Picker:** Custom dial-based color picker with base colors → shade expansion → hue ring. ✅ Built.

## 2. Organization & Structure
- **Notebooks & Folders:** Infinitely nestable folder system displayed as a sidebar tree with drag-and-drop. ✅ Built.
- **Inline Renaming:** Direct `TextField` editing for folders and notes (no interruptive dialogs). ✅ Built.
- **Soft-Delete Trash System:** Items are moved to Trash (hidden from normal views) and can be restored or permanently deleted. ✅ Built.
- **Drag-and-Drop:** Reorder and reparent folders and notes via sidebar drag targets. ✅ Built.
- **Context Menus:** Right-click/long-press menus for sidebar folders and `...` menus for dashboard cards. ✅ Built.
- **Search:** Global search across all notebook titles and metadata. ⏳ Pending.
- **Cover Customization:** Set custom cover art or colors for Notebooks. ⏳ Pending.

## 3. Data & Sync
- **Local-First Storage (Hive):** All notes are saved immediately to device via Hive NoSQL boxes for offline access. ✅ Built.
- **Zero-Server Cloud Sync:** Background sync directly to user's personal Google Drive or OneDrive using REST APIs. No custom backend. ⏳ Pending.
- **Cross-Platform:** Flutter compilation targeting Android, iOS, Web, Windows, macOS. ✅ Framework ready.
- **Export Options:** Export single pages or entire notebooks as PDF or PNG. ⏳ Pending.

## 4. Monetization (Zero-Server Ad Model)
- **100% Free:** All premium features unlocked for all users. No paywalls, no feature gating.
- **Google AdMob:** Standard banner/interstitial ads integrated.
- **Rewarded Video Pass:** Watch 1 ad = 6 hours ad-free pass. Passes are stackable.
- ⏳ All monetization features pending implementation.

---

## 5. Niche "Study Weapon" Features (The Pivot)
*These features differentiate us entirely from general-purpose note apps like StarNote by specifically targeting competitive exam aspirants.*
- **Spaced Repetition on Canvas:** Draw a mind map or diagram, and the app auto-generates flashcards from specific nodes to help memorize it.
- **Exam Timer Mode:** A built-in, distraction-free timer for practicing mock tests and previous year papers directly on the canvas.
- **Previous Year Paper Templates:** Pre-loaded, structured templates for UPSC, CAT, GATE, and NEET exams ready for annotation.
- **AI Question Generator:** AI reads your handwritten notes/maps and generates practice multiple-choice questions (MCQs) to test your knowledge.
- **Study Group Sync:** Real-time collaboration to share annotated study maps and notes with your specific study group.
- **Tutor & Notes Marketplace:** A platform where toppers and educators can sell their heavily annotated mind maps and notes (with a 30% platform commission).

---
*Documented for Developer Handoff.*

