import SwiftUI

enum PracticeTab: Hashable {
    case dashboard
    case post
    case billing
    case notifications
    case messages
    case settings
}

struct PracticeTabView: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var selectedTab: PracticeTab = .dashboard
    @State private var dashboardRouter = Router()
    @State private var postRouter = Router()
    @State private var billingRouter = Router()
    @State private var notificationsRouter = Router()
    @State private var messagesRouter = Router()
    @State private var settingsRouter = Router()
    @State private var bannerNotification: AppNotification?
    @State private var notificationUnreadCount = 0
    @State private var messageUnreadCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TabNavigationStack(router: dashboardRouter, title: "Dashboard") {
                PracticeDashboardScreen(
                    session: session,
                    openShift: { openShift($0) },
                    openApplicants: { openApplicants($0) }
                )
            }
            .tabItem { Label("Dashboard", systemImage: "rectangle.grid.2x2") }
            .tag(PracticeTab.dashboard)

            TabNavigationStack(router: postRouter, title: "Post a shift") {
                PostShiftScreen(session: session, onPosted: { postedShiftId in
                    selectedTab = .dashboard
                    dashboardRouter.append(.shiftDetail(postedShiftId))
                })
            }
            .tabItem { Label("Post a shift", systemImage: "plus.circle") }
            .tag(PracticeTab.post)

            TabNavigationStack(router: messagesRouter, title: "Messages") {
                MessagesListScreen(session: session)
            }
            .tabItem { Label("Messages", systemImage: "message") }
            .badge(messageUnreadCount)
            .tag(PracticeTab.messages)

            TabNavigationStack(router: notificationsRouter, title: "Notifications") {
                NotificationsListScreen(session: session, onNotificationStateChanged: {
                    Task { await loadNotificationUnreadCount() }
                })
            }
            .tabItem { Label("Notifications", systemImage: "bell") }
            .badge(notificationUnreadCount)
            .tag(PracticeTab.notifications)

            TabNavigationStack(router: billingRouter, title: "Billing") {
                PracticeBillingScreen(session: session)
            }
            .tabItem { Label("Billing", systemImage: "creditcard") }
            .tag(PracticeTab.billing)

            TabNavigationStack(router: settingsRouter, title: "Practice settings") {
                PlaceholderScreen(title: "Practice settings", systemImage: "gearshape", message: "Practice settings land later.")
            }
            .tabItem { Label("Practice settings", systemImage: "gearshape") }
            .tag(PracticeTab.settings)
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
        selectedTab = .dashboard
        dashboardRouter.append(.shiftDetail(id))
    }

    private func openApplicants(_ id: Shift.ID) {
        selectedTab = .dashboard
        dashboardRouter.append(.applicants(id))
    }

    private func handleBannerTap(_ notification: AppNotification) {
        if notification.kind == .new_applicant,
           let idString = notification.payload["shiftId"],
           let shiftId = UUID(uuidString: idString) {
            openApplicants(shiftId)
        } else if let route = notification.actionUrl.flatMap(DeepLink.parse) {
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
            selectedTab = .dashboard
            dashboardRouter.append(route)
        case .applicants:
            selectedTab = .dashboard
            dashboardRouter.append(route)
        case .bookingDetail:
            selectedTab = .billing
            billingRouter.append(route)
        case .messageThread:
            selectedTab = .messages
            messagesRouter.append(route)
        case .odProfile, .practiceProfile, .review, .watchZoneEditor:
            selectedTab = .dashboard
            dashboardRouter.append(route)
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
                    ($0.kind == .new_applicant || $0.kind == .booking_confirmed || $0.kind == .message_received)
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
