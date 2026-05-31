import SwiftUI

enum ODTab: Hashable {
    case home
    case shifts
    case watch
    case bookings
    case messages
    case profile
}

struct ODTabView: View {
    var session: Session

    @State private var selectedTab: ODTab = .home
    @State private var homeRouter = Router()
    @State private var shiftsRouter = Router()
    @State private var watchRouter = Router()
    @State private var bookingsRouter = Router()
    @State private var messagesRouter = Router()
    @State private var profileRouter = Router()

    var body: some View {
        TabView(selection: $selectedTab) {
            TabNavigationStack(router: homeRouter, title: "Home") {
                ODHomePlaceholder(session: session)
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(ODTab.home)

            TabNavigationStack(router: shiftsRouter, title: "Shifts") {
                PlaceholderScreen(title: "Shifts", systemImage: "calendar.badge.clock", message: "Browse matching and nearby shifts in Phase 2.")
            }
            .tabItem { Label("Shifts", systemImage: "calendar") }
            .tag(ODTab.shifts)

            TabNavigationStack(router: watchRouter, title: "Watch") {
                PlaceholderScreen(title: "Watch", systemImage: "map", message: "Watch zones and alerts land in Phase 2.")
            }
            .tabItem { Label("Watch", systemImage: "scope") }
            .tag(ODTab.watch)

            TabNavigationStack(router: bookingsRouter, title: "Bookings") {
                PlaceholderScreen(title: "Bookings", systemImage: "checklist.checked", message: "Your confirmed shifts and contracts land later.")
            }
            .tabItem { Label("Bookings", systemImage: "checklist.checked") }
            .tag(ODTab.bookings)

            TabNavigationStack(router: messagesRouter, title: "Messages") {
                PlaceholderScreen(title: "Messages", systemImage: "message", message: "Practice conversations land later.")
            }
            .tabItem { Label("Messages", systemImage: "message") }
            .tag(ODTab.messages)

            TabNavigationStack(router: profileRouter, title: "Profile") {
                PlaceholderScreen(title: "Profile", systemImage: "person.crop.circle", message: "OD profile completion lands later.")
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(ODTab.profile)
        }
    }
}

private struct ODHomePlaceholder: View {
    var session: Session

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome, \(session.user.name ?? "OD")")
                        .font(.title2.weight(.bold))
                    Text("Watch-match alerts and nearby shifts land here next.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Phase 1 shell") {
                Label("Role-routed OD tab tree", systemImage: "checkmark.circle.fill")
                Label("Global demo switcher", systemImage: "person.2")
                Label("Per-tab navigation stacks", systemImage: "square.stack.3d.up")
            }
        }
    }
}
