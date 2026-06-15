# Hydrop Notes: Developer Handoff Document

Welcome to the **Hydrop Notes** project! This document serves as the primary entry point for developers taking over the implementation phase of the application.

## Project Overview
**Hydrop Notes** is a premium, infinite-canvas note-taking app designed primarily for tablets. It targets professionals and students who need a distraction-free, tactile writing environment for deep thought. 
The core philosophy is the "canvas without edges"—a fluid, lag-free writing experience on a warm, paper-like surface.

## Phase Status
- **Strategy & Research:** ✅ Complete
- **Information Architecture:** ✅ Complete
- **UI/UX Design:** ✅ Complete (Neo-Skeuomorphic design system implemented in `theme.dart`)
- **Frontend Development:** 🔄 In Progress (Core canvas, toolbar, layers, minimap, home dashboard, file management — all built)
- **Monetization (AdMob):** ⏳ Pending
- **Cloud Sync (Google Drive/OneDrive):** ⏳ Pending
- **Onboarding Flow:** ⏳ Pending

## Key Technical Decisions
Before writing code, please review the architecture and strategy plan:
- **Tech Stack**: Flutter (Tablet-first, compiling to Web/Desktop later).
- **Core Challenge**: Latency. We must achieve <10ms perceived latency for the pen tool.
- **Architecture Reference**: Read [Technical Architecture](../02_Strategy_and_Business/Technical_Architecture.md) for canvas graphics details, and [Zero Server Ad Model Strategy](../02_Strategy_and_Business/Zero_Server_Ad_Model_Strategy.md) for the monetization and storage architecture.
- **Sync Strategy**: Zero-server cost model. We utilize local-first storage (Hive NoSQL) and perform background sync directly to the user's personal Google Drive or OneDrive using REST APIs. No custom backend server is used.
- **Monetization and Tokens**: The application is 100% free with all premium features unlocked. It integrates Google AdMob, utilizing standard banner/interstitial ads and a stackable rewarded video pass (1 Ad watched = 6 hours ad-free pass).

## Design & UI Guidelines — Neo-Skeuomorphic ("Tactile Blueprint")
The app utilizes the **Neo-Skeuomorphic Ink Kit** design system (Light-only v1).
- **Aesthetic:** Tactile, warm, monochromatic. The UI feels like a hand-drawn wireframe on textured paper.
- **Paper Background:** `#F4F2EC` — warm off-white paper for all surfaces
- **Ink:** `#2D2D2D` — dark grey for all text, borders, and active icons
- **Inset Background:** `#E8E4D9` — slightly darker paper for pressed/active/recessed states
- **Borders:** All interactive surfaces use 2px solid ink borders — this is the defining visual trait
- **Surface States:**
  - `raisedSurface` — Floating toolbars & panels (paper bg, 2px border, 20px radius, level2 shadow)
  - `buttonPressed` — Active tools (inset bg, 2px border, 12px radius, NO shadow)
  - `insetSurface` — Recessed panels like minimap (inset bg, 2px border, 12px radius)
- **Typography:** System-native font. Weight tokens: Regular (400), Medium (500), Bold (700)
- **Icons:** Flutter Material Icons. Active = ink color, Inactive = muted grey (`#6B7280`)
- **Design System Specs:** Read [Design System Spec](../03_Design_and_UX/Design_System_Spec.md) for exact hex codes, border radii, surface decorators, and component styles.

## Where to Find the Screens
The core screens have been **implemented directly in Flutter** (not via Stitch mockups):
- **Completed & Built:**
  1. Canvas Active State (Infinite + A4 modes)
  2. Home Dashboard (Folder Grid + Note Grid + Sidebar Tree)
  3. Dockable Toolbar (Left/Right/Top/Bottom with flyouts)
  4. Layers Panel (Multi-layer with visibility toggles)
  5. Minimap (Real-time canvas overview)
  6. Radial Color Picker (Dial-based with shade expansion)
  7. Split View (Dual-canvas side-by-side)
  8. Soft-Delete Trash System
- **Pending:**
  1. Pro Paywall / Ad Integration
  2. Onboarding Flow (3 Screens)
  3. Settings / Account Management
  4. Export Options

## Folder Structure Guide
If you need to understand the 'Why' behind any feature, refer to the documentation:
- `01_Research_and_Discovery/`: User needs, market analysis, feature matrix.
- `02_Strategy_and_Business/`: Brand identity, monetization (tokens), technical architecture, solo creator challenges.
- `03_Design_and_UX/`: User flows, design system spec (Neo-Skeuomorphic), wireframes, screens, design plans.
- `04_Resources_and_Brainstorms/`: Naming brainstorms, pitch decks, landing pages, learning strategies.
- `05_Session_Logs/`: Project execution logs and session summaries.

Good luck building the canvas without edges!
