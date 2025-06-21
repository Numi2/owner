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
        
        // Set initial region to user location if available
        if let location = locationService.currentLocation {
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Update hex overlays
        updateHexOverlays(on: uiView)
        
        // Update user location region
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
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle annotation selection if needed
        }
        
        func mapView(_ mapView: MKMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            // Find the turf at this coordinate
            let hexCoordinate = parent.locationService.hexGridCoordinate(from: coordinate)
            
            if let turf = parent.gameManager.nearbyTurfs.first(where: { 
                abs($0.coordinate.latitude - hexCoordinate.latitude) < 0.00001 &&
                abs($0.coordinate.longitude - hexCoordinate.longitude) < 0.00001
            }) {
                parent.selectedTurf = turf
                parent.showingActionSheet = true
            }
        }
        
        private func hexColor(for turf: Turf) -> UIColor {
            if turf.isUnderAttack {
                return .red
            } else if turf.isNeutral {
                return .gray
            } else if turf.ownerID == parent.gameManager.currentPlayer?.id {
                return .blue
            } else {
                return .red
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