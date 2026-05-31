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
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var selectedTab: ODTab = .home
    @State private var homeRouter = Router()
    @State private var shiftsRouter = Router()
    @State private var watchRouter = Router()
    @State private var bookingsRouter = Router()
    @State private var messagesRouter = Router()
    @State private var profileRouter = Router()
    @State private var bannerNotification: AppNotification?
    @State private var messageUnreadCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TabNavigationStack(router: homeRouter, title: "Home") {
                ODHomeScreen(
                    session: session,
                    openShift: { openShift($0) },
                    openWatch: { selectedTab = .shifts }
                )
            }
            .tabItem { Label("Home", systemImage: "house") }
            .tag(ODTab.home)

            TabNavigationStack(router: shiftsRouter, title: "Shifts") {
                ODBrowseShiftsScreen(session: session, openShift: { openShift($0) })
            }
            .tabItem { Label("Shifts", systemImage: "calendar") }
            .tag(ODTab.shifts)

            TabNavigationStack(router: watchRouter, title: "Watch") {
                ODWatchZonesScreen(session: session, openEditor: { openWatchEditor($0) })
            }
            .tabItem { Label("Watch", systemImage: "scope") }
            .tag(ODTab.watch)

            TabNavigationStack(router: bookingsRouter, title: "Bookings") {
                ODBookingsScreen(session: session)
            }
            .tabItem { Label("Bookings", systemImage: "checklist.checked") }
            .tag(ODTab.bookings)

            TabNavigationStack(router: messagesRouter, title: "Messages") {
                MessagesListScreen(session: session)
            }
            .tabItem { Label("Messages", systemImage: "message") }
            .badge(messageUnreadCount)
            .tag(ODTab.messages)

            TabNavigationStack(router: profileRouter, title: "Profile") {
                ODProfileScreen(session: session)
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(ODTab.profile)
        }
        .safeAreaInset(edge: .top) {
            if let bannerNotification {
                NotificationBanner(notification: bannerNotification) {
                    handleBannerTap(bannerNotification)
                } onDismiss: {
                    withAnimation { self.bannerNotification = nil }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .task(id: session.user.id) {
            await loadPersistedBanner()
            await loadMessageUnreadCount()
            for await notification in env.api.notificationStream(for: session.user.id) {
                withAnimation {
                    bannerNotification = notification
                }
                await loadMessageUnreadCount()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            guard newTab == .messages else { return }
            Task { await loadMessageUnreadCount() }
        }
    }

    private func openShift(_ id: Shift.ID) {
        selectedTab = .shifts
        shiftsRouter.append(.shiftDetail(id))
    }

    private func openWatchEditor(_ id: WatchZone.ID?) {
        selectedTab = .watch
        watchRouter.append(.watchZoneEditor(id))
    }

    private func handleBannerTap(_ notification: AppNotification) {
        if let route = notification.actionUrl.flatMap(DeepLink.parse) {
            routeTo(route)
        }
        Task {
            try? await env.api.markRead(notification.id)
        }
        withAnimation {
            bannerNotification = nil
        }
    }

    private func routeTo(_ route: Route) {
        switch route {
        case .shiftDetail:
            selectedTab = .shifts
            shiftsRouter.append(route)
        case .bookingDetail:
            selectedTab = .bookings
            bookingsRouter.append(route)
        case .messageThread:
            selectedTab = .messages
            messagesRouter.append(route)
        case .watchZoneEditor:
            selectedTab = .watch
            watchRouter.append(route)
        case .odProfile, .practiceProfile, .review, .applicants:
            selectedTab = .shifts
            shiftsRouter.append(route)
        }
    }

    private func loadPersistedBanner() async {
        guard let notification = try? await env.api.notifications(for: session.user.id)
            .first(where: {
                $0.readAt == nil &&
                    ($0.kind == .watch_match || $0.kind == .message_received || $0.kind == .booking_confirmed)
            })
        else { return }

        withAnimation {
            bannerNotification = notification
        }
    }

    private func loadMessageUnreadCount() async {
        guard let threads = try? await env.api.threads(for: session.user.id) else { return }
        messageUnreadCount = threads.reduce(0) { $0 + $1.unreadCount }
    }
}
