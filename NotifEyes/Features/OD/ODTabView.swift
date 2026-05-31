import SwiftUI

enum ODTab: Hashable {
    case shifts
    case watch
    case notifications
    case payouts
    case messages
    case profile
}

struct ODTabView: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var selectedTab: ODTab = .shifts
    @State private var shiftsRouter = Router()
    @State private var watchRouter = Router()
    @State private var notificationsRouter = Router()
    @State private var payoutsRouter = Router()
    @State private var messagesRouter = Router()
    @State private var profileRouter = Router()
    @State private var bannerNotification: AppNotification?
    @State private var notificationUnreadCount = 0
    @State private var messageUnreadCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TabNavigationStack(router: shiftsRouter, title: "Browse shifts") {
                ODBrowseShiftsScreen(session: session, openShift: { openShift($0) })
            }
            .tabItem { Label("Browse shifts", systemImage: "calendar") }
            .tag(ODTab.shifts)

            TabNavigationStack(router: watchRouter, title: "Watch zones") {
                ODWatchZonesScreen(session: session, openEditor: { openWatchEditor($0) })
            }
            .tabItem { Label("Watch zones", systemImage: "scope") }
            .tag(ODTab.watch)

            TabNavigationStack(router: notificationsRouter, title: "Notifications") {
                NotificationsListScreen(session: session, onNotificationStateChanged: {
                    Task { await loadNotificationUnreadCount() }
                })
            }
            .tabItem { Label("Notifications", systemImage: "bell") }
            .badge(notificationUnreadCount)
            .tag(ODTab.notifications)

            TabNavigationStack(router: messagesRouter, title: "Messages") {
                MessagesListScreen(session: session)
            }
            .tabItem { Label("Messages", systemImage: "message") }
            .badge(messageUnreadCount)
            .tag(ODTab.messages)

            TabNavigationStack(router: payoutsRouter, title: "Payouts") {
                ODPayoutsScreen(session: session)
            }
            .tabItem { Label("Payouts", systemImage: "banknote") }
            .tag(ODTab.payouts)

            TabNavigationStack(router: profileRouter, title: "My profile") {
                ODProfileScreen(session: session)
            }
            .tabItem { Label("My profile", systemImage: "person.crop.circle") }
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
            await loadNotificationUnreadCount()
            await loadMessageUnreadCount()
            for await notification in env.api.notificationStream(for: session.user.id) {
                withAnimation {
                    bannerNotification = notification
                }
                await loadNotificationUnreadCount()
                await loadMessageUnreadCount()
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .messages {
                Task { await loadMessageUnreadCount() }
            } else if newTab == .notifications {
                Task { await loadNotificationUnreadCount() }
            }
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
            await loadNotificationUnreadCount()
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
            selectedTab = .payouts
            payoutsRouter.append(route)
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

    private func loadNotificationUnreadCount() async {
        guard let count = try? await env.api.unreadCount(for: session.user.id) else { return }
        notificationUnreadCount = count
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
