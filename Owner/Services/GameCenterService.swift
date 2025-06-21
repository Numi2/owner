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
            if let error = error {
                self?.authError = error
                self?.isAuthenticated = false
                print("Game Center authentication error: \(error.localizedDescription)")
                return
            }
            
            if let viewController = viewController {
                // Present authentication view controller
                // Note: In a real app, you'd present this from your main view controller
                print("Need to present Game Center authentication")
                return
            }
            
            if GKLocalPlayer.local.isAuthenticated {
                self?.isAuthenticated = true
                self?.localPlayer = GKLocalPlayer.local
                print("Game Center authenticated: \(GKLocalPlayer.local.displayName)")
                self?.loadPlayerData()
            } else {
                self?.isAuthenticated = false
                print("Game Center not authenticated")
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
        
        let scoreObj = GKScore(leaderboardIdentifier: category)
        scoreObj.value = Int64(score)
        
        GKScore.report([scoreObj]) { error in
            if let error = error {
                print("Score submission error: \(error.localizedDescription)")
            } else {
                print("Score submitted successfully")
            }
        }
    }
    
    func showLeaderboard() {
        guard isAuthenticated else { return }
        
        let viewController = GKGameCenterViewController(state: .leaderboards)
        // In a real app, present this from your main view controller
        print("Show leaderboard")
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