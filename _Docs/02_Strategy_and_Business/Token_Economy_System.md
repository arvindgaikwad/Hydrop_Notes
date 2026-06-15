# 🪙 The Token Economy System

> **Date:** 2026-06-02  
> **Status:** APPROVED STRATEGY  
> **Core Principle:** Give students complete freedom to pay with their time or their wallets.

---

## 1. The Core Currency: "The Focus Token"

To abstract the monetization and gamify the experience, we introduce an internal currency called the **Focus Token**.
*   **Value:** 1 Focus Token = 24 Hours of 100% Ad-Free Premium Canvas.
*   **Behavior:** When a user activates a Focus Token, a countdown timer (24:00:00) starts. During this time, all banner and interstitial ads are completely disabled.

---

## 2. The Three Paths to Ad-Free (The Economy)

Users have three distinct paths to secure an ad-free experience, catering to every budget and study habit.

### Path A: The "Grind" (Pay with Time)
*   **Cost:** Watch 5 Rewarded Video Ads.
*   **Reward:** 1 Focus Token (24 hours ad-free).
*   **Target Audience:** Budget-conscious high-school/college students who have more time than money.
*   **UX Flow:** A "Charge" meter on the home screen. The user taps "Charge", watches a 30-second ad, and one of five battery bars fills up. Once 5 bars are full, a Focus Token is minted.

### Path B: The "Exam Cram" Micro-Transaction (Pay as you go)
*   **Cost:** ₹10 per Token.
*   **Reward:** 1 Focus Token (24 hours ad-free).
*   **Target Audience:** Students the night before a major exam who don't want to waste 2.5 minutes watching ads, but don't want to commit to a monthly subscription.
*   **Financial Math:** Google Play takes 15% (Small Business Program). Net revenue = **₹8.50 per transaction**. 

### Path C: The "Pro Student" Subscription (Set and Forget)
*   **Cost:** ₹49 / Month.
*   **Reward:** Permanent Ad-Free Status (While Subscribed).
*   **Target Audience:** Power users, professionals, and serious students who love the app and want zero friction.
*   **Financial Math:** Net revenue = **₹41.65 / month**. 

---

## 3. Why This Economy Wins

1.  **Zero Guilt, Zero Friction:** You are never forcing a user to pay money. If they complain about ads in a 1-star review, the community will defend you: *"Just watch the 5 ads or pay ₹10, it's a completely free app otherwise."*
2.  **Gamification:** The "5-Ad Charge Meter" feels like a game mechanic rather than a corporate monetization wall. It creates a daily ritual for the user before they begin studying.
3.  **Revenue Maximization:** 
    *   Path A (5 Ads) yields approximately **~₹3.00** (assuming ~$7.40 eCPM for 5 rewarded video impressions).
    *   Path B (₹10 payment) yields **₹8.50 net**.
    *   Path C (₹49/month) yields **₹41.65 net**.
    *   Because the micro-transaction (₹10) yields nearly 3x the revenue of the ads, every user who upgrades from Path A to Path B increases your profit significantly while feeling like they got a great deal.

---

## 4. Technical Implementation Notes

*   **Local State:** The token balance (`available_tokens`) and the active timer (`active_until_timestamp`) must be stored locally in the Isar/Hive database.
*   **Anti-Cheat Validation:** When a Focus Token is activated, the app must fetch the current UTC time from a public API (e.g., `worldtimeapi.org`) to calculate the exact expiry time (`activation_time + 24 hours`). It must not rely on the local device clock to prevent users from changing their phone's date to extend the token indefinitely.
*   **Google Play Billing:** Both the ₹10 one-time consumable purchase (Path B) and the ₹49/month auto-renewing subscription (Path C) must be routed through the standard `in_app_purchase` Flutter package to comply with Google Play policies.
