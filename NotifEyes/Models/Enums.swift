import Foundation

enum UserRole: String, Codable, Hashable, Sendable {
    case practice_owner
    case practice_scheduler
    case od
    case admin
}

enum ShiftType: String, Codable, Hashable, CaseIterable, Sendable {
    case fill_in
    case half_day
    case weekend
    case recurring
    case permanent
}

enum ShiftStatus: String, Codable, Hashable, Sendable {
    case draft
    case posted
    case booked
    case completed
    case cancelled
}

enum ShiftVisibility: String, Codable, Hashable, Sendable {
    case `public`
    case favorites
    case invite_only
}

enum ApplicationSource: String, Codable, Hashable, Sendable {
    case apply
    case invite
    case watch_alert
}

enum ApplicationStatus: String, Codable, Hashable, Sendable {
    case applied
    case shortlisted
    case offered
    case accepted
    case declined
    case withdrawn
}

enum BookingStatus: String, Codable, Hashable, Sendable {
    case confirmed
    case in_progress
    case completed
    case cancelled
    case no_show
}

enum PayoutStatus: String, Codable, Hashable, Sendable {
    case scheduled
    case sent
    case failed
}

enum WatchZoneShape: String, Codable, Hashable, Sendable {
    case circle
    case polygon
}

enum ReviewAuthor: String, Codable, Hashable, Sendable {
    case practice
    case od
}

enum VerificationStatus: String, Codable, Hashable, Sendable {
    case pending
    case verified
    case rejected
}

enum Channel: String, Codable, Hashable, CaseIterable, Sendable {
    case push
    case email
    case sms
}

enum NotificationKind: String, Codable, Hashable, Sendable {
    case watch_match
    case invite_received
    case new_applicant
    case booking_confirmed
    case shift_reminder
    case cancellation
    case no_show_check
    case payout_sent
    case review_request
    case credential_expiring
    case verification_decided
    case message_received
}
