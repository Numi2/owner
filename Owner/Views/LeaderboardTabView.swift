import SwiftUI
import GameKit

struct LeaderboardTabView: View {
    @EnvironmentObject var gameCenterService: GameCenterService
    @EnvironmentObject var gameManager: GameManager
    
    @State private var selectedScope: LeaderboardScope = .global
    @State private var isLoadingLeaderboard = false
    @State private var leaderboardEntries: [LeaderboardEntry] = []
    
    enum LeaderboardScope: String, CaseIterable {
        case global = "Global"
        case friends = "Friends"
        case nearby = "Nearby"
        
        var systemImage: String {
            switch self {
            case .global: return "globe"
            case .friends: return "person.2"
            case .nearby: return "location.circle"
            }
        }
    }
    
    struct LeaderboardEntry: Identifiable {
        let id = UUID()
        let rank: Int
        let playerName: String
        let score: Int
        let turfsOwned: Int
        let isCurrentPlayer: Bool
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Scope Selector
                    Picker("Scope", selection: $selectedScope) {
                        ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                            Label(scope.rawValue, systemImage: scope.systemImage)
                                .tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Player Stats Card
                    PlayerStatsCard()
                        .padding(.horizontal)
                    
                    // Leaderboard List
                    VStack(spacing: 12) {
                        ForEach(mockLeaderboardData()) { entry in
                            LeaderboardRowView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshLeaderboard) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isLoadingLeaderboard ? 360 : 0))
                            .animation(isLoadingLeaderboard ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoadingLeaderboard)
                    }
                }
            }
            .onAppear {
                loadLeaderboardData()
            }
        }
    }
    
    private func mockLeaderboardData() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(rank: 1, playerName: "TurfMaster", score: 125000, turfsOwned: 45, isCurrentPlayer: false),
            LeaderboardEntry(rank: 2, playerName: "CashKing", score: 98000, turfsOwned: 38, isCurrentPlayer: false),
            LeaderboardEntry(rank: 3, playerName: "LandLord", score: 87500, turfsOwned: 35, isCurrentPlayer: false),
            LeaderboardEntry(rank: 4, playerName: gameCenterService.localPlayer?.displayName ?? "You", score: 75000, turfsOwned: gameManager.playerTurfs.count, isCurrentPlayer: true),
            LeaderboardEntry(rank: 5, playerName: "PropertyPro", score: 65000, turfsOwned: 28, isCurrentPlayer: false),
            LeaderboardEntry(rank: 6, playerName: "TurfTycoon", score: 58000, turfsOwned: 25, isCurrentPlayer: false),
            LeaderboardEntry(rank: 7, playerName: "CashCollector", score: 52000, turfsOwned: 22, isCurrentPlayer: false),
            LeaderboardEntry(rank: 8, playerName: "TerritoryKing", score: 48000, turfsOwned: 20, isCurrentPlayer: false),
        ]
    }
    
    private func loadLeaderboardData() {
        isLoadingLeaderboard = true
        // Simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoadingLeaderboard = false
        }
    }
    
    private func refreshLeaderboard() {
        loadLeaderboardData()
    }
}

// MARK: - Player Stats Card
struct PlayerStatsCard: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var gameCenterService: GameCenterService
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Your Ranking")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("#4")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue.gradient)
            }
            
            // Stats Grid
            HStack(spacing: 20) {
                StatItem(title: "Net Worth", value: "$\(gameManager.netWorth(), specifier: "%.0f")", icon: "dollarsign.circle.fill", color: .green)
                StatItem(title: "Turfs", value: "\(gameManager.playerTurfs.count)", icon: "hexagon.fill", color: .blue)
                StatItem(title: "Rank", value: "Top 5%", icon: "chart.line.uptrend.xyaxis", color: .orange)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(16)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row
struct LeaderboardRowView: View {
    let entry: LeaderboardTabView.LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(rankColor.gradient)
                    .frame(width: 40, height: 40)
                
                Text("\(entry.rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.playerName)
                    .font(.headline)
                    .fontWeight(entry.isCurrentPlayer ? .bold : .medium)
                    .foregroundColor(entry.isCurrentPlayer ? .blue : .primary)
                
                HStack(spacing: 12) {
                    Label("\(entry.turfsOwned) turfs", systemImage: "hexagon.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing) {
                Text("$\(entry.score)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(entry.isCurrentPlayer ? Color.blue.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isCurrentPlayer ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color.orange
        default: return .blue
        }
    }
}

// MARK: - Preview
struct LeaderboardTabView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardTabView()
            .environmentObject(GameCenterService.shared)
            .environmentObject(GameManager())
    }
}