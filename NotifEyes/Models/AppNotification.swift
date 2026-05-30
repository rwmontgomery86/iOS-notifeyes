import Foundation

struct AppNotification: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var userId: User.ID
    var kind: NotificationKind
    var payload: [String: String]
    var actionUrl: String?
    var readAt: Date?
    var createdAt: Date
}
