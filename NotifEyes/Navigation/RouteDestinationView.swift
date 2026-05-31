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
        case let .messageThread(id):
            MessageThreadScreen(threadId: id)
        case let .review(id):
            ReviewScreen(bookingId: id)
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
