import Foundation
import Observation

@Observable
final class ZoneDrawController {
    enum DrawShape: String, CaseIterable, Identifiable {
        case circle
        case polygon

        var id: String { rawValue }
    }

    var name = "My zone"
    var shape: DrawShape = .circle
    var center = LatLng(lat: 37.7749, lng: -122.4194)
    var radiusMiles = 25.0
    var polygonPoints: [LatLng] = []
    var daysOfWeek = [1, 2, 3, 4, 5, 6, 0]
    var timeStart: String?
    var timeEnd: String?
    var minRateCents: Cents = 10_000
    var shiftTypes: [ShiftType] = [.fill_in, .half_day, .weekend]
    var notifyChannels: [Channel] = [.push, .email]

    var radiusMeters: Double {
        radiusMiles * 1_609.344
    }

    var geometryMeta: GeometryMeta {
        switch shape {
        case .circle:
            return .circle(centerLat: center.lat, centerLng: center.lng, radiusMeters: radiusMeters)
        case .polygon:
            return .polygon(points: polygonPoints)
        }
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (shape == .circle || polygonPoints.count >= 3)
    }

    func load(zone: WatchZone) {
        name = zone.name
        daysOfWeek = zone.daysOfWeek
        timeStart = zone.timeStart
        timeEnd = zone.timeEnd
        minRateCents = zone.minRateCents
        shiftTypes = zone.shiftTypes
        notifyChannels = zone.notifyChannels

        switch zone.geometryMeta {
        case let .circle(centerLat, centerLng, radiusMeters):
            shape = .circle
            center = LatLng(lat: centerLat, lng: centerLng)
            radiusMiles = radiusMeters / 1_609.344
            polygonPoints = []
        case let .polygon(points):
            shape = .polygon
            polygonPoints = points
            if let first = points.first {
                center = first
            }
        }
    }

    func addMapPoint(_ point: LatLng) {
        switch shape {
        case .circle:
            center = point
        case .polygon:
            polygonPoints.append(point)
        }
    }

    func removeLastPolygonPoint() {
        _ = polygonPoints.popLast()
    }

    func clearPolygon() {
        polygonPoints.removeAll()
    }

    func makeInput() -> CreateWatchZoneInput {
        CreateWatchZoneInput(
            name: name,
            geometryMeta: geometryMeta,
            daysOfWeek: daysOfWeek,
            timeStart: timeStart,
            timeEnd: timeEnd,
            minRateCents: minRateCents,
            shiftTypes: shiftTypes,
            notifyChannels: notifyChannels
        )
    }

    func makeUpdateInput() -> UpdateWatchZoneInput {
        UpdateWatchZoneInput(
            name: name,
            geometryMeta: geometryMeta,
            daysOfWeek: daysOfWeek,
            timeStart: timeStart,
            timeEnd: timeEnd,
            minRateCents: minRateCents,
            shiftTypes: shiftTypes,
            notifyChannels: notifyChannels
        )
    }
}
