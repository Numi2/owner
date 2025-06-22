//
//  GameManager.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import Foundation
import CoreLocation
import Combine
import GameKit

@MainActor
class GameManager: ObservableObject {
    @Published var currentPlayer: Player?
    @Published var nearbyTurfs: [Turf] = []
    @Published var playerTurfs: [Turf] = []
    @Published var walletBalance: Double = 100.0
    @Published var selectedTurf: Turf?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // In-memory storage for Phase 2 (local-only)
    private var allTurfs: [String: Turf] = [:]
    private var incomeTimer: Timer?
    private var attackTimer: Timer?
    private var proximityTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Services - these will be injected via environment
    private var locationService: LocationService?
    private let gameCenterService = GameCenterService.shared
    
    func initialize(locationService: LocationService? = nil) {
        // Set location service if provided
        if let locationService = locationService {
            self.locationService = locationService
        }
        
        // Initialize player
        if let localPlayer = gameCenterService.localPlayer {
            // Use gamePlayerID instead of deprecated playerID
            currentPlayer = Player(gamePlayerID: localPlayer.gamePlayerID)
        } else {
            // Create a test player if GameCenter isn't available
            currentPlayer = Player(gamePlayerID: "test_player_\(UUID().uuidString)")
        }
        
        // Start income timer
        startIncomeTimer()
        
        // New: Start attack timer
        startAttackTimer()
        
        // New: Start proximity timer
        startProximityTimer()
        
        // Subscribe to location updates if location service is available
        setupLocationSubscription()
        
        print("GameManager initialized with player: \(currentPlayer?.id ?? "unknown")")
    }
    
    func forceInitialize() {
        // Force initialization even if services aren't ready
        if currentPlayer == nil {
            currentPlayer = Player(gamePlayerID: "test_player_\(UUID().uuidString)")
        }
        
        // Generate some test turfs if we don't have location
        if nearbyTurfs.isEmpty {
            generateTestTurfs()
        }
        
        print("GameManager force initialized")
    }
    
    func generateTestTurfs() {
        // Generate test turfs around a default location (Apple Park)
        let defaultLocation = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        
        nearbyTurfs.removeAll()
        
        // Generate a 7x7 grid of turfs
        for latOffset in -3...3 {
            for lonOffset in -3...3 {
                let hexLat = defaultLocation.latitude + Double(latOffset) * GameConstants.hexGridSize
                let hexLon = defaultLocation.longitude + Double(lonOffset) * GameConstants.hexGridSize
                
                let hexCoordinate = CLLocationCoordinate2D(latitude: hexLat, longitude: hexLon)
                let turfId = "\(hexLat):\(hexLon)"
                
                var turf = Turf(coordinate: hexCoordinate)
                
                // Make some turfs owned by different players and add some cash
                let random = Int.random(in: 0...10)
                if random < 3 {
                    // 30% chance of being owned by player
                    turf.ownerID = currentPlayer?.id
                    turf.vaultCash = Double.random(in: 5...50)
                    turf.defenseMultiplier = Int.random(in: 1...3)
                } else if random < 6 {
                    // 30% chance of being owned by others
                    turf.ownerID = "enemy_\(Int.random(in: 1...5))"
                    turf.vaultCash = Double.random(in: 10...100)
                    turf.defenseMultiplier = Int.random(in: 1...5)
                }
                // 40% remain neutral
                
                allTurfs[turfId] = turf
                nearbyTurfs.append(turf)
            }
        }
        
        updatePlayerTurfs()
        print("Generated \(nearbyTurfs.count) test turfs")
    }
    
