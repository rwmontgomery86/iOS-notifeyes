import Foundation

struct Practice: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var dba: String?
    var bio: String?
    var addressLine: String?
    var city: String?
    var state: String?
    var zip: String?
    var location: LatLng?
    var services: [String]
    var languages: [String]
    var ratingAvg: Double?
    var ratingCount: Int
    var shiftsCompleted: Int
    var businessLicenseVerified: Bool
    var paymentMethodVerified: Bool
}
