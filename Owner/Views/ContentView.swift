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
    @State private var hasInitialized = false
    
    var body: some View {
        ZStack {
            if hasInitialized {
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
                    } else {
                        VStack {
                            Text("Waiting for location...")
                            Text("Nearby Turfs: \(gameManager.nearbyTurfs.count)")
                            Text("My Turfs: \(gameManager.playerTurfs.count)")
                            
                            Button("Generate Test Turfs") {
                                gameManager.generateTestTurfs()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .font(.caption)
                        .padding(.horizontal)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom)
                    }
                }
            } else {
                // Loading screen
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Initializing TurfCash...")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Setting up location services and game data...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
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
            Button("Continue Without Location") {
                // Allow playing without precise location
                gameManager.generateTestTurfs()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This app works best with location access, but you can still play with test data.")
        }
        .onAppear {
            initializeGame()
        }
        .onChange(of: locationService.authorizationStatus) { _, newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showingLocationAlert = true
            }
        }
    }
    
    private func initializeGame() {
        // Initialize game with a delay to ensure everything is set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            gameManager.forceInitialize()
            hasInitialized = true
        }
    }
}