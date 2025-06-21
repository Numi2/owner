import SwiftUI
import GameKit

struct ProfileTabView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var gameCenterService: GameCenterService
    @EnvironmentObject var locationService: LocationService
    
    @State private var showingSettings = false
    @State private var showingAchievements = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView()
                        .padding(.horizontal)
                    
                    // Stats Overview
                    StatsOverviewSection()
                        .padding(.horizontal)
                    
                    // Quick Actions
                    QuickActionsSection(
                        showingSettings: $showingSettings,
                        showingAchievements: $showingAchievements
                    )
                    .padding(.horizontal)
                    
                    // Recent Activity
                    RecentActivitySection()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView()
            }
        }
    }
}

// MARK: - Profile Header
struct ProfileHeaderView: View {
    @EnvironmentObject var gameCenterService: GameCenterService
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(gameCenterService.localPlayer?.displayName.prefix(2).uppercased() ?? "PL")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Player Info
            VStack(spacing: 4) {
                Text(gameCenterService.localPlayer?.displayName ?? "Player")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Level \(calculateLevel())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress to next level
            VStack(spacing: 8) {
                HStack {
                    Text("Progress to Level \(calculateLevel() + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(calculateProgress())%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: Double(calculateProgress()) / 100)
                    .tint(.blue)
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(20)
    }
    
    private func calculateLevel() -> Int {
        let netWorth = gameManager.netWorth()
        return Int(log10(max(netWorth, 1))) + 1
    }
    
    private func calculateProgress() -> Int {
        let netWorth = max(gameManager.netWorth(), 1)
        let currentLevelThreshold = pow(10.0, Double(calculateLevel() - 1))
        let nextLevelThreshold = pow(10.0, Double(calculateLevel()))
        let progress = (netWorth - currentLevelThreshold) / (nextLevelThreshold - currentLevelThreshold)
        return Int(progress * 100)
    }
}

// MARK: - Stats Overview
struct StatsOverviewSection: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(title: "Net Worth", value: "$\(gameManager.netWorth(), specifier: "%.0f")", icon: "dollarsign.circle.fill", color: .green)
                StatCard(title: "Wallet", value: "$\(gameManager.walletBalance, specifier: "%.0f")", icon: "wallet.pass.fill", color: .blue)
                StatCard(title: "Total Turfs", value: "\(gameManager.playerTurfs.count)", icon: "hexagon.fill", color: .purple)
                StatCard(title: "Defense Average", value: "Lvl \(averageDefenseLevel())", icon: "shield.fill", color: .orange)
            }
        }
    }
    
    private func averageDefenseLevel() -> Int {
        guard !gameManager.playerTurfs.isEmpty else { return 0 }
        let totalDefense = gameManager.playerTurfs.reduce(0) { $0 + $1.defenseLevel }
        return totalDefense / gameManager.playerTurfs.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions
struct QuickActionsSection: View {
    @Binding var showingSettings: Bool
    @Binding var showingAchievements: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            VStack(spacing: 0) {
                ActionRow(title: "Achievements", icon: "trophy.fill", color: .yellow) {
                    showingAchievements = true
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ActionRow(title: "Game Center", icon: "gamecontroller.fill", color: .green) {
                    // Show Game Center
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ActionRow(title: "Settings", icon: "gearshape.fill", color: .gray) {
                    showingSettings = true
                }
                
                Divider()
                    .padding(.leading, 56)
                
                ActionRow(title: "Help & Support", icon: "questionmark.circle.fill", color: .blue) {
                    // Show help
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct ActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - Recent Activity
struct RecentActivitySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                Button("See All") {
                    // Show all activity
                }
                .font(.caption)
            }
            
            VStack(spacing: 8) {
                ActivityRow(icon: "hexagon.fill", title: "Claimed Central Park", time: "2 hours ago", isPositive: true)
                ActivityRow(icon: "shield.slash", title: "Lost Times Square", time: "5 hours ago", isPositive: false)
                ActivityRow(icon: "arrow.up.circle", title: "Upgraded Brooklyn Bridge", time: "1 day ago", isPositive: true)
                ActivityRow(icon: "trophy", title: "Achieved Turf Master", time: "2 days ago", isPositive: true)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(isPositive ? .green : .red)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("notifications") private var notifications = true
    @AppStorage("soundEffects") private var soundEffects = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                    Toggle("Notifications", isOn: $notifications)
                    Toggle("Sound Effects", isOn: $soundEffects)
                }
                
                Section("Location") {
                    HStack {
                        Text("Location Services")
                        Spacer()
                        Text("Enabled")
                            .foregroundColor(.green)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    
                    Button("Terms of Service") {
                        // Open terms
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(mockAchievements()) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    struct Achievement: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let icon: String
        let isUnlocked: Bool
        let progress: Double
    }
    
    private func mockAchievements() -> [Achievement] {
        [
            Achievement(title: "First Turf", description: "Claim your first turf", icon: "flag.fill", isUnlocked: true, progress: 1.0),
            Achievement(title: "Turf Master", description: "Own 10 turfs", icon: "crown.fill", isUnlocked: true, progress: 1.0),
            Achievement(title: "Millionaire", description: "Reach $1M net worth", icon: "dollarsign.circle.fill", isUnlocked: false, progress: 0.75),
            Achievement(title: "Defender", description: "Successfully defend 50 attacks", icon: "shield.fill", isUnlocked: false, progress: 0.3),
        ]
    }
}

struct AchievementRow: View {
    let achievement: AchievementsView.Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.yellow.gradient : Color.gray.gradient)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !achievement.isUnlocked && achievement.progress > 0 {
                    ProgressView(value: achievement.progress)
                        .tint(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
            .environmentObject(GameManager())
            .environmentObject(GameCenterService.shared)
            .environmentObject(LocationService())
    }
}