import Foundation

enum GeoCalculations {
    static func distanceMiles(_ lhs: LatLng, _ rhs: LatLng) -> Double {
        distanceMeters(lhs, rhs) / 1_609.344
    }

    static func distanceMeters(_ lhs: LatLng, _ rhs: LatLng) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lhsLat = lhs.lat * .pi / 180
        let rhsLat = rhs.lat * .pi / 180
        let deltaLat = (rhs.lat - lhs.lat) * .pi / 180
        let deltaLng = (rhs.lng - lhs.lng) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lhsLat) * cos(rhsLat) * sin(deltaLng / 2) * sin(deltaLng / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    static func polygon(_ points: [LatLng], contains point: LatLng) -> Bool {
        guard points.count >= 3 else { return false }
        var inside = false
        var j = points.count - 1
        for i in points.indices {
            let yi = points[i].lat
            let yj = points[j].lat
            let xi = points[i].lng
            let xj = points[j].lng
            if ((yi > point.lat) != (yj > point.lat))
                && (point.lng < (xj - xi) * (point.lat - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}

extension Date {
    var notifEyesDayOfWeek: Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.component(.weekday, from: self) - 1
    }

    var isNotifEyesWeekend: Bool {
        let weekday = notifEyesDayOfWeek
        return weekday == 0 || weekday == 6
    }

    func isWithinNext(days: Int) -> Bool {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return self >= calendar.startOfDay(for: Date()) && self <= end
    }
}
