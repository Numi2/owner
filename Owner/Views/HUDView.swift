//
//  HUDView.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import SwiftUI
import GameKit

struct HUDView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var gameCenterService: GameCenterService
    
    var body: some View {
        HStack {
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                    Text(gameCenterService.localPlayer?.displayName ?? "Player")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                    Text("$\(gameManager.walletBalance, specifier: "%.0f")")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Image(systemName: "hexagon.fill")
                        .foregroundColor(.blue)
                    Text("\(gameManager.playerTurfs.count) Turfs")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Net Worth & Actions
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("Net Worth:")
                        .font(.caption)
                    Text("$\(gameManager.netWorth(), specifier: "%.0f")")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        // Show my turfs list
                    }) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        gameCenterService.showLeaderboard()
                    }) {
                        Image(systemName: "trophy")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.orange.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}