import Foundation

struct Contract: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var bookingId: Booking.ID
    var templateVersion: String
    var bodyText: String
    var signedByPracticeAt: Date?
    var signedByOdAt: Date?
}
