# Turf Cash – Asynchronous PvP Mechanics

This document expands the earlier minimal spec to fully cover the **asynchronous player-versus-player (PvP)** flow: data structures, life-cycle, server conflict handling, and user experience.

------------------------------------------------------------------------
1. Terminology
------------------------------------------------------------------------
Turf           – Geo-anchored record that can be owned by exactly one player at a time.  
Vault Cash     – Cash stored *inside* the Turf (earns interest, counts toward Defense).  
Defense Value  – `vaultCash × defenseMultiplier` (multiplier chosen by owner).  
Attack Value   – Sum of weapon packs purchased *plus* mini-game modifier.

Key Property
• *Deterministic resolution:*  given (AV, DV) both clients should arrive at identical win/lose state—essential for conflict resolution.

------------------------------------------------------------------------
2. CloudKit Record Layout
------------------------------------------------------------------------
Record `Turf`
```
id                CKRecord.ID      (lat:lon composite key)
ownerID           String           (Game Center ID)
vaultCash         Double
defenseMultiplier Int             1…5
lastIncomeAt      Date             (server time)

# Volatile raid info
isUnderAttack     Bool (default false)
pendingAV         Double           (only meaningful while isUnderAttack=true)
attackerID        String           (GCID of current attacker)
attackStartAt     Date             (server time)
attackTTL         Double           (seconds, e.g. 90)
```

Record `AttackLog` (one-shot, write-once)
```
id           CKRecord.ID          (UUID)
turkRef      CKRecord.Reference   (Turf)
attackerID   String
defenderID   String
av           Double
dv           Double
outcome      String   ("win" / "loss" / "timeout" / "conflict")
timestamp    Date
lootDelta    Double   (+cash for attacker, -cash for defender)
```

Why a flag *inside* Turf?
• Lets nearby players see a hex as “under attack” in realtime.  
• Enables basic locking without costly atomic transactions.

------------------------------------------------------------------------
3. Raid Lifecycle
------------------------------------------------------------------------
1️⃣  **Initiate**  
• Attacker taps *Attack* on rival Turf.  
• Client performs local distance check (≤25 m) + wallet ≥ weapon cost.  
• Client starts a `CKModifyRecordsOperation`:
   – Fetch Turf record (server-side latest).  
   – Reject if `isUnderAttack==true`.  
   – Set `isUnderAttack=true`, fill `attackerID`, `pendingAV=0`, `attackStartAt=now`, `attackTTL=90`.

2️⃣  **Mini-game**  
• Client runs 15-s timing bar → yields modifier (±10 %).  
• Calculates `AV = baseWeaponValue × (1±0.1)`.  
• Sends second `CKModifyRecordsOperation` to update `pendingAV` once mini-game ends.

3️⃣  **Resolve**  
• After any of these triggers:  
   a. Attacker posts resolution.  
   b. 90 s TTL expires (background, app closed).  
   c. Defender attempts an action → server auto-resolves first.  

Resolution algorithm (CloudKit function or Client w/ atomic update):
```
if pendingAV == 0 → outcome = timeout
else if AV > DV      → outcome = win
else                  → outcome = loss

if win:
   loot = min(vaultCash * 0.25, vaultCash)  # 25 % rounded down
   vaultCash -= loot
   ownerID = attackerID
   isUnderAttack = false  # clear flag
else:
   isUnderAttack = false
```
• Create `AttackLog` record storing full details.  
• Push notifications (future phase): attacker & defender informed.

------------------------------------------------------------------------
4. Conflict Handling & Atomicity
------------------------------------------------------------------------
Scenario: two attackers try simultaneously.
• First modifier write succeeds; second fails on `isUnderAttack==true` → UI shows “busy” state.  
• If attacker crashes before sending modifier, TTL will auto-timeout; flag clears.

Atomic updates
• Always include Turf record’s current `modificationDate` in `CKModifyRecordsOperation` (CloudKit optimistic locking).  
• On conflict error, refetch & retry once; if still failing, surface error to player.

------------------------------------------------------------------------
5. Defender Experience
------------------------------------------------------------------------
While *isUnderAttack==true* :  
• Defender cannot Invest/Collect.  
• Hex renders with animated red outline “Under Attack”.  
• After resolution, defender may view replay stub (reads `AttackLog`).

------------------------------------------------------------------------
6. Edge Cases & Safeguards
------------------------------------------------------------------------
• **GPS Jump** – Attacker’s position verified server-side by writing their latest coordinate into AttackLog; server compares to Turf coord (<=25 m).  
• **Networking Drop** – If attacker loses connectivity, TTL resolves.  
• **Infinite Loop** – Winning attacker cannot trigger another attack immediately; impose 2-minute cooldown per Turf.

------------------------------------------------------------------------
7. Unit-Test Checklist
------------------------------------------------------------------------
✓ AV > DV: ownership flips, 25 % loot transferred.  
✓ AV == DV: defender retains turf.  
✓ AV < DV: defender retains, attacker loses weapons fee.  
✓ Timeout: no ownership change, attacker loses weapons fee.  
✓ Flag reset after each resolution.  
✓ Conflict: two parallel initiation attempts, only first proceeds.

------------------------------------------------------------------------
8. Implementation Hooks (Swift)
------------------------------------------------------------------------
```swift
/// Called when player presses Attack button
func beginAttack(on turf: Turf, weaponCost: Double) async throws {
    try await turfService.lockTurfForAttack(turfID: turf.id, attackerID: player.id)
    // present MiniGameView...
}

/// Called after mini-game finishes
func finishAttack(turf: Turf, av: Double) async throws {
    try await turfService.submitAttackValue(turfID: turf.id, av: av)
    try await turfService.resolveAttackIfReady(turfID: turf.id)
}
```

------------------------------------------------------------------------
9. UI States
------------------------------------------------------------------------
Hex overlay variants
• Normal  – colored by owner.  
• Under Attack (owned) – pulsating red border + owner color fill.  
• Under Attack (neutral) – red border + neutral fill.

ActionSheet buttons when viewer is DEFENDER and turf `isUnderAttack`:
   [View Status 🔒]  (greyed actions)  
   Tooltip: “Turf is under attack – wait for outcome.”

------------------------------------------------------------------------
10. Performance Notes
------------------------------------------------------------------------
• `CKQuerySubscription` on Turf allows near-instant UI update when attack resolves.  
• Keep `AttackLog` in separate zone; purge logs >30 days to control database size.

------------------------------------------------------------------------
Revision History
------------------------------------------------------------------------
v1  – Initial async PvP deep-dive (author: OpenAI, 2025-06-21)
