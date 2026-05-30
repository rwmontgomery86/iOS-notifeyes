import Foundation

struct Review: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var bookingId: Booking.ID
    var authorRole: ReviewAuthor
    var ratingOverall: Int
    var ratingSpecifics: [String: Int]
    var publicComment: String?
    var privateFeedback: String?
    var publishedAt: Date?
}
