# Strategic & Technical Implementation Plan: The "Zero-Server" Ad Model

This document outlines the pivot of Horizon Notes from a subscription-based, custom-cloud note app to a **100% Free, Ad-Supported, "Bring Your Own Storage"** model.

## User Review Required

> [!WARNING]
> **Major Architectural Shift**
> By adopting this model, we are officially abandoning the custom Supabase real-time sync engine. We will no longer support "live, multi-user collaboration" (like Notion or Figma). Instead, this app becomes a single-player, offline-first tool that backs up to the user's personal Google Drive/OneDrive. 
> Please confirm if you are 100% aligned with dropping real-time collaboration to achieve $0 server costs.

## Open Questions

> [!IMPORTANT]
> 1. **Ad Mediation:** Do we want to launch with *only* Google AdMob for simplicity, or do you want to integrate AppLovin MAX from Day 1? (Demiurge recommends AdMob only for the MVP launch).
> 2. **Initial Platform:** Are we launching exclusively on Android (Google Play) first to avoid Apple's App Tracking Transparency and $99 fee, or do you still want to launch on both simultaneously using Flutter?
> 3. **The Pivot Features:** Should we still include the "Study Weapon" features (Spaced Repetition, Exam Timer) in this free ad-supported version, or start with just a clean, basic note-taking MVP?

---

## Proposed Changes: Technical Architecture

We will restructure the application to operate with **$0 monthly server costs**.

### 1. Local Storage Engine (Offline-First)
- **Tech Stack:** Flutter with **Isar Database** or **Hive** (NoSQL local storage).
- **Behavior:** All notes, strokes, and metadata are saved locally in milliseconds. The app must feel instantly responsive without waiting for a network connection.

### 2. The "Bring Your Own Storage" (BYOS) Sync Engine
- **Tech Stack:** Google Drive API (via `googleapis` Flutter package) and Microsoft Graph API (for OneDrive).
- **Behavior:** 
  - Instead of continuous real-time sync, the app performs a silent background sync (JSON metadata + binary stroke data) to a hidden app-data folder in the user's Google Drive.
  - Conflict Resolution: "Last Modified Wins." If a user edits a note offline on a tablet and on a phone, we prompt them to pick the correct version.

### 3. The Ad Infrastructure & Stackable Token Logic
- **The Problem with 4 Ads Upfront:** Forcing a user to watch 4 video ads consecutively (up to 2 minutes) causes friction. If an ad fails to load, the user will become frustrated.
- **The "Token" Solution:** We use a stackable token system. **1 Ad Watched = 1 Token = 6 Hours Ad-Free.**
  - Users can watch just 1 ad to unlock 6 hours for their immediate study session.
  - Or they can choose to stack 4 ads sequentially to max out at 24 hours ad-free.
- **Tech Stack:** `google_mobile_ads` Flutter package.
- **State Management (Local):**
  - `expiry_time` (timestamp) stored locally via Hive/Isar.
  - Every time a rewarded video ad finishes, we add +6 hours to `expiry_time` (up to a maximum cap of `Now() + 24 hours`).
- **Anti-Cheat Mechanism:** Before granting the token time, the app makes a 50ms HTTP request to `worldtimeapi.org` to fetch the true global time. This prevents users from changing their phone's clock to extend the ad-free pass indefinitely.

---

## Proposed Changes: Marketing & Launch Strategy

With this model, our biggest weapon is that we are free. 

### 1. The Reddit "Underdog" Campaign
- **Target Communities:** r/NoteTaking, r/androidapps, r/productivity, r/JEENEETards.
- **The Pitch:** *"I'm a solo dev who was tired of GoodNotes and Notein charging expensive subscriptions. So I built a 100% free alternative that saves straight to your Google Drive. No server fees, no subscriptions. If you want to support me, you can watch a few ads to get an ad-free pass for the day."*
- **Why it works:** Reddit hates greedy corporations and loves honest indie developers. This pitch will generate massive organic downloads on Day 1.

### 2. App Store Optimization (ASO)
- Focus entirely on high-volume, budget-conscious search terms:
  - *"Free note taking app"*
  - *"GoodNotes free alternative"*
  - *"Notes app with Google Drive"*
  - *"Student planner free"*

### 3. The Monetization Funnel
- **The Banner:** Placed safely at the **very top** of the screen (away from the palm rest) to ensure we don't trigger accidental clicks that infuriate users.
- **The Interstitial:** Triggers *only* when the user hits "Close Notebook" or "Export PDF". Never interrupts active writing.
- **The Golden Goose (Rewarded Video):** A massive, beautiful button on the home screen: **"Get 24 Hours Ad-Free 🎁"**. Students will instinctively tap this before their study session begins.

---

## Verification Plan

### Automated Tests
- Test the Google Drive auth token refresh cycle to ensure users don't randomly get logged out.
- Unit test the `ad_count` logic and anti-cheat time validation.

### Manual Verification
- **Palm Rejection & Ad Placement:** Physically test the app on an Android tablet with a stylus to ensure the hand never accidentally brushes the banner ad.
- **Offline Reliability:** Turn on Airplane mode, write a note, turn off Airplane mode, and verify it successfully queues and uploads to Google Drive.
