import SwiftUI

struct RouteDestinationView: View {
    @Environment(SessionStore.self) private var sessionStore

    var route: Route

    var body: some View {
        switch route {
        case let .shiftDetail(id):
            ShiftDetailScreen(shiftId: id)
        case let .bookingDetail(id):
            BookingDetailScreen(bookingId: id)
        case .odProfile:
            PlaceholderScreen(title: "OD profile", systemImage: "stethoscope", message: "Public OD profiles land here later.")
        case .practiceProfile:
            PlaceholderScreen(title: "Practice profile", systemImage: "building.2", message: "Public practice profiles land here later.")
        case .messageThread:
            PlaceholderScreen(title: "Message thread", systemImage: "message", message: "Thread composer lands here later.")
        case .review:
            PlaceholderScreen(title: "Review", systemImage: "star", message: "Review submission lands here later.")
        case let .applicants(id):
            ApplicantsScreen(shiftId: id)
        case let .watchZoneEditor(id):
            if let session = sessionStore.session {
                WatchZoneEditorScreen(zoneId: id, session: session)
            } else {
                PlaceholderScreen(title: "Watch-zone editor", systemImage: "map", message: "Choose a demo OD first.")
            }
        }
    }
}
