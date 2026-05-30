import Foundation

struct Shift: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var practiceId: Practice.ID
    var startsAt: Date
    var endsAt: Date
    var lunchMinutes: Int
    var type: ShiftType
    var rateCentsPerHour: Cents
    var bumpRateCentsPerHour: Cents?
    var bumpRadiusMeters: Int?
    var servicesNeeded: [String]
    var notesForOd: String?
    var visibility: ShiftVisibility
    var status: ShiftStatus
    var urgent: Bool
    var bookedApplicationId: Application.ID?
    var postedAt: Date?
}
