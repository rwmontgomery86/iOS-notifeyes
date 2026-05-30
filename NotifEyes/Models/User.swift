import Foundation

struct User: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var email: String
    var role: UserRole
    var name: String?
    var practiceId: Practice.ID?
    var odId: Optometrist.ID?
    var phone: String?
    var emailOptedIn: Bool
    var smsOptedIn: Bool
}
