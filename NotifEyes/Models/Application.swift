import Foundation

struct Application: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var shiftId: Shift.ID
    var odId: Optometrist.ID
    var source: ApplicationSource
    var message: String?
    var status: ApplicationStatus
    var createdAt: Date
}
