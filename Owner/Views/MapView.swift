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
        mapView.register(TurfAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        context.coordinator.mapView = mapView
        
        let initialLocation = locationService.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)
        let region = MKCoordinateRegion(center: initialLocation, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: false)
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.centerOnUser(_:)),
            name: .centerMapOnUser,
            object: nil
        )
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        updateAnnotations(on: uiView)
    }
    
    private func updateAnnotations(on mapView: MKMapView) {
        // Find annotations to add or remove
        let existingAnnotations = mapView.annotations.compactMap { $0 as? TurfAnnotation }
        let existingTurfIDs = Set(existingAnnotations.map { $0.turf.id })
        let nearbyTurfIDs = Set(gameManager.nearbyTurfs.map { $0.id })
        
        let turfsToAdd = gameManager.nearbyTurfs.filter { !existingTurfIDs.contains($0.id) }
        let annotationsToRemove = existingAnnotations.filter { !nearbyTurfIDs.contains($0.turf.id) }
        
        // Add new annotations
        mapView.addAnnotations(turfsToAdd.map { TurfAnnotation(turf: $0) })
        
        // Remove old annotations
        mapView.removeAnnotations(annotationsToRemove)
        
        // Update existing annotations that might have changed state
        for annotation in existingAnnotations {
            if let updatedTurf = gameManager.nearbyTurfs.first(where: { $0.id == annotation.turf.id }) {
                if annotation.turf.ownerID != updatedTurf.ownerID || annotation.turf.isUnderAttack != updatedTurf.isUnderAttack {
                    // This is a bit of a hack. MKAnnotation is not directly updatable.
                    // A better approach would be a custom notification system or more advanced state management.
                    // For now, we'll remove and re-add to force a refresh.
                    mapView.removeAnnotation(annotation)
                    mapView.addAnnotation(TurfAnnotation(turf: updatedTurf))
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        weak var mapView: MKMapView?
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let turfAnnotation = annotation as? TurfAnnotation else { return nil }
            
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: turfAnnotation) as! TurfAnnotationView
            view.configure(with: turfAnnotation.turf, gameManager: parent.gameManager)
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let turfAnnotation = view.annotation as? TurfAnnotation else { return }
            parent.selectedTurf = turfAnnotation.turf
            parent.showingActionSheet = true
            mapView.deselectAnnotation(view.annotation, animated: false) // Deselect to allow re-tapping
        }
        
        @objc func centerOnUser(_ notification: Notification) {
            guard let mapView = self.mapView,
                  let location = notification.object as? CLLocation else { return }
            
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
}

// MARK: - TurfAnnotation
class TurfAnnotation: NSObject, MKAnnotation {
    let turf: Turf
    
    init(turf: Turf) {
        self.turf = turf
        super.init()
    }
    
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        return turf.coordinate
    }
    
    // For comparison
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? TurfAnnotation else { return false }
        return turf.id == other.turf.id
    }
    
    override var hash: Int {
        return turf.id.hashValue
    }
}

// MARK: - TurfAnnotationView
class TurfAnnotationView: MKAnnotationView {
    private var shapeLayer = CAShapeLayer()
    private var iconImageView = UIImageView()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        
        // Setup shape layer for hexagon
        let path = UIBezierPath()
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = bounds.width / 2
        
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
        
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = 2.0
        shapeLayer.fillColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        shapeLayer.strokeColor = UIColor.gray.cgColor
        layer.addSublayer(shapeLayer)
        
        // Setup icon image view
        iconImageView.frame = bounds.insetBy(dx: 15, dy: 15)
        iconImageView.contentMode = .scaleAspectFit
        addSubview(iconImageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with turf: Turf, gameManager: GameManager) {
        let color = colorForTurf(turf, gameManager: gameManager)
        shapeLayer.fillColor = color.withAlphaComponent(0.5).cgColor
        shapeLayer.strokeColor = color.cgColor
        
        if turf.isUnderAttack {
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
            iconImageView.isHidden = false
        } else {
            iconImageView.isHidden = true
        }
    }
    
    private func colorForTurf(_ turf: Turf, gameManager: GameManager) -> UIColor {
        if turf.isNeutral {
            return .systemGray
        } else if turf.ownerID == gameManager.currentPlayer?.id {
            return .systemBlue
        } else {
            return .systemRed
        }
    }
}