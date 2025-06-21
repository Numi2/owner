//
//  TurfCashApp.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import SwiftUI

@main
struct TurfCashApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var gameManager = GameManager()
    @StateObject private var locationService = LocationService()
    @StateObject private var gameCenterService = GameCenterService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameManager)
                .environmentObject(locationService)
                .environmentObject(gameCenterService)
                .onAppear {
                    // Initialize game systems with location service
                    gameManager.initialize(locationService: locationService)
                }
        }
    }
}