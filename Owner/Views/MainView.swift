import SwiftUI
import CoreLocation

struct MainView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var gameCenterService: GameCenterService
    
    @State private var selectedTab = 0
    @State private var hasInitialized = false
    @State private var showingLocationAlert = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Map Tab
            MapTabView(hasInitialized: $hasInitialized)
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)
            
            // My Turfs Tab
            TurfsTabView()
                .tabItem {
                    Label("Turfs", systemImage: "hexagon.fill")
                }
                .tag(1)
                .badge(gameManager.playerTurfs.count)
            
            // Leaderboard Tab
            LeaderboardTabView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
                .tag(2)
            
            // Profile Tab
            ProfileTabView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
        }
        // Modern tab bar appearance
        .onAppear {
            // Let the system handle the appearance for Liquid Glass
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            
            // Remove custom background to let Liquid Glass show through
            appearance.backgroundEffect = nil
            appearance.backgroundColor = .clear
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            initializeGame()
        }
        .alert("Location Access Required", isPresented: $showingLocationAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Continue Without Location") {
                gameManager.generateTestTurfs()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app works best with location access, but you can still play with test data.")
        }
        .onChange(of: locationService.authorizationStatus) { _, newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showingLocationAlert = true
            }
        }
    }
    
    private func initializeGame() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            gameManager.forceInitialize()
            hasInitialized = true
        }
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(GameManager())
            .environmentObject(LocationService())
            .environmentObject(GameCenterService.shared)
    }
}
