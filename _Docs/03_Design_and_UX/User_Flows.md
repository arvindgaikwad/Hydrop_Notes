# 🗺️ Information Architecture & User Flows

> **Prepared by:** LEONARDO & DEMIURGE  
> **Date:** 2026-05-30 (Updated June 12, 2026)  
> **Phase:** 2 (Information Architecture)  
> **Status:** COMPLETE — Flows remain valid after Neo-Skeuomorphic design pivot  

> [!NOTE]
> The visual language pivoted from "Expansive Minimalism" (glassmorphic, dark-mode) to **Neo-Skeuomorphic** (paper/ink, tactile surfaces) during implementation. The user flows and screen architecture below remain structurally accurate — only the aesthetic has changed. See [Design_System_Spec.md](file:///c:/Users/Silver/Downloads/silver-os/50_IDEAS/Apps/Horizon_Notes/03_Design_and_UX/Design_System_Spec.md) for current visual tokens.

## 📱 The 22 MVP Screens (Finalized)

### 1. Onboarding & Authentication
1. Splash / Onboarding Screen 1
2. Onboarding Screen 2
3. Onboarding Screen 3
4. Sign In / Sign Up

### 2. Core Navigation & Management
5. Home / Notebooks List (Grid/List View)
6. Notebook Detail Layout (Inside a folder/notebook)
7. Empty State 1 (No Notebooks)
8. Empty State 2 (No Pages)
9. Search Notes Overlay

### 3. The Canvas Experience (Hero Screens)
10. Note Canvas (Empty State)
11. Note Canvas (Active State)
12. Tool Palette (Pen, Text, Eraser)
13. Page Rotation UI (Single-tap rotation)
14. Horizontal Page Strip (Bottom thumbnail navigation)
15. Page Settings Menu

### 4. Utility & Status
16. Sync Status Details (Cloud sync states)
17. Export Options (PDF, Image, Vector)
18. Delete Confirmation Dialog

### 5. Account & Monetization
19. Profile / Account Management
20. Connected Devices Panel
21. App Settings
22. Pro Upgrade / Paywall Screen

---

## 🌊 Core User Flows

### Flow A: The "First Note" Flow (Time to Value)
`Splash Screen` ➔ `Onboarding (1,2,3)` ➔ `Sign Up` ➔ `Home (Empty State)` ➔ `Tap "New Note"` ➔ `Canvas (Empty State)` ➔ `Tool Palette opens` ➔ `Canvas (Active State)`

### Flow B: The "Infinite Rotation" Flow
`Home` ➔ `Tap Notebook` ➔ `Notebook Detail` ➔ `Tap Page` ➔ `Canvas (Active)` ➔ `Tap Rotation UI` ➔ `Canvas Rotates 90°` ➔ `Draw` ➔ `Tap Page Strip to swap pages`

### Flow C: The "Upgrade to Pro" Flow
`Canvas (Active)` ➔ `Tap Sync Status` (shows limit reached) ➔ `Pro Upgrade Paywall` ➔ `Payment Success` ➔ `Connected Devices Panel` (shows syncing)

### Flow D: The "Export & Share" Flow
`Canvas (Active)` ➔ `Tap Page Settings` ➔ `Export Options` ➔ `Select PDF/Vector` ➔ `Share Sheet`

---

## 🚫 v2 Features (Deferred from MVP)
The following features are deferred to post-MVP:
- Audio Recording and Sync (Like Notability)
- Real-time Collaboration (Multiplayer cursors)
- Template Marketplace (Creator economy)
- AI Summarization or Handwriting-to-Text extraction
- Advanced Tagging System

## ✅ Originally Deferred, Now Implemented
The following were not in the original MVP plan but have since been built:
- **Text Nodes:** Inline-editable text objects on the canvas
- **Image Insertion:** File picker integration with local storage
- **Lasso Selection:** Ray-casting polygon selection with bounding box
- **Multi-Layer System:** Per-layer visibility, add/remove layers
- **Minimap:** Real-time overview of canvas content and viewport
- **Split View:** Side-by-side dual-canvas editing
- **Soft-Delete Trash System:** Trash bin with restore/permanent delete
- **Drag-and-Drop:** Folder and note reorganization via sidebar

---
#ia #user-flows #phase-2
