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
        }
        
        // Start income timer
        startIncomeTimer()
        
        // Subscribe to location updates if location service is available
        setupLocationSubscription()
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
        guard let currentPlayer = currentPlayer else { return }
        guard turf.isNeutral else { return }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { return }
        
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
        
        print("Captured turf: \(turf.id)")
    }
    
    func collectFromTurf(_ turf: Turf) {
        guard turf.ownerID == currentPlayer?.id else { return }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { return }
        guard turf.vaultCash > 0 else { return }
        
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
        
        print("Collected $\(collected) from turf")
    }
    
    func investInTurf(_ turf: Turf, amount: Double) {
        guard turf.ownerID == currentPlayer?.id else { return }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { return }
        guard walletBalance >= amount else { return }
        
        walletBalance -= amount
        
        var updatedTurf = turf
        updatedTurf.vaultCash += amount
        allTurfs[turf.id] = updatedTurf
        
        // Update local arrays
        if let index = nearbyTurfs.firstIndex(where: { $0.id == turf.id }) {
            nearbyTurfs[index] = updatedTurf
        }
        updatePlayerTurfs()
        
        print("Invested $\(amount) in turf")
    }
    
    func attackTurf(_ turf: Turf, weaponPack: WeaponPack) {
        guard let currentPlayer = currentPlayer else { return }
        guard turf.ownerID != currentPlayer.id else { return }
        guard !turf.isNeutral else { return }
        guard locationService?.isWithinRange(of: turf.coordinate) == true else { return }
        guard walletBalance >= weaponPack.cost else { return }
        
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
            
            print("Attack succeeded! Captured turf and looted $\(loot)")
        } else {
            print("Attack failed! Lost $\(weaponPack.cost)")
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