//
//  LocationService.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: Error?
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // Update every 5 meters
        
        // Request authorization on init
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization() // Use WhenInUse instead of Always for easier testing
        case .denied, .restricted:
            // Handle denied state - show alert to user
            print("Location access denied")
        case .authorizedWhenInUse:
            startLocationUpdates()
        case .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            print("Location authorization not granted")
            return
        }
        
        locationManager.startUpdatingLocation()
        // Only use significant location changes if we have Always authorization
        if authorizationStatus == .authorizedAlways {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    func distanceFromCurrentLocation(to coordinate: CLLocationCoordinate2D) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return currentLocation.distance(from: targetLocation)
    }
    
    func isWithinRange(of coordinate: CLLocationCoordinate2D, range: Double = 25.0) -> Bool {
        // If we don't have location, assume in range for testing
        guard let distance = distanceFromCurrentLocation(to: coordinate) else { return true }
        return distance <= range
    }
    
    // Convert real coordinates to hex-grid aligned coordinates
    func hexGridCoordinate(from coordinate: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let hexSize = GameConstants.hexGridSize
        let hexLat = round(coordinate.latitude / hexSize) * hexSize
        let hexLon = round(coordinate.longitude / hexSize) * hexSize
        return CLLocationCoordinate2D(latitude: hexLat, longitude: hexLon)
    }
    
    func currentHexCoordinate() -> CLLocationCoordinate2D? {
        guard let currentLocation = currentLocation else { return nil }
        return hexGridCoordinate(from: currentLocation.coordinate)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationError = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}