    private func setupLocationSubscription() {
        guard let locationService = locationService else { return }
        
        locationService.$currentLocation
            .compactMap { $0 }
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] location in
                self?.updateNearbyTurfs(around: location.coordinate)
            }
            .store(in: &cancellables)
    }
    
    private func startIncomeTimer() {
        incomeTimer = Timer.scheduledTimer(withTimeInterval: GameConstants.incomeInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processPassiveIncome()
            }
        }
    }
    
    private func processPassiveIncome() {
        let now = Date()
        var totalIncome = 0.0
        
        for (turfId, var turf) in allTurfs {
            guard turf.ownerID == currentPlayer?.id else { continue }
            
            // Check for completed structures and activate them
            for i in 0..<turf.structures.count {
                if turf.structures[i].isBuilding && turf.structures[i].buildProgress >= 1.0 {
                    turf.structures[i].buildStartAt = nil // Mark as built
                    print("✅ Structure \(turf.structures[i].type.rawValue) on turf \(turf.id) completed building!")
                }
            }

            let timeSinceLastIncome = now.timeIntervalSince(turf.lastIncomeAt)
            let incomeIntervals = timeSinceLastIncome / GameConstants.incomeInterval
            
            if incomeIntervals >= 1.0 {
                var turfIncome = GameConstants.baseIncomeRate * incomeIntervals
                
                // Add income from structures
                for structure in turf.structures {
                    if !structure.isBuilding && structure.type == .incomeGenerator {
                        turfIncome += structure.currentIncomeBonus * incomeIntervals
                    }
                }
                
                totalIncome += turfIncome
                
                // Update turf
                turf.vaultCash += turfIncome
                turf.lastIncomeAt = now
                allTurfs[turfId] = turf
            }
        }
        
        if totalIncome > 0 {
            updatePlayerTurfs()
            print("Passive income: $\(totalIncome)")
        }
    }
    
    private func startAttackTimer() {
        attackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processActiveAttacks()
            }
        }
    }
    
    private func processActiveAttacks() {
        let now = Date()
        for (turfId, var turf) in allTurfs {
            guard turf.isUnderAttack, let attackStartAt = turf.attackStartAt, turf.attackerID != nil else { continue }
            
            // Determine time since last processing or attack start
            let timeElapsedSinceLastProcess = now.timeIntervalSince(turf.lastAttackProcessedAt ?? attackStartAt)
            let totalAttackDuration = now.timeIntervalSince(attackStartAt)
            
            // Check for timeout
            if totalAttackDuration >= turf.attackTTL {
                // Attack times out
                resolveAttack(turf: turf, outcome: .timeout)
                continue
            }
            
            // Calculate attack progress for this interval
            let attackTickValue = turf.pendingAV * timeElapsedSinceLastProcess / turf.attackTTL
            
            // Apply damage to turf's currentDefenseHealth
            turf.currentDefenseHealth -= attackTickValue
            
            // Check if defense is broken
            if turf.currentDefenseHealth <= 0 {
                resolveAttack(turf: turf, outcome: .win)
                continue
            }
            
            // Update last processed time
            turf.lastAttackProcessedAt = now
            allTurfs[turfId] = turf // Update turf in storage
            
            // For immediate "timed" resolution, we can check at intervals.
            // For this phase, if the attack is ongoing, just update the turf state.
            // The actual resolution will happen at attackTTL or if defense changes.
        }
    }
    
    private func resolveAttack(turf: Turf, outcome: AttackLog.AttackOutcome) {
        var updatedTurf = turf
        let attackerID = turf.attackerID
        let defenderID = turf.ownerID
        let initialVaultCash = turf.vaultCash
        var lootDelta = 0.0
        
        if outcome == .win {
            // Attacker wins - capture turf and loot
            let loot = min(turf.vaultCash * GameConstants.lootPercentage, turf.vaultCash)
            if let attacker = currentPlayer, attacker.id == attackerID {
                walletBalance += loot
            }
            
            updatedTurf.ownerID = attackerID
            updatedTurf.vaultCash -= loot
            updatedTurf.lastIncomeAt = Date()
            lootDelta = loot
            
            print("✅ Attack succeeded! Captured turf \(turf.id) and looted $\(lootDelta). Outcome: \(outcome.rawValue)")
        } else if outcome == .loss || outcome == .timeout {
            print("❌ Attack failed for turf \(turf.id). Outcome: \(outcome.rawValue)")
        } else if outcome == .conflict {
            print("⚠️ Attack conflict for turf \(turf.id). Outcome: \(outcome.rawValue)")
        }
        
        updatedTurf.isUnderAttack = false
        updatedTurf.pendingAV = 0.0
        updatedTurf.attackerID = nil
        updatedTurf.attackStartAt = nil
        updatedTurf.lastAttackProcessedAt = nil // Reset
        
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        // Log the attack
        let attackLog = AttackLog(turfID: turf.id, attackerID: attackerID ?? "unknown", defenderID: defenderID, av: turf.pendingAV, dv: turf.defenseValue, outcome: outcome, timestamp: Date(), lootDelta: lootDelta)
        // TODO: Store attack log (e.g., to CloudKit or local history)
        print("Attack Logged: \(attackLog)")
    }
    
    private func updateNearbyTurfs(around coordinate: CLLocationCoordinate2D) {
        var nearby: [Turf] = []
        
        // Generate hex grid around current location
        for latOffset in -3...3 {
            for lonOffset in -3...3 {
                let hexLat = round(coordinate.latitude / GameConstants.hexGridSize) * GameConstants.hexGridSize + Double(latOffset) * GameConstants.hexGridSize
                let hexLon = round(coordinate.longitude / GameConstants.hexGridSize) * GameConstants.hexGridSize + Double(lonOffset) * GameConstants.hexGridSize
                
                let hexCoordinate = CLLocationCoordinate2D(latitude: hexLat, longitude: hexLon)
                let turfId = "\(hexLat):\(hexLon)"
                
                // Create turf if it doesn't exist
                if allTurfs[turfId] == nil {
                    allTurfs[turfId] = Turf(coordinate: hexCoordinate)
                }
                
                if let turf = allTurfs[turfId] {
                    nearby.append(turf)
                }
            }
        }
        
        nearbyTurfs = nearby
        updatePlayerTurfs()
    }
    
    private func updatePlayerTurfs() {
        playerTurfs = allTurfs.values.filter { $0.ownerID == currentPlayer?.id }
    }
    
    // MARK: - Game Actions
    
    func captureTurf(_ turf: Turf) {
        guard let currentPlayer = currentPlayer else { 
            print("❌ No current player found!")
            return 
        }
        guard turf.isNeutral else { 
            print("❌ Turf is not neutral: \(turf.ownerID ?? "unknown owner")")
            return 
        }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { 
            print("❌ Not in range of turf")
            return 
        }
        
        var updatedTurf = turf
        updatedTurf.ownerID = currentPlayer.id
        updatedTurf.lastIncomeAt = Date()
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        // Achievement
        if playerTurfs.count == 1 {
            gameCenterService.reportAchievement(GameCenterService.Achievements.firstCapture)
        } else if playerTurfs.count == 10 {
            gameCenterService.reportAchievement(GameCenterService.Achievements.tenTurfs)
        }
        
        print("✅ Captured turf: \(turf.id) - Player now owns \(playerTurfs.count) turfs")
    }
    
    func collectFromTurf(_ turf: Turf) {
        guard turf.ownerID == currentPlayer?.id else { 
            print("❌ Can't collect from turf you don't own")
            return 
        }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { 
            print("❌ Not in range of turf")
            return 
        }
        guard turf.vaultCash > 0 else { 
            print("❌ No cash to collect from turf")
            return 
        }
        
        let collected = turf.vaultCash
        walletBalance += collected
        
        var updatedTurf = turf
        updatedTurf.vaultCash = 0
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("✅ Collected $\(collected) from turf - Wallet balance: $\(walletBalance)")
    }
    
    func investInTurf(_ turf: Turf, amount: Double) {
        guard turf.ownerID == currentPlayer?.id else { 
            print("❌ Can't invest in turf you don't own")
            return 
        }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { 
            print("❌ Not in range of turf")
            return 
        }
        guard walletBalance >= amount else { 
            print("❌ Insufficient funds - Need $\(amount), have $\(walletBalance)")
            return 
        }
        
        walletBalance -= amount
        
        var updatedTurf = turf
        updatedTurf.vaultCash += amount
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("✅ Invested $\(amount) in turf - Turf vault: $\(updatedTurf.vaultCash), Wallet: $\(walletBalance)")
    }
    
    func attackTurf(_ turf: Turf, weaponPack: WeaponPack) {
        guard let currentPlayer = currentPlayer else { 
            print("❌ No current player found!")
            return 
        }
        guard turf.ownerID != currentPlayer.id else { 
            print("❌ Can't attack your own turf")
            return 
        }
        guard !turf.isNeutral else { 
            print("❌ Can't attack neutral turf - capture it instead")
            return 
        }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { 
            print("❌ Not in range of turf")
            return 
        }
        guard walletBalance >= weaponPack.cost else { 
            print("❌ Insufficient funds for weapon - Need $\(weaponPack.cost), have $\(walletBalance)")
            return 
        }
        
        // Check if already under attack by someone else and prevent concurrent attacks
        guard !turf.isUnderAttack || (turf.isUnderAttack && turf.attackerID == currentPlayer.id) else {
            print("❌ Turf is already under attack by another player!")
            return
        }

        // Deduct weapon cost
        walletBalance -= weaponPack.cost
        
        // Initiate timed attack
        var updatedTurf = turf
        updatedTurf.isUnderAttack = true
        updatedTurf.pendingAV = weaponPack.attackValue // Set pending AV
        updatedTurf.attackerID = currentPlayer.id
        updatedTurf.attackStartAt = Date()
        updatedTurf.lastAttackProcessedAt = Date() // Initialize last processed time
        updatedTurf.currentDefenseHealth = turf.defenseValue // Initialize defense health
        
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("🚀 Initiated attack on turf: \(turf.id) with \(weaponPack.name)! Attack will resolve in \(turf.attackTTL) seconds.")
        print("Current wallet balance: $\(walletBalance)")
        print("Turf Defense Health: $\(updatedTurf.currentDefenseHealth)")
    }
    
    func reinforceTurf(_ turf: Turf, amount: Double) {
        guard let currentPlayer = currentPlayer else {
            print("❌ No current player found!")
            return
        }
        guard turf.ownerID == currentPlayer.id else {
            print("❌ Can't reinforce a turf you don't own")
            return
        }
        guard turf.isUnderAttack else {
            print("❌ Turf is not under attack, no need to reinforce")
            return
        }
        guard walletBalance >= amount else {
            print("❌ Insufficient funds to reinforce - Need $\(amount), have $\(walletBalance)")
            return
        }
        
        walletBalance -= amount
        
        var updatedTurf = turf
        updatedTurf.currentDefenseHealth += amount // Increase defense health
        
        // Ensure defense health doesn't exceed initial defense value
        updatedTurf.currentDefenseHealth = min(updatedTurf.currentDefenseHealth, turf.defenseValue)
        
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("✅ Reinforced turf: \(turf.id) with $\(amount). New defense health: $\(updatedTurf.currentDefenseHealth)")
    }
    
    func getTurfOwnerColor(_ turf: Turf) -> String {
        if turf.isNeutral {
            return "gray"
        } else if turf.ownerID == currentPlayer?.id {
            return "blue"
        } else {
            return "red"
        }
    }
    
    // MARK: - Utility
    
    func netWorth() -> Double {
        let vaultTotal = playerTurfs.reduce(0) { $0 + $1.vaultCash }
        return walletBalance + vaultTotal
    }
    
    func buildStructure(on turf: Turf, type: Structure.StructureType) {
        guard let currentPlayer = currentPlayer else {
            print("❌ No current player found!")
            return
        }
        guard turf.ownerID == currentPlayer.id else {
            print("❌ Can't build on a turf you don't own")
            return
        }
        
        var newStructure = Structure(type: type)
        guard walletBalance >= newStructure.currentCost else {
            print("❌ Insufficient funds to build \(type.rawValue) - Need $\(newStructure.currentCost), have $\(walletBalance)")
            return
        }
        
        // Check if a similar structure is already building or built (limit to one of each type for now)
        if turf.structures.contains(where: { $0.type == type }) {
            print("❌ A \(type.rawValue) already exists on this turf.")
            return
        }
        
        walletBalance -= newStructure.currentCost
        newStructure.buildStartAt = Date()
        
        var updatedTurf = turf
        updatedTurf.structures.append(newStructure)
        allTurfs[turf.id] = updatedTurf
        
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("✅ Started building \(type.rawValue) on turf \(turf.id) for $\(newStructure.currentCost) - Build time: \(newStructure.buildTime)s")
        print("Current wallet balance: $\(walletBalance)")
    }
    
    func upgradeStructure(on turf: Turf, structureID: UUID) {
        guard let currentPlayer = currentPlayer else {
            print("❌ No current player found!")
            return
        }
        guard turf.ownerID == currentPlayer.id else {
            print("❌ Can't upgrade on a turf you don't own")
            return
        }
        
        guard var structureToUpgrade = turf.structures.first(where: { $0.id == structureID }) else {
            print("❌ Structure not found on this turf.")
            return
        }
        
        // Prevent upgrading if still building
        guard !structureToUpgrade.isBuilding else {
            print("❌ Cannot upgrade \(structureToUpgrade.type.rawValue) while it is still building.")
            return
        }

        let upgradeCost = structureToUpgrade.currentCost // Cost for next level
        guard walletBalance >= upgradeCost else {
            print("❌ Insufficient funds to upgrade \(structureToUpgrade.type.rawValue) - Need $\(upgradeCost), have $\(walletBalance)")
            return
        }
        
        walletBalance -= upgradeCost
        structureToUpgrade.level += 1
        structureToUpgrade.buildStartAt = Date() // Start new build time for upgrade
        
        var updatedTurf = turf
        if let index = updatedTurf.structures.firstIndex(where: { $0.id == structureID }) {
            updatedTurf.structures[index] = structureToUpgrade
        }
        allTurfs[turf.id] = updatedTurf
        
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("✅ Started upgrading \(structureToUpgrade.type.rawValue) on turf \(turf.id) to level \(structureToUpgrade.level) for $\(upgradeCost) - Build time: \(structureToUpgrade.buildTime)s")
        print("Current wallet balance: $\(walletBalance)")
    }
    
    private func startProximityTimer() {
        proximityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processProximityEffects()
            }
        }
    }
    
    private func processProximityEffects() {
        guard let currentPlayerId = currentPlayer?.id else { return }
        
        let playerOwnedTurfsWithTowers = allTurfs.values.filter {
            $0.ownerID == currentPlayerId && $0.structures.contains(where: { $0.type == .defenseTower && !$0.isBuilding })
        }
        
        guard !playerOwnedTurfsWithTowers.isEmpty else { return }
        
        let enemyTurfs = allTurfs.values.filter { $0.ownerID != nil && $0.ownerID != currentPlayerId }
        
        for turf in playerOwnedTurfsWithTowers {
            guard let tower = turf.structures.first(where: { $0.type == .defenseTower }),
                  let stealRadius = tower.stealRadius,
                  let stealRate = tower.stealRate else { continue }
            
            let turfLocation = CLLocation(latitude: turf.latitude, longitude: turf.longitude)
            
            for var enemyTurf in enemyTurfs {
                let enemyLocation = CLLocation(latitude: enemyTurf.latitude, longitude: enemyTurf.longitude)
                let distance = turfLocation.distance(from: enemyLocation)
                
                if distance <= stealRadius && enemyTurf.vaultCash > 0 {
                    let amountToSteal = min(GameConstants.baseIncomeRate * stealRate, enemyTurf.vaultCash)
                    
                    // Update our turf
                    var updatedPlayerTurf = turf
                    updatedPlayerTurf.vaultCash += amountToSteal
                    allTurfs[turf.id] = updatedPlayerTurf
                    
                    // Update enemy turf
                    enemyTurf.vaultCash -= amountToSteal
                    allTurfs[enemyTurf.id] = enemyTurf
                    
                    print("💰 Stole $\(amountToSteal) from turf \(enemyTurf.id) with tower at \(turf.id)")
                }
            }
        }
        
        updatePlayerTurfs()
    }
    
    deinit {
        incomeTimer?.invalidate()
        attackTimer?.invalidate()
        proximityTimer?.invalidate()
    }
}
