//
//  MapView.swift
//  Owner
//
//  Created by T on 6/21/25.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var locationService: LocationService
    
    @Binding var selectedTurf: Turf?
    @Binding var showingActionSheet: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        // Set initial region - use default location if no user location
        let initialLocation = locationService.currentLocation?.coordinate ?? 
                            CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        let region = MKCoordinateRegion(
            center: initialLocation,
            latitudinalMeters: 500,
            longitudinalMeters: 500
        )
        mapView.setRegion(region, animated: false)
        
        // Add size validation to prevent Metal layer issues
        DispatchQueue.main.async {
            if mapView.bounds.size.width > 0 && mapView.bounds.size.height > 0 {
                // Safe to proceed with Metal layer operations
                mapView.setNeedsDisplay()
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update hex overlays
        updateHexOverlays(on: uiView)
        
        // Update user location region if available
        if let location = locationService.currentLocation {
            let currentRegion = uiView.region
            let userLocation = location.coordinate
            
            // Only update region if user has moved significantly
            let distance = CLLocation(latitude: currentRegion.center.latitude, longitude: currentRegion.center.longitude)
                .distance(from: location)
            
            if distance > 100 { // 100 meters
                let region = MKCoordinateRegion(
                    center: userLocation,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                uiView.setRegion(region, animated: true)
            }
        }
    }
    
    private func updateHexOverlays(on mapView: MKMapView) {
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)
        
        // Add hex overlays for nearby turfs
        for turf in gameManager.nearbyTurfs {
            let hexOverlay = HexOverlay(turf: turf)
            mapView.addOverlay(hexOverlay)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let hexOverlay = overlay as? HexOverlay {
                let renderer = MKPolygonRenderer(polygon: hexOverlay.polygon)
                
                // Color based on turf ownership
                let color = hexColor(for: hexOverlay.turf)
                renderer.fillColor = color.withAlphaComponent(0.3)
                renderer.strokeColor = color
                renderer.lineWidth = 2.0
                
                return renderer
            }
            
            return MKOverlayRenderer(overlay: overlay)
        }
        
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            let mapView = gesture.view as! MKMapView
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Find the nearest turf to the tap location
            var nearestTurf: Turf?
            var minDistance = Double.infinity
            
            for turf in parent.gameManager.nearbyTurfs {
                let turfLocation = CLLocation(latitude: turf.latitude, longitude: turf.longitude)
                let tapLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let distance = turfLocation.distance(from: tapLocation)
                
                if distance < minDistance && distance < 50 { // Within 50 meters
                    minDistance = distance
                    nearestTurf = turf
                }
            }
            
            if let turf = nearestTurf {
                parent.selectedTurf = turf
                parent.showingActionSheet = true
            }
        }
        
        private func hexColor(for turf: Turf) -> UIColor {
            if turf.isUnderAttack {
                return .systemRed
            } else if turf.isNeutral {
                return .systemGray
            } else if turf.ownerID == parent.gameManager.currentPlayer?.id {
                return .systemBlue
            } else {
                return .systemRed
            }
        }
    }
}

// MARK: - HexOverlay
class HexOverlay: NSObject, MKOverlay {
    let turf: Turf
    let polygon: MKPolygon
    
    init(turf: Turf) {
        self.turf = turf
        
        // Create hexagon points
        let hexSize = GameConstants.hexGridSize * 0.8 // Slightly smaller for visual spacing
        let center = turf.coordinate
        
        var coordinates: [CLLocationCoordinate2D] = []
        for i in 0..<6 {
            let angle = Double(i) * Double.pi / 3.0
            let lat = center.latitude + hexSize * cos(angle)
            let lon = center.longitude + hexSize * sin(angle)
            coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        self.polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        super.init()
    }
    
    var coordinate: CLLocationCoordinate2D {
        return turf.coordinate
    }
    
    var boundingMapRect: MKMapRect {
        return polygon.boundingMapRect
    }
}