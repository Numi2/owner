//
//  GameManager.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import Foundation
import CoreLocation
import Combine

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
        if let playerId = gameCenterService.localPlayer?.playerID {
            currentPlayer = Player(gamePlayerID: playerId)
        } else {
            // Create a test player if GameCenter isn't available
            currentPlayer = Player(gamePlayerID: "test_player_\(UUID().uuidString)")
        }
        
        // Start income timer
        startIncomeTimer()
        
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
            self?.processPassiveIncome()
        }
    }
    
    private func processPassiveIncome() {
        let now = Date()
        var totalIncome = 0.0
        
        for (turfId, turf) in allTurfs {
            guard turf.ownerID == currentPlayer?.id else { continue }
            
            let timeSinceLastIncome = now.timeIntervalSince(turf.lastIncomeAt)
            let incomeIntervals = timeSinceLastIncome / GameConstants.incomeInterval
            
            if incomeIntervals >= 1.0 {
                let income = GameConstants.baseIncomeRate * incomeIntervals
                totalIncome += income
                
                // Update turf
                var updatedTurf = turf
                updatedTurf.vaultCash += income
                updatedTurf.lastIncomeAt = now
                allTurfs[turfId] = updatedTurf
            }
        }
        
        if totalIncome > 0 {
            updatePlayerTurfs()
            print("Passive income: $\(totalIncome)")
        }
    }
    
    private func updateNearbyTurfs(around coordinate: CLLocationCoordinate2D) {
        let radius = 0.001 // ~100m radius
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
        
        // Deduct weapon cost
        walletBalance -= weaponPack.cost
        
        // Simple attack resolution for Phase 2 (no mini-game yet)
        let attackValue = weaponPack.attackValue
        let defenseValue = turf.defenseValue
        
        let attackWins = attackValue > defenseValue
        
        if attackWins {
            // Attacker wins - capture turf and loot
            let loot = min(turf.vaultCash * GameConstants.lootPercentage, turf.vaultCash)
            walletBalance += loot
            
            var updatedTurf = turf
            updatedTurf.ownerID = currentPlayer.id
            updatedTurf.vaultCash -= loot
            updatedTurf.lastIncomeAt = Date()
            allTurfs[turf.id] = updatedTurf
            
            print("✅ Attack succeeded! Captured turf and looted $\(loot) - AV:\(attackValue) vs DV:\(defenseValue)")
        } else {
            print("❌ Attack failed! Lost $\(weaponPack.cost) - AV:\(attackValue) vs DV:\(defenseValue)")
        }
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = allTurfs[turf.id]!
        }
        updatePlayerTurfs()
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
    
    deinit {
        incomeTimer?.invalidate()
    }
}