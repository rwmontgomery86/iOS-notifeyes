import Foundation
import Observation

@Observable
final class ZoneDrawController {
    var name = "My zone"
    var center = LatLng(lat: 37.7749, lng: -122.4194)
    var radiusMiles = 25.0
    var daysOfWeek = [1, 2, 3, 4, 5, 6, 0]
    var timeStart: String?
    var timeEnd: String?
    var minRateCents: Cents = 10_000
    var shiftTypes: [ShiftType] = [.fill_in, .half_day, .weekend]
    var notifyChannels: [Channel] = [.push, .email]

    var radiusMeters: Double {
        radiusMiles * 1_609.344
    }

    func makeInput() -> CreateWatchZoneInput {
        CreateWatchZoneInput(
            name: name,
            geometryMeta: .circle(centerLat: center.lat, centerLng: center.lng, radiusMeters: radiusMeters),
            daysOfWeek: daysOfWeek,
            timeStart: timeStart,
            timeEnd: timeEnd,
            minRateCents: minRateCents,
            shiftTypes: shiftTypes,
            notifyChannels: notifyChannels
        )
    }
}
