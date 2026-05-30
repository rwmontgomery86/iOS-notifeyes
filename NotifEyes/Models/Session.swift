import Foundation

struct Session: Codable, Hashable, Sendable {
    var user: User
    var role: SessionRole
}
