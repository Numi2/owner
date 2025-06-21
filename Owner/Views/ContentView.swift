//
//  ContentView.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var gameCenterService: GameCenterService
    
    @State private var showingActionSheet = false
    @State private var selectedTurf: Turf?
    @State private var showingLocationAlert = false
    
    var body: some View {
        ZStack {
            // Map View
            MapView(selectedTurf: $selectedTurf, showingActionSheet: $showingActionSheet)
                .ignoresSafeArea()
            
            // HUD Overlay
            VStack {
                HUDView()
                    .padding()
                
                Spacer()
                
                // Debug info (remove in production)
                if let location = locationService.currentLocation {
                    VStack {
                        Text("Lat: \(location.coordinate.latitude, specifier: "%.6f")")
                        Text("Lon: \(location.coordinate.longitude, specifier: "%.6f")")
                        Text("Nearby Turfs: \(gameManager.nearbyTurfs.count)")
                        Text("My Turfs: \(gameManager.playerTurfs.count)")
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.bottom)
                }
            }
        }
        .sheet(isPresented: $showingActionSheet) {
            if let turf = selectedTurf {
                ActionSheetView(turf: turf)
            }
        }
        .alert("Location Access Required", isPresented: $showingLocationAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app requires location access to play. Please enable location services in Settings.")
        }
        .onChange(of: locationService.authorizationStatus) { _, newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showingLocationAlert = true
            }
        }
    }
}