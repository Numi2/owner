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
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Compact View
            HStack {
                // Player Info
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        
                        Text(gameCenterService.localPlayer?.displayName.prefix(1).uppercased() ?? "P")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    // Stats
                    VStack(alignment: .leading, spacing: 2) {
                        Text(gameCenterService.localPlayer?.displayName ?? "Player")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 8) {
                            Label("$\(gameManager.walletBalance, specifier: "%.0f")", systemImage: "dollarsign.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            
                            Label("\(gameManager.playerTurfs.count)", systemImage: "hexagon.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Net Worth
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Net Worth")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("$\(gameManager.netWorth(), specifier: "%.0f")")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                }
                
                // Expand Button
                Button(action: { withAnimation(.spring()) { HapticManager.shared.impact(.light); isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            
            // Expanded View
            if isExpanded {
                VStack(spacing: 8) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Quick Stats Grid
                    HStack(spacing: 16) {
                        QuickStat(title: "Attacks", value: "\(gameManager.playerTurfs.filter { $0.isUnderAttack }.count)", icon: "exclamationmark.shield.fill", color: .red)
                        QuickStat(title: "Income", value: "$\(calculateIncome())/h", icon: "chart.line.uptrend.xyaxis", color: .green)
                        QuickStat(title: "Defense", value: "Avg \(averageDefense())", icon: "shield.fill", color: .blue)
                    }
                }
                .transition(.asymmetric(
                    insertion: .push(from: .top).combined(with: .opacity),
                    removal: .push(from: .bottom).combined(with: .opacity)
                ))
            }
        }
        .glassCard()
    }
    
    private func calculateIncome() -> Int {
        gameManager.playerTurfs.reduce(0) { $0 + Int($1.value * 0.1) }
    }
    
    private func averageDefense() -> Int {
        guard !gameManager.playerTurfs.isEmpty else { return 0 }
        return gameManager.playerTurfs.reduce(0) { $0 + $1.defenseLevel } / gameManager.playerTurfs.count
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView()
            .environmentObject(GameManager())
            .environmentObject(GameCenterService.shared)
            .padding()
            .background(Color.gray)
    }
}