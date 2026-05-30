import Foundation

enum DemoActor: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case mayaPatel
    case yaraBrennan
    case bayviewEyeCare

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mayaPatel:
            return "Maya Patel"
        case .yaraBrennan:
            return "Yara Brennan"
        case .bayviewEyeCare:
            return "Bayview Eye Care"
        }
    }

    var subtitle: String {
        switch self {
        case .mayaPatel:
            return "Verified OD"
        case .yaraBrennan:
            return "Pending OD"
        case .bayviewEyeCare:
            return "Practice owner"
        }
    }

    var demoEmail: String {
        switch self {
        case .mayaPatel:
            return "maya@example.com"
        case .yaraBrennan:
            return "yara@example.com"
        case .bayviewEyeCare:
            return "owner@bayview.example.com"
        }
    }
}

enum SessionRole: String, Codable, Hashable, Sendable {
    case od
    case practice
}

extension SessionRole {
    init(user: User) throws {
        if user.odId != nil {
            self = .od
        } else if user.practiceId != nil {
            self = .practice
        } else {
            throw APIError.unauthorized
        }
    }
}

struct ShiftFilter: Codable, Hashable, Sendable {
    var minRateCents: Cents?
    var types: [ShiftType]
    var near: LatLng?
    var radiusMi: Double?

    init(
        minRateCents: Cents? = nil,
        types: [ShiftType] = [],
        near: LatLng? = nil,
        radiusMi: Double? = nil
    ) {
        self.minRateCents = minRateCents
        self.types = types
        self.near = near
        self.radiusMi = radiusMi
    }
}

struct ShiftSummary: Identifiable, Codable, Hashable, Sendable {
    var id: Shift.ID
    var practiceName: String
    var practiceId: Practice.ID
    var startsAt: Date
    var endsAt: Date
    var type: ShiftType
    var rateCentsPerHour: Cents
    var bumpRateCentsPerHour: Cents?
    var status: ShiftStatus
    var urgent: Bool
    var location: LatLng?
    var distanceMi: Double?
}

struct ShiftDetail: Codable, Hashable, Sendable {
    var shift: Shift
    var practice: Practice
    var cost: ShiftCost
    var viewerApplication: Application?
}

struct ApplicantSummary: Identifiable, Codable, Hashable, Sendable {
    var application: Application
    var optometrist: Optometrist

    var id: Application.ID { application.id }
}

struct BookingDetail: Codable, Hashable, Sendable {
    var booking: Booking
    var shift: Shift
    var practice: Practice
    var optometrist: Optometrist
    var contract: Contract?
    var thread: MessageThread?
}

struct ThreadSummary: Identifiable, Codable, Hashable, Sendable {
    var thread: MessageThread
    var participants: [User]
    var lastMessage: Message?
    var unreadCount: Int

    var id: MessageThread.ID { thread.id }
}

struct BookingSummary: Identifiable, Codable, Hashable, Sendable {
    var booking: Booking
    var shift: Shift
    var practice: Practice
    var optometrist: Optometrist
    var contract: Contract?

    var id: Booking.ID { booking.id }
}

struct BillingLine: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var bookingId: Booking.ID
    var description: String
    var subtotalCents: Cents
    var platformFeeCents: Cents
    var totalCents: Cents
    var status: String
    var issuedAt: Date
}

struct CreateShiftInput: Codable, Hashable, Sendable {
    var startsAt: Date
    var endsAt: Date
    var lunchMinutes: Int
    var type: ShiftType
    var rateCentsPerHour: Cents
    var bumpRateCentsPerHour: Cents?
    var bumpRadiusMeters: Int?
    var servicesNeeded: [String]
    var notesForOd: String?
    var visibility: ShiftVisibility
    var urgent: Bool
}

struct CreateWatchZoneInput: Codable, Hashable, Sendable {
    var name: String
    var geometryMeta: GeometryMeta
    var daysOfWeek: [Int]
    var timeStart: String?
    var timeEnd: String?
    var minRateCents: Cents
    var shiftTypes: [ShiftType]
    var notifyChannels: [Channel]
}

struct UpdateWatchZoneInput: Codable, Hashable, Sendable {
    var name: String?
    var geometryMeta: GeometryMeta?
    var daysOfWeek: [Int]?
    var timeStart: String?
    var timeEnd: String?
    var minRateCents: Cents?
    var shiftTypes: [ShiftType]?
    var notifyChannels: [Channel]?
}

struct UpdateODInput: Codable, Hashable, Sendable {
    var name: String?
    var displayName: String?
    var bio: String?
    var headshotUrl: String?
    var homeLocation: LatLng?
    var travelRadiusMi: Double?
    var licenseState: String?
    var specialties: [String]?
    var ehrExperience: [String]?
}

struct UpdatePracticeInput: Codable, Hashable, Sendable {
    var name: String?
    var dba: String?
    var bio: String?
    var addressLine: String?
    var city: String?
    var state: String?
    var zip: String?
    var location: LatLng?
    var services: [String]?
    var languages: [String]?
}

struct SubmitReviewInput: Codable, Hashable, Sendable {
    var bookingId: Booking.ID
    var authorRole: ReviewAuthor
    var ratingOverall: Int
    var ratingSpecifics: [String: Int]
    var publicComment: String?
    var privateFeedback: String?
}
