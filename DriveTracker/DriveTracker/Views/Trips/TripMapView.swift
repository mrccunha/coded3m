import SwiftUI
import MapKit

struct TripMapView: UIViewRepresentable {
    let trip: Trip

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        let points = trip.orderedRoutePoints
        guard !points.isEmpty else { return }

        // Draw polyline route
        let coords = points.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(polyline)

        // Start annotation
        let startPin = SpeedAnnotation(
            coordinate: coords.first!,
            title: "Início",
            subtitle: trip.startDate.formatted(date: .omitted, time: .shortened),
            type: .start
        )
        mapView.addAnnotation(startPin)

        // End annotation
        if let lastCoord = coords.last, !trip.isActive {
            let endPin = SpeedAnnotation(
                coordinate: lastCoord,
                title: "Fim",
                subtitle: trip.endDate?.formatted(date: .omitted, time: .shortened) ?? "",
                type: .end
            )
            mapView.addAnnotation(endPin)
        }

        // Max speed annotation
        if trip.maxSpeed > 0 {
            let maxPin = SpeedAnnotation(
                coordinate: trip.maxSpeedLocation,
                title: "Vel. Máxima",
                subtitle: String(format: "%.0f km/h", trip.maxSpeed),
                type: .maxSpeed
            )
            mapView.addAnnotation(maxPin)
        }

        // Min speed annotation
        let safeMin = trip.minSpeed < Double.greatestFiniteMagnitude ? trip.minSpeed : 0
        if safeMin > 0 {
            let minPin = SpeedAnnotation(
                coordinate: trip.minSpeedLocation,
                title: "Vel. Mínima",
                subtitle: String(format: "%.0f km/h", safeMin),
                type: .minSpeed
            )
            mapView.addAnnotation(minPin)
        }

        // Fit region
        let padding = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: padding, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let pin = annotation as? SpeedAnnotation else { return nil }
            let id = "speedPin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)

            view.annotation = annotation
            view.canShowCallout = true

            switch pin.type {
            case .maxSpeed:
                view.markerTintColor = .systemRed
                view.glyphImage = UIImage(systemName: "arrow.up.circle.fill")
            case .minSpeed:
                view.markerTintColor = .systemGreen
                view.glyphImage = UIImage(systemName: "arrow.down.circle.fill")
            case .start:
                view.markerTintColor = .systemBlue
                view.glyphImage = UIImage(systemName: "play.fill")
            case .end:
                view.markerTintColor = .systemGray
                view.glyphImage = UIImage(systemName: "stop.fill")
            }

            return view
        }
    }
}
