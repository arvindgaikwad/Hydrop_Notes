# Horizon Notes — Wireframe Generation Instructions

> **Purpose:** This file contains everything needed to generate the remaining 43 Hi-Fi wireframe screens for the Horizon Notes app. Give this file to a new agent/conversation and it will have full context.
> **Project Path:** `c:\Users\Silver\Downloads\silver-os\50_IDEAS\Apps\Horizon_Notes\`

---

## What This Project Is

**Horizon Notes** is a premium infinite-canvas handwriting/note-taking app (like GoodNotes/Noteshelf) built with Flutter. We are creating high-fidelity HTML/CSS wireframes for **both Phone (390×844px) and Tablet (1194×834px)** layouts.

## Output Location

- **Phone screens:** `03_Design_and_UX\HiFi_Screens\Phone\`
- **Tablet screens:** `03_Design_and_UX\HiFi_Screens\Tablet\`
- **Naming format:** `{ID}_{ScreenName}.html` (e.g. `B2_Notebook_Detail.html`)

---

## Design System: "Horizon Obsidian"

Every screen MUST use these exact tokens. Copy this CSS `:root` block into every file:

```css
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&display=swap');

:root {
  --bg-primary: #FCFCFC;
  --bg-secondary: #FFFFFF;
  --bg-tertiary: #F1F5F9;
  --text-primary: #0F172A;      /* Obsidian — primary text & headings */
  --text-secondary: #64748B;    /* Descriptions, labels */
  --text-muted: #94A3B8;        /* Placeholders, disabled */
  --border: #E2E8F0;            /* Dividers, card borders */
  --accent: #0F172A;            /* Primary CTAs (NOT blue) */
  --accent-active: #6366F1;     /* Indigo — active/selected tool glow */
  --accent-glow: rgba(99, 102, 241, 0.10);
  --success: #10B981;
  --warning: #F59E0B;
  --error: #EF4444;
  --pro-gradient: linear-gradient(135deg, #0F172A, #6366F1);
  --radius-card: 16px;
  --radius-btn: 12px;
  --radius-pill: 32px;
}
```

### Typography: DM Sans only
| Level | Size | Weight | Use |
|:------|:-----|:-------|:----|
| Display | 48px (tablet) / 32px (phone) | 700 | Onboarding headlines |
| H1 | 28-32px | 600 | Screen titles |
| H2 | 24px | 500 | Section headers |
| Body | 16px | 400 | Descriptions |
| Caption | 13-14px | 400 | Timestamps, metadata |
| Overline | 12px | 600, letter-spacing 0.05em | Tags, badges |

### Spacing
- **Phone margins:** 24-32px side padding
- **Tablet margins:** 48-80px side padding
- **Grid:** Strict 8pt grid (all values multiples of 8)
- **Touch targets:** 56px minimum height
- **Card radius:** 16px. Button radius: 12px. Pills: 32px.

### Key Components

**Floating Tool Palette:**
- Phone: horizontal pill at bottom center, `border-radius: 24px`
- Tablet: vertical sidebar pinned to left edge, `border-radius: 20px`
- Both: `background: rgba(255,255,255,0.88); backdrop-filter: blur(24px); border: 1px solid rgba(226,232,240,0.6); box-shadow: 0 8px 32px rgba(15,23,42,0.08)`
- Active tool: `background: var(--accent-glow); color: var(--accent-active)` with a small dot/bar indicator

**Notebook Cards:**
- `background: var(--bg-secondary); border: 1px solid var(--border); border-radius: 16px`
- Cover area: 4:3 aspect ratio with pastel background + subtle icon
- Info area: title (14px/500), meta (12px, `--text-muted`)

**Canvas Dot Grid:**
- `background-image: radial-gradient(circle, #D4D4D8 0.8px, transparent 0.8px); background-size: 24px 24px` (phone) or `28px 28px` (tablet)

**Bottom Navigation (Phone only):**
- `height: 80px; background: var(--bg-secondary); border-top: 1px solid var(--border)`
- 4 items: Home, Search, Favorites, Profile
- Active: `color: var(--accent)`

---

## What's Already Done (6 screens)

| ID | Screen | Phone | Tablet |
|:---|:-------|:-----:|:------:|
| A1 | Welcome / Splash | ✅ | ✅ |
| A5 | Sign In / Sign Up | ✅ | ❌ |
| B1 | Home: Notebooks Grid | ✅ | ❌ |
| C2 | Canvas Active Drawing | ✅ | ✅ |

---

## What Needs to Be Built (43 screens)

### Group A: Onboarding & Auth (remaining: 7)

**A2 — Onboarding: Infinite Canvas (Phone + Tablet)**
- Full-screen centered layout
- Large illustration area showing an infinite canvas expanding outward (use SVG: concentric expanding rectangles fading out)
- Headline: "Write without boundaries" (Display size)
- Subtitle: "An infinite canvas that grows with your ideas." (Body, `--text-secondary`)
- Pagination dots at bottom (3 dots, second active with `--accent-active`)
- "Next" button bottom-right, "Skip" text button bottom-left

**A3 — Onboarding: Sync Everywhere (Phone + Tablet)**
- Same layout as A2
- Illustration: cloud icon connected to device icons (phone, tablet, laptop) with dotted lines
- Headline: "Your notes, every device"
- Subtitle: "Seamless sync. Start on your tablet, continue on your phone."
- Third pagination dot NOT active (second is)

**A4 — Onboarding: Built for Focus (Phone + Tablet)**
- Same layout as A2
- Illustration: minimal toolbar floating above a clean canvas
- Headline: "Tools that disappear"
- Subtitle: "The toolbar hides while you write, so you can focus on what matters."
- Third pagination dot active
- "Get Started" primary button instead of "Next"

**A5 — Sign In / Sign Up (Tablet)**
- Split layout: form on left half, decorative right half (dot grid + floating card like A1 tablet)
- Same form elements as phone version: tab switcher, email, password, social login

### Group B: Core Navigation (remaining: 9)

**B1 — Home: Notebooks Grid (Tablet)**
- Left sidebar (240px): Logo at top, nav items (All Notes, Recent, Favorites, Shared), "New Notebook" button at bottom
- Main area: header with title + search bar, filter pills, 3-column notebook grid
- Same card design as phone but larger

**B2 — Notebook Detail: Pages List (Phone + Tablet)**
- Header: back arrow, notebook title ("Biology 301"), edit/share icons
- Subtitle: "12 pages · Created May 15"
- Grid of page thumbnails (3:4 ratio cards with miniature dot grid + faint ink lines)
- Active page has `--accent-active` border
- "Add Page" card with dashed border and + icon
- Phone: 2 columns. Tablet: 4 columns with sidebar.

**B3 — Empty State: No Notebooks (Phone + Tablet)**
- Centered layout
- Large illustration: empty notebook icon (outlined, 80px, `--text-muted`)
- Headline: "No notebooks yet" (H2)
- Subtitle: "Create your first notebook to start writing." (Body, `--text-secondary`)
- "Create Notebook" primary button (56px height)

**B4 — Empty State: No Pages (Phone + Tablet)**
- Same pattern as B3
- Icon: blank page with + icon
- Headline: "This notebook is empty"
- Subtitle: "Add your first page and start writing."
- "Add Page" primary button

**B5 — Search Overlay (Phone + Tablet)**
- Full-screen overlay with `--bg-primary` background
- Top: large search input with auto-focus styling (Indigo border)
- "Recent Searches" section with chip tags
- Live results: list items with notebook icon, title (bold match highlight), preview text, timestamp
- Phone: full screen. Tablet: centered modal (640px max-width) with backdrop dim.

### Group C: Canvas — Hero Screens (remaining: 7)

**C1 — Canvas Empty State (Phone + Tablet)**
- Same layout as C2 but canvas is empty
- Ghost text in center: "Tap to start writing..." in `--text-muted`, italic
- Toolbar visible but no tool selected (all grey)
- No ink strokes, just the dot grid

**C3 — Tool Palette Expanded (Phone + Tablet)**
- Canvas with some ink in background (reuse C2's content faded)
- Phone: horizontal palette expanded to show sub-options — pen types row (ballpoint, fountain, marker), stroke width slider, color row
- Tablet: vertical palette expanded with a flyout panel to the right showing the same options
- Flyout panel: `background: var(--bg-secondary); border: 1px solid var(--border); border-radius: 16px; box-shadow: 0 12px 40px rgba(15,23,42,0.1)`

**C4 — Color Picker Open (Phone + Tablet)**
- Canvas background with toolbar
- Color picker popup anchored to the color swatch
- Grid of 12 preset colors (3×4), "Recent" row of 4, and a "Custom" hex input at bottom
- Phone: bottom sheet style. Tablet: inline popover.

**C5 — Page Rotation UI (Phone + Tablet)**
- Canvas with content rotated 90°
- Rotation handle visible: circular arc with degree indicator showing "90°"
- Subtle animated guide lines
- "Done" button overlay

**C6 — Page Strip Expanded (Phone + Tablet)**
- Canvas in background (slightly dimmed)
- Phone: bottom sheet sliding up showing vertical list of page thumbnails
- Tablet: bottom strip expanded taller, showing larger thumbnails with page numbers
- Active page highlighted, drag handles for reorder

**C7 — Dual-Page Split View (Tablet only)**
- Two canvas areas side by side with a 4px draggable divider line
- Left canvas: "Physics 101 — Page 2" (active, with toolbar)
- Right canvas: "Biology 301 — Page 5" (reference, slightly dimmed toolbar)
- Each canvas has its own header with page title
- Central divider has a small drag handle icon

### Group D: Utility & Dialogs (remaining: 8)

**D1 — Sync Status Details (Phone + Tablet)**
- Phone: full screen. Tablet: right panel or centered modal.
- Header: "Sync Status" with close button
- Sync summary card: "All synced" with green badge, or "2 pending" with yellow
- List of notebooks with sync icons: ✓ (green), ↻ (yellow, animating), ⚠ (red)
- Each row: notebook name, page count, last synced timestamp
- "Sync Now" button at bottom

**D2 — Export Options (Phone + Tablet)**
- Phone: bottom sheet. Tablet: centered modal (480px).
- Header: "Export" with close X
- Three option cards (stacked): PDF, PNG, SVG — each with icon, title, description
- Quality selector: "Standard" / "High" toggle
- "Export" primary button + "Share" secondary button

**D3 — Delete Confirmation Dialog (Phone + Tablet)**
- Centered modal overlay with backdrop dim (`rgba(15,23,42,0.4)`)
- Modal: `max-width: 340px; border-radius: 16px; padding: 24px`
- Warning icon (⚠) at top
- "Delete 'Biology 301'?" headline
- "This notebook and all 12 pages will be permanently deleted." body text
- Two buttons: "Cancel" (secondary) + "Delete" (red background: `--error`)

**D4 — Page Settings Menu (Phone + Tablet)**
- Phone: bottom sheet. Tablet: popover panel.
- "Page Settings" header
- Background type: radio selection with previews (Blank / Ruled / Grid / Dot Grid)
- Page color: row of 6 color circles (white, cream, sage, lavender, blue-grey, dark)
- Template section: "None" selected, with option to browse templates

### Group E: Account & Monetization (remaining: 8)

**E1 — Profile / Account (Phone + Tablet)**
- Header: "Account"
- Profile card: avatar circle (initials), name, email
- Storage usage: progress bar showing "1.2 GB / 5 GB" with percentage
- List sections: "Subscription" (Free/Pro badge), "Connected Devices" (→), "Data & Privacy" (→)
- "Sign Out" text button at bottom in `--error` color

**E2 — Connected Devices (Phone + Tablet)**
- Header: "Connected Devices" with back arrow
- List of devices: icon (phone/tablet/laptop), device name, OS, "This Device" badge on current
- Last synced timestamp per device
- "Disconnect" action (swipe or button)

**E3 — App Settings (Phone + Tablet)**
- Grouped list settings:
  - **Appearance:** Theme toggle (Light / Dark / System), App Icon
  - **Canvas:** Default background (Dot Grid), Default pen color, Pen pressure sensitivity toggle
  - **Storage:** Local storage usage, "Clear Cache" button
  - **About:** Version number, "Rate App", "Send Feedback"

**E4 — Pro Upgrade / Paywall (Phone + Tablet)**
- Hero section: gradient background (`--pro-gradient`), "Horizon Notes Pro" headline in white, crown/star icon
- Feature comparison table:
  - Free: 3 notebooks, basic tools, local only
  - Pro: unlimited, all tools, cloud sync, PDF export
  - Use checkmarks (✓) in `--success` and crosses (✗) in `--text-muted`
- Price: "$9.99 — one-time purchase" prominently displayed
- "Unlock Pro" primary button (full width, 56px)
- "Restore Purchase" text link below
- Phone: scrollable full screen. Tablet: centered card (600px max-width) with decorative background.

---

## Technical Notes

1. Each file is a **standalone HTML file** — no build tools, no frameworks. Just open in a browser.
2. All fonts loaded from Google Fonts CDN.
3. Phone width: `390px`, height: `844px` (iPhone 14 size)
4. Tablet width: `1194px`, height: `834px` (iPad Air landscape)
5. Use `margin: 0 auto` on body to center the viewport.
6. SVG icons should use `stroke="currentColor" stroke-width="1.5" stroke-linecap="round"` — Lucide icon style.
7. Canvas ink content: use SVG `<text>` and `<path>` elements to simulate handwritten notes.

## Reference Files

- **Design System Spec:** `03_Design_and_UX\Design_System_Spec.md`
- **User Flows (screen list):** `03_Design_and_UX\User_Flows.md`
- **Feature List:** `01_Research_and_Discovery\Core_Features_List.md`
- **Completed screens** (use as reference for style consistency): `03_Design_and_UX\HiFi_Screens\Phone\C2_Canvas_Active_Drawing.html` and `...\Tablet\C2_Canvas_Active_Drawing.html`

---

## Execution Order (recommended)

1. Finish Group A (A2, A3, A4 phone+tablet, A5 tablet) — 7 screens
2. Finish Group B (B1 tablet, B2-B5 phone+tablet) — 9 screens
3. Finish Group C (C1, C3-C7) — 7 screens
4. Group D (all 8) — 8 screens
5. Group E (all 8) — 8 screens

**Total remaining: 43 screens.**
