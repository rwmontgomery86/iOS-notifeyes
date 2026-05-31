import MapKit
import SwiftUI

struct WatchZoneMap: View {
    var zones: [WatchZone]
    var shifts: [ShiftSummary]
    var onShiftTap: ((Shift.ID) -> Void)?

    var body: some View {
        Map {
            ForEach(zones) { zone in
                switch zone.geometryMeta {
                case let .circle(centerLat, centerLng, radiusMeters):
                    MapCircle(
                        center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng),
                        radius: radiusMeters
                    )
                    .foregroundStyle(.blue.opacity(0.18))
                    .stroke(.blue, lineWidth: 2)
                case let .polygon(points):
                    MapPolygon(coordinates: points.map(\.coordinate))
                        .foregroundStyle(.green.opacity(0.16))
                        .stroke(.green, lineWidth: 2)
                }
            }

            ForEach(shifts) { shift in
                if let location = shift.location {
                    Annotation(shift.practiceName, coordinate: location.coordinate) {
                        Button {
                            onShiftTap?(shift.id)
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(shift.urgent ? Color.red : Color.notifEyesBlue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
