import Foundation
import MapKit

extension LatLng {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

extension GeometryMeta {
    var coordinates: [CLLocationCoordinate2D] {
        switch self {
        case let .circle(centerLat, centerLng, _):
            return [CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)]
        case let .polygon(points):
            return points.map(\.coordinate)
        }
    }

    var region: MKCoordinateRegion {
        switch self {
        case let .circle(centerLat, centerLng, radiusMeters):
            let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
            let spanDegrees = max(0.04, radiusMeters / 111_000 * 2.4)
            return MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: spanDegrees, longitudeDelta: spanDegrees)
            )
        case let .polygon(points):
            guard let first = points.first else {
                return MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
                )
            }
            let minLat = points.map(\.lat).min() ?? first.lat
            let maxLat = points.map(\.lat).max() ?? first.lat
            let minLng = points.map(\.lng).min() ?? first.lng
            let maxLng = points.map(\.lng).max() ?? first.lng
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
                span: MKCoordinateSpan(latitudeDelta: max(0.04, (maxLat - minLat) * 1.4), longitudeDelta: max(0.04, (maxLng - minLng) * 1.4))
            )
        }
    }
}
