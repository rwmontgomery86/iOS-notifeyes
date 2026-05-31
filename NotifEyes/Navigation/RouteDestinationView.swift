import SwiftUI

struct RouteDestinationView: View {
    var route: Route

    var body: some View {
        switch route {
        case .shiftDetail:
            PlaceholderScreen(title: "Shift detail", systemImage: "calendar.badge.clock", message: "Shift detail lands here in Phase 2.")
        case .bookingDetail:
            PlaceholderScreen(title: "Booking detail", systemImage: "doc.text", message: "Booking contracts and day-of actions land here later.")
        case .odProfile:
            PlaceholderScreen(title: "OD profile", systemImage: "stethoscope", message: "Public OD profiles land here later.")
        case .practiceProfile:
            PlaceholderScreen(title: "Practice profile", systemImage: "building.2", message: "Public practice profiles land here later.")
        case .messageThread:
            PlaceholderScreen(title: "Message thread", systemImage: "message", message: "Thread composer lands here later.")
        case .review:
            PlaceholderScreen(title: "Review", systemImage: "star", message: "Review submission lands here later.")
        case .applicants:
            PlaceholderScreen(title: "Applicants", systemImage: "person.crop.circle.badge.checkmark", message: "Applicant review lands here in the practice loop.")
        case .watchZoneEditor:
            PlaceholderScreen(title: "Watch-zone editor", systemImage: "map", message: "Circle-by-radius zone editing lands here in Phase 2.")
        }
    }
}
