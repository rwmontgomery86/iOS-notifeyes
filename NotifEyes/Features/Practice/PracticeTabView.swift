import SwiftUI

enum PracticeTab: Hashable {
    case dashboard
    case post
    case shifts
    case applicants
    case messages
    case settings
}

struct PracticeTabView: View {
    var session: Session

    @State private var selectedTab: PracticeTab = .dashboard
    @State private var dashboardRouter = Router()
    @State private var postRouter = Router()
    @State private var shiftsRouter = Router()
    @State private var applicantsRouter = Router()
    @State private var messagesRouter = Router()
    @State private var settingsRouter = Router()

    var body: some View {
        TabView(selection: $selectedTab) {
            TabNavigationStack(router: dashboardRouter, title: "Dashboard") {
                PracticeDashboardPlaceholder(session: session)
            }
            .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
            .tag(PracticeTab.dashboard)

            TabNavigationStack(router: postRouter, title: "Post") {
                PlaceholderScreen(title: "Post", systemImage: "plus.circle", message: "The stepped post-a-shift flow lands in Phase 2.")
            }
            .tabItem { Label("Post", systemImage: "plus.circle") }
            .tag(PracticeTab.post)

            TabNavigationStack(router: shiftsRouter, title: "Shifts") {
                PlaceholderScreen(title: "Shifts", systemImage: "calendar", message: "Open shifts and applicant counts land in Phase 2.")
            }
            .tabItem { Label("Shifts", systemImage: "calendar") }
            .tag(PracticeTab.shifts)

            TabNavigationStack(router: applicantsRouter, title: "Applicants") {
                PlaceholderScreen(title: "Applicants", systemImage: "person.crop.circle.badge.checkmark", message: "Applications and booking actions land in Phase 2.")
            }
            .tabItem { Label("Applicants", systemImage: "person.crop.circle.badge.checkmark") }
            .tag(PracticeTab.applicants)

            TabNavigationStack(router: messagesRouter, title: "Messages") {
                PlaceholderScreen(title: "Messages", systemImage: "message", message: "OD conversations land later.")
            }
            .tabItem { Label("Messages", systemImage: "message") }
            .tag(PracticeTab.messages)

            TabNavigationStack(router: settingsRouter, title: "Settings") {
                PlaceholderScreen(title: "Settings", systemImage: "gearshape", message: "Practice settings land later.")
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(PracticeTab.settings)
        }
    }
}

private struct PracticeDashboardPlaceholder: View {
    var session: Session

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.user.name ?? "Practice dashboard")
                        .font(.title2.weight(.bold))
                    Text("Open shifts and applicant counts land here next.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            Section("Phase 1 shell") {
                Label("Role-routed practice tab tree", systemImage: "checkmark.circle.fill")
                Label("Global demo switcher", systemImage: "person.2")
                Label("Per-tab navigation stacks", systemImage: "square.stack.3d.up")
            }
        }
    }
}
