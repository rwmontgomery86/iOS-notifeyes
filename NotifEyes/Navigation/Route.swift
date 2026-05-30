import Foundation

enum Route: Hashable {
    case shiftDetail(Shift.ID)
    case bookingDetail(Booking.ID)
    case odProfile(Optometrist.ID)
    case practiceProfile(Practice.ID)
    case messageThread(MessageThread.ID)
    case review(Booking.ID)
    case applicants(Shift.ID)
    case watchZoneEditor(WatchZone.ID?)
}
