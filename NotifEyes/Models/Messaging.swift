import Foundation

struct MessageThread: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var contextBookingId: Booking.ID?
    var contextShiftId: Shift.ID?
    var lastMessageAt: Date?
}

struct Message: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var threadId: MessageThread.ID
    var senderUserId: User.ID?
    var body: String
    var createdAt: Date
    var systemKind: String?
}
