import SwiftUI
import MapKit

struct MapTabView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var locationService: LocationService
    
    @Binding var hasInitialized: Bool
    @State private var showingActionSheet = false
    @State private var selectedTurf: Turf?
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    var body: some View {
        NavigationStack {
            ZStack {
                if hasInitialized {
                    // Map View
                    MapView(selectedTurf: $selectedTurf, showingActionSheet: $showingActionSheet)
                        .ignoresSafeArea()
                    
                    // Floating HUD with glass effect
                    VStack {
                        HUDView()
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        Spacer()
                    }
                    
                    // Floating action buttons
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            // Center on user location button
                            Button(action: {
                                HapticManager.shared.impact(.light)
                                centerOnUserLocation()
                            }) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                    .frame(width: 50, height: 50)
                                    .background(.thinMaterial)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 100) // Above tab bar
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                } else {
                    // Loading state with glass effect
                    LoadingView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TurfCash")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // Show game info or settings
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .sheet(isPresented: $showingActionSheet) {
            if let turf = selectedTurf {
                ActionSheetView(turf: turf)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationService.currentLocation {
            // Trigger map update to center on user
            NotificationCenter.default.post(name: .centerMapOnUser, object: location)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
            
            Text("Initializing TurfCash")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Setting up location services...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .glassCard(cornerRadius: 20, shadowRadius: 10)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let centerMapOnUser = Notification.Name("centerMapOnUser")
}

// MARK: - Preview
struct MapTabView_Previews: PreviewProvider {
    static var previews: some View {
        MapTabView(hasInitialized: .constant(true))
            .environmentObject(GameManager())
            .environmentObject(LocationService())
    }
}