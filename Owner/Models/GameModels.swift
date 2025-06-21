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
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var defenseValue: Double {
        return vaultCash * Double(defenseMultiplier)
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
    }
}

// MARK: - WeaponPack Model
struct WeaponPack: Codable, Identifiable {
    let id = UUID()
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
    let id = UUID()
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