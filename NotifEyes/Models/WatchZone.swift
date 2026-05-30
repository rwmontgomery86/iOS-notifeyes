import Foundation

struct WatchZone: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var odId: Optometrist.ID
    var name: String
    var shape: WatchZoneShape
    var geometryMeta: GeometryMeta
    var daysOfWeek: [Int]
    var timeStart: String?
    var timeEnd: String?
    var minRateCents: Cents
    var shiftTypes: [ShiftType]
    var notifyChannels: [Channel]
    var paused: Bool
}
