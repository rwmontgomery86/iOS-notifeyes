import Foundation

extension ShiftType {
    var displayName: String {
        switch self {
        case .fill_in:
            return "Fill-in"
        case .half_day:
            return "Half-day"
        case .weekend:
            return "Weekend"
        case .recurring:
            return "Recurring"
        case .permanent:
            return "Permanent"
        }
    }
}

extension ShiftStatus {
    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .posted:
            return "Open"
        case .booked:
            return "Booked"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

extension ApplicationStatus {
    var displayName: String {
        switch self {
        case .applied:
            return "Applied"
        case .shortlisted:
            return "Shortlisted"
        case .offered:
            return "Offered"
        case .accepted:
            return "Booked"
        case .declined:
            return "Declined"
        case .withdrawn:
            return "Withdrawn"
        }
    }
}

extension BookingStatus {
    var displayName: String {
        switch self {
        case .confirmed:
            return "Confirmed"
        case .in_progress:
            return "In progress"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        case .no_show:
            return "No-show"
        }
    }
}

extension PayoutStatus {
    var displayName: String {
        switch self {
        case .scheduled:
            return "Scheduled"
        case .sent:
            return "Sent"
        case .failed:
            return "Failed"
        }
    }
}

extension VerificationStatus {
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .verified:
            return "Verified"
        case .rejected:
            return "Rejected"
        }
    }
}

extension Channel {
    var displayName: String {
        switch self {
        case .push:
            return "Push"
        case .email:
            return "Email"
        case .sms:
            return "SMS"
        }
    }
}

extension NotificationKind {
    var displayName: String {
        switch self {
        case .watch_match:
            return "Watch match"
        case .invite_received:
            return "Invite received"
        case .new_applicant:
            return "New applicant"
        case .booking_confirmed:
            return "Booking confirmed"
        case .shift_reminder:
            return "Shift reminder"
        case .cancellation:
            return "Cancellation"
        case .no_show_check:
            return "No-show check"
        case .payout_sent:
            return "Payout sent"
        case .review_request:
            return "Review request"
        case .credential_expiring:
            return "Credential expiring"
        case .verification_decided:
            return "Verification decided"
        case .message_received:
            return "Message received"
        }
    }
}

extension AppNotification {
    var summary: String {
        switch kind {
        case .watch_match:
            return "A posted shift matches one of your watch zones."
        case .new_applicant:
            return "An OD applied to one of your open shifts."
        case .booking_confirmed:
            return "A booking is confirmed and ready for next steps."
        case .shift_reminder:
            return "You have a shift coming up."
        case .message_received:
            return "You have a new message."
        default:
            return kind.displayName
        }
    }
}

extension APIError {
    var userMessage: String {
        switch self {
        case .notImplemented:
            return "This API is not implemented yet."
        case .notFound:
            return "That record could not be found."
        case let .invalid(message):
            return message
        case .unauthorized:
            return "You are not authorized for that action."
        }
    }
}

func userFacingMessage(for error: Error) -> String {
    if let apiError = error as? APIError {
        return apiError.userMessage
    }
    return error.localizedDescription
}
