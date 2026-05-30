import Foundation

struct Booking: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var shiftId: Shift.ID
    var odId: Optometrist.ID
    var practiceId: Practice.ID
    var applicationId: Application.ID
    var contractId: Contract.ID?
    var totalCents: Cents
    var platformFeeCents: Cents
    var status: BookingStatus
    var checkInAt: Date?
    var checkOutAt: Date?
    var cancellationReason: String?
    var cancellationFeeCents: Cents?
    var paymentStatus: String
}
