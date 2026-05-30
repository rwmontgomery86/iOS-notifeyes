import Foundation

struct Optometrist: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var displayName: String?
    var bio: String?
    var headshotUrl: String?
    var homeLocation: LatLng?
    var travelRadiusMi: Double
    var licenseState: String?
    var verificationStatus: VerificationStatus
    var specialties: [String]
    var ehrExperience: [String]
    var ratingAvg: Double?
    var ratingCount: Int
    var shiftsCompleted: Int
    var noShowCount: Int
}
