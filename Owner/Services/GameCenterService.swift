//
//  GameCenterService.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import Foundation
import GameKit
import Combine

@MainActor
class GameCenterService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var authError: Error?
    
    static let shared = GameCenterService()
    
    private init() {
        authenticatePlayer()
    }
    
    func authenticatePlayer() {
        localPlayer = GKLocalPlayer.local
        
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error
                    self?.isAuthenticated = false
                    print("Game Center authentication error: \(error.localizedDescription)")
                    
                    // Check if this is a missing entitlement error
                    let nsError = error as NSError
                    if nsError.domain == "GKErrorDomain" && nsError.code == 3 {
                        print("⚠️  Game Center entitlement missing or invalid. Please check project entitlements.")
                    }
                    return
                }
                
                if let viewController = viewController {
                    // Present authentication view controller
                    // Note: In a real app, you'd present this from your main view controller
                    print("Need to present Game Center authentication view controller")
                    // For now, we'll continue without authentication
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayer = GKLocalPlayer.local
                    print("✅ Game Center authenticated: \(GKLocalPlayer.local.displayName ?? "Unknown")")
                    self?.loadPlayerData()
                } else {
                    self?.isAuthenticated = false
                    print("❌ Game Center not authenticated")
                }
            }
        }
    }
    
    private func loadPlayerData() {
        // Load player's Game Center data
        // This could include achievements, leaderboards, etc.
    }
    
    // MARK: - Leaderboards
    func submitScore(_ score: Int, category: String = "net_worth") {
        guard isAuthenticated else { return }
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [category]
                )
                print("Score submitted successfully")
            } catch {
                print("Score submission error: \(error.localizedDescription)")
            }
        }
    }
    
    func showLeaderboard() {
        guard isAuthenticated else { return }
        
        // In a real app, create and present GKGameCenterViewController from your main view controller
        // Example: let viewController = GKGameCenterViewController(state: .leaderboards)
        print("Show leaderboard - implement presentation in your view controller")
    }
    
    // MARK: - Achievements
    func reportAchievement(_ identifier: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else { return }
        
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        
        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Achievement report error: \(error.localizedDescription)")
            } else {
                print("Achievement reported: \(identifier)")
            }
        }
    }
    
    // Achievement identifiers (these would be configured in App Store Connect)
    struct Achievements {
        static let firstCapture = "first_capture"
        static let tenTurfs = "ten_turfs"
        static let hundredAttacks = "hundred_attacks"
        static let millionaire = "millionaire"
    }
}