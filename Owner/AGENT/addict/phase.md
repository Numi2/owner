# Turf Cash — Development Phases (v1)

The goal is to reach a *fun, location-aware turf war loop* as quickly as possible, then layer on persistence and visuals.  This plan stops after Phase 5—the point at which the game is playable with real players, real data, and branded art.  Later polish (analytics, notifications, scaling) can be scheduled once core engagement is proven.

──────────────────────────────────────────────
PHASE 0 — Pre-Production (≤1 week)
──────────────────────────────────────────────
Objectives
1. Freeze the ultra-minimal rule set (see tasks.md).  
2. Convert rules into unit-testable formulas (income, DV, AV).  
3. Spike a GPS hex-grid algorithm on a playground file.  
4. Risk list: CloudKit limits, GPS spoofing, animation transparency.

Deliverable ⇒ “green-light” checklist : spec locked, repo created, tickets written.

──────────────────────────────────────────────
PHASE 1 — App Skeleton & Location (1 week)
──────────────────────────────────────────────
Build once, throw away never.  Nothing visual besides the map.

Steps
• New Xcode 15 project, SwiftUI.  
• Enable Game Center + Always-On Location.  
• Implement `LocationService` with significant-change monitoring.  
• Render Apple Map and real-time blue dot.  
• Drop debug hex overlay using playground algorithm (static colors).

Exit criteria ⇒ walk a city block, blue dot stays in correct hex; GC login succeeds.

──────────────────────────────────────────────
PHASE 2 — Local-Only Core Loop (2 weeks)
──────────────────────────────────────────────
Prove “grab, earn, steal” is compelling before adding servers.

Steps
• Create in-memory `Turf` dictionary keyed by rounded lat/lon.  
• Implement ActionSheet with four actions (capture, collect, invest, attack).  
• Passive income timer ticks every minute.  
• Simple attack: AV > DV wins (no mini-game yet).  
• HUD showing wallet, number of turfs.

Playtest goals
• 2 devices alternately capturing same coffee-shop; check if risk/reward feels right.  
• Adjust default numbers until sessions average ≥5 min.

──────────────────────────────────────────────
PHASE 3 — Cloud Persistence & Multi-user (2 weeks)
──────────────────────────────────────────────
Turn the local fun into shared fun.

Steps
• Model `Player` and `Turf` in CloudKit.  
• Replace in-memory store with CloudKit backed `TurfService`.  
• Handle optimistic UI and conflict rollback on simultaneous attacks.  
• Cache nearby turfs in Core Data for offline use.

Exit criteria ⇒ two TestFlight testers on different Apple IDs can see each other’s turf in real time; ownership survives app reinstall.

──────────────────────────────────────────────
PHASE 4 — Combat Mini-Game & Balancing (1 week)
──────────────────────────────────────────────
Add the 15-second timing bar to give agency and skill expression.

Steps
• Build `MiniGameView` (tap timing).  
• Feed ±10 % modifier into attack resolver.  
• Unit tests for edge-case math (max/min DV vs AV).  
• First balance pass on weapon pricing and defense multipliers.

Playtest metric ⇒ average attack win rate ~50 % when AV≈DV.

──────────────────────────────────────────────
PHASE 5 — Art & Animation Drop-in (parallel, 1 week)
──────────────────────────────────────────────
Swap placeholders for MidJourney assets once mechanics stop shifting.

Steps
• Generate all required PNGs/MP4s with prompts in Assets/prompts.txt.  
• Integrate into SwiftUI views & animation callbacks.  
• Apply color palette from Assets/colors.json.  
• Quick device QA for transparency edges, performance.

Exit criteria ⇒ game looks branded, playable end-to-end, no stub graphics.

──────────────────────────────────────────────
Why stop here?
These five phases deliver a *complete vertical slice*: live map, territory capture, passive income, asynchronous PvP, and thematic art.  Power users can start real-world turf wars, giving us concrete data before investing in deeper features (notifications, analytics, anti-cheat sophistication, etc.).
