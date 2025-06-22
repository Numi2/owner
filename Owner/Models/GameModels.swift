//
//  GameModels.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import Foundation
import CoreLocation
import GameKit

// MARK: - Player Model
struct Player: Codable, Identifiable {
    let id: String // Game Center ID
    var walletBalance: Double
    var createdAt: Date
    var lastActiveAt: Date
    
    init(gamePlayerID: String) {
        self.id = gamePlayerID
        self.walletBalance = 100.0 // Starting balance
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
}

// MARK: - Turf Model  
struct Turf: Codable, Identifiable {
    let id: String // lat:lon composite key
    let latitude: Double
    let longitude: Double
    var ownerID: String?
    var vaultCash: Double
    var defenseMultiplier: Int // 1-5
    var lastIncomeAt: Date
    var createdAt: Date
    
    // Volatile raid info
    var isUnderAttack: Bool
    var pendingAV: Double
    var attackerID: String?
    var attackStartAt: Date?
    var attackTTL: Double // seconds
    var lastAttackProcessedAt: Date? // New: Track last time attack progress was applied
    var currentDefenseHealth: Double // New: Tracks turf health during an attack
    var structures: [Structure] // New: Array to hold structures on this turf
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var defenseValue: Double {
        let baseValue = vaultCash * Double(defenseMultiplier)
        let structureDefenseBonus = structures.reduce(0.0) { (sum, structure) in
            // Only active structures contribute to defense
            return sum + (structure.isBuilding ? 0 : structure.currentDefenseBonus)
        }
        return baseValue + structureDefenseBonus
    }
    
    var isNeutral: Bool {
        return ownerID == nil
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        // Create hex-grid aligned coordinate
        let hexSize = GameConstants.hexGridSize
        let hexLat = round(coordinate.latitude / hexSize) * hexSize
        let hexLon = round(coordinate.longitude / hexSize) * hexSize
        
        self.id = "\(hexLat):\(hexLon)"
        self.latitude = hexLat
        self.longitude = hexLon
        self.ownerID = nil
        self.vaultCash = 0.0
        self.defenseMultiplier = 1
        self.lastIncomeAt = Date()
        self.createdAt = Date()
        
        // Initialize raid state
        self.isUnderAttack = false
        self.pendingAV = 0.0
        self.attackerID = nil
        self.attackStartAt = nil
        self.attackTTL = 90.0
        self.lastAttackProcessedAt = nil // New: Initialize to nil
        self.currentDefenseHealth = 0.0 // New: Initialize to 0.0, will be set on attack start
        self.structures = [] // New: Initialize empty array of structures
    }
}

// MARK: - WeaponPack Model
struct WeaponPack: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let cost: Double
    let attackValue: Double
    
    static let basic = WeaponPack(name: "Basic", cost: 10.0, attackValue: 25.0)
    static let advanced = WeaponPack(name: "Advanced", cost: 25.0, attackValue: 75.0)
    static let elite = WeaponPack(name: "Elite", cost: 50.0, attackValue: 150.0)
    
    static let all = [basic, advanced, elite]
}

// MARK: - Attack Log Model
struct AttackLog: Codable, Identifiable {
    var id: UUID = UUID()
    let turfID: String
    let attackerID: String
    let defenderID: String?
    let av: Double
    let dv: Double
    let outcome: AttackOutcome
    let timestamp: Date
    let lootDelta: Double
    
    enum AttackOutcome: String, Codable, CaseIterable {
        case win = "win"
        case loss = "loss"
        case timeout = "timeout"
        case conflict = "conflict"
    }
}

// MARK: - Game Constants
struct GameConstants {
    static let maxCaptureDistance: Double = 25.0 // meters
    static let hexGridSize: Double = 0.09 // ~10 km per hex
    static let baseIncomeRate: Double = 1.0 // $ per minute
    static let maxDefenseMultiplier: Int = 5
    static let lootPercentage: Double = 0.25 // 25% of vault on successful attack
    static let attackCooldown: Double = 120.0 // 2 minutes
    static let incomeInterval: Double = 60.0 // 1 minute
}

// MARK: - Structure Model
struct Structure: Codable, Identifiable, Hashable {
    let id: UUID
    let type: StructureType
    var level: Int
    let baseCost: Double
    let baseDefenseBonus: Double
    let baseIncomeBonus: Double
    var buildTime: Double // in seconds
    var buildStartAt: Date?
    
    enum StructureType: String, Codable, CaseIterable {
        case defenseTower = "Defense Tower"
        case incomeGenerator = "Income Generator"
    }
    
    var currentCost: Double {
        return baseCost * pow(1.5, Double(level - 1))
    }
    
    var currentDefenseBonus: Double {
        return baseDefenseBonus * Double(level)
    }
    
    var currentIncomeBonus: Double {
        return baseIncomeBonus * Double(level)
    }
    
    var isBuilding: Bool {
        if let start = buildStartAt, Date().timeIntervalSince(start) < buildTime {
            return true
        }
        return false
    }
    
    var buildProgress: Double {
        guard let start = buildStartAt, buildTime > 0 else { return 1.0 }
        let progress = Date().timeIntervalSince(start) / buildTime
        return min(max(progress, 0.0), 1.0)
    }
    
    init(type: StructureType, level: Int = 1) {
        self.id = UUID()
        self.type = type
        self.level = level
        self.buildStartAt = nil
        
        switch type {
        case .defenseTower:
            self.baseCost = 50.0
            self.baseDefenseBonus = 25.0
            self.baseIncomeBonus = 0.0
            self.buildTime = 30.0 // 30 seconds
        case .incomeGenerator:
            self.baseCost = 75.0
            self.baseDefenseBonus = 0.0
            self.baseIncomeBonus = 0.5 // +0.5$ per minute per level
            self.buildTime = 45.0 // 45 seconds
        }
    }
}
