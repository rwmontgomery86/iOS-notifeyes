import Foundation

struct Payout: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var bookingId: Booking.ID
    var odId: Optometrist.ID
    var amountCents: Cents
    var status: PayoutStatus
    var scheduledFor: Date
    var sentAt: Date?
}
