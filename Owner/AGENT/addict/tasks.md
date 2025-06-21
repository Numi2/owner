# Turf Cash — Task Breakdown

This file enumerates the concrete steps required to ship the minimal “Turf Cash” prototype.  It is split between engineering tasks (Xcode/iOS) and visual-design tasks.

## 1. iOS Developer (Xcode + GameKit)

0. Project Setup
   • Create a new Xcode 15 project targeting iOS 17, Swift & SwiftUI.  
   • Enable capabilities: Game Center, Location Updates (Always), Background Fetch, CloudKit.

1. Data Model
   • `Player`: id (Game Center ID), `walletBalance`.  
   • `Turf`: id, latitude, longitude, `ownerID`, `vaultCash`, `defenseMultiplier`.  
   • `WeaponPack`: cost, `attackValue`.

2. Cloud Back-End (CloudKit)
   • Create record types **Player** and **Turf**; index Turf on geopoint.  
   • ACL: Turf writable only by current owner; use atomic `CKModifyRecords` in attack flow.

3. Services Layer
   • **LocationService** – GPS + significant-change monitoring.  
   • **TurfService** – fetch nearby Turfs, create new ones.  
   • **IncomeService** – compute passive earnings on resume / 15-min timer.  
   • **GameLogicService** – capture, collect, invest, attack resolution.

4. Game Center Integration
   • Authenticate on launch.  
   • Leaderboard “Net Worth” (wallet + all vaults).  
   • Achievements: “First Capture”, “Ten Turfs”, etc.

5. UI / UX (SwiftUI)
   • **MapView** – `MKMapView` with hex overlays color-coded by owner.  
   • **ActionSheet** – context actions based on distance & ownership.  
   • HUD – wallet balance & profile pic.  
   • **MiniGameView** – 15-sec tap-timing bar (±10 % AV).  
   • Lists: My Turfs, optional Attack Replays.

6. Game Loop Implementation
   A. Capture neutral Turf.  
   B. Passive income accumulator.  
   C. Invest flow – deposit from wallet.  
   D. Attack flow – buy weapons, run mini-game, resolve via `GameLogicService`.  
   E. CloudKit update & UI refresh.

7. Local Notifications
   • Vault full.  
   • Turf lost while app is backgrounded.

8. Testing
   • Unit tests: income calculation, attack edge cases.  
   • UI tests: map overlay & action availability with simulated GPS.

9. Deployment
   • Prepare TestFlight build and public testing link.  
   • Collect screenshots: Map, ActionSheet, Mini-Game.

---

## 2. Visual-Asset Creator Tasks (MidJourney-First Workflow)

1. MidJourney Prompt Packs
   • Draft descriptive prompts for each required asset group:  
     – Map Screen background + UI framing  
     – Hex tiles (neutral, owned, rival)  
     – ActionSheet panel  
     – HUD icons (wallet, shield, crosshair, arrow-down)  
     – Mini-Game timing bar & slider  
   • Include desired color palette, perspective, resolution (≥ 1024×1024) in each prompt.

2. Generate & Curate Images
   • Run prompts in MidJourney.  
   • Pick best candidates; upscale as needed.  
   • Export PNGs: @1× @2× @3× for all UI elements.

3. Short Motion Loops (Video/GIF)
   • Use MidJourney (video mode) or Runway/After Effects to create 0.6–1 s loops for:  
     – Capture success  
     – Collect  
     – Invest  
     – Attack  
   • Deliver as MP4 & optional GIF fallback (transparent where possible).

4. Color & Typography Reference
   • Document final hex, accent, and background colors in a `colors.json` or PDF.  
   • Confirm primary font: SF Pro (system)—no file delivery needed.

5. Packaging
   • Place all PNGs in `/Assets/Images`.  
   • Place MP4/GIF loops in `/Assets/Animations`.  
   • Include `README.md` in `/Assets` describing asset names and recommended usage sizes.

6. Handoff Review
   • Verify each UI element aligns to 8-pt grid when imported into Xcode asset catalog.  
   • Provide MidJourney prompt text in `/Assets/prompts.txt` for future regeneration.
