import SwiftUI

struct NotificationsListScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(Router.self) private var router

    var session: Session
    var onNotificationStateChanged: () -> Void = {}

    @State private var notifications: [AppNotification] = []
    @State private var activeWatchZone: WatchZone?
    @State private var isLoading = false
    @State private var isSimulating = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if session.role == .od {
                demoSection
            }

            if hasUnread {
                Section {
                    Button {
                        Task { await markAllRead() }
                    } label: {
                        Label("Mark all read", systemImage: "checkmark.circle")
                    }
                }
            }

            Section("Notifications") {
                if notifications.isEmpty && !isLoading {
                    EmptyStateView(
                        title: "No notifications yet",
                        message: "Watch matches, applicant activity, booking updates, and messages appear here.",
                        systemImage: "bell"
                    )
                }

                ForEach(notifications) { notification in
                    Button {
                        Task { await open(notification) }
                    } label: {
                        NotificationRow(notification: notification)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        if notification.readAt == nil {
                            Button {
                                Task { await markRead(notification) }
                            } label: {
                                Label("Read", systemImage: "checkmark")
                            }
                            .tint(Color.notifEyesBlue)
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .refreshable {
            await load()
            onNotificationStateChanged()
        }
        .task(id: session.user.id) {
            await load()
            onNotificationStateChanged()
        }
    }

    private var demoSection: some View {
        Section("Demo") {
            Button {
                Task { await simulateMatchingShift() }
            } label: {
                Label(isSimulating ? "Simulating..." : "Simulate a matching shift", systemImage: "bell.badge")
            }
            .disabled(activeWatchZone == nil || isSimulating)

            if activeWatchZone == nil && !isLoading {
                Text("Create or resume a watch zone to generate a mock watch-match alert.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hasUnread: Bool {
        notifications.contains { $0.readAt == nil }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            notifications = try await env.api.notifications(for: session.user.id)
            if session.role == .od, let odId = session.user.odId {
                activeWatchZone = try await env.api.watchZones(for: odId).first { !$0.paused }
            } else {
                activeWatchZone = nil
            }
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func open(_ notification: AppNotification) async {
        do {
            if notification.readAt == nil {
                try await env.api.markRead(notification.id)
                await load()
                onNotificationStateChanged()
            }

            if let route = notification.actionUrl.flatMap(DeepLink.parse) {
                router.append(route)
            }
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func markRead(_ notification: AppNotification) async {
        do {
            try await env.api.markRead(notification.id)
            await load()
            onNotificationStateChanged()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func markAllRead() async {
        do {
            try await env.api.markAllRead(for: session.user.id)
            await load()
            onNotificationStateChanged()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func simulateMatchingShift() async {
        guard let activeWatchZone else {
            errorMessage = "Create or resume a watch zone to simulate a matching shift."
            return
        }

        isSimulating = true
        defer { isSimulating = false }

        do {
            _ = try await env.api.simulateMatchingShift(for: activeWatchZone.id)
            await load()
            onNotificationStateChanged()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct NotificationRow: View {
    var notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundStyle(notification.readAt == nil ? .white : Color.notifEyesBlue)
                .frame(width: 38, height: 38)
                .background(notification.readAt == nil ? Color.notifEyesBlue : Color.notifEyesBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.kind.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.notifEyesInk)

                    Spacer(minLength: 8)

                    Text(notification.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(notification.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    StatusBadge(
                        text: notification.readAt == nil ? "Unread" : "Read",
                        color: notification.readAt == nil ? Color.orange : Color.secondary
                    )

                    if notification.actionUrl != nil {
                        Label("Open", systemImage: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.notifEyesBlue)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var iconName: String {
        switch notification.kind {
        case .watch_match:
            return "scope"
        case .invite_received:
            return "envelope.badge"
        case .new_applicant:
            return "person.crop.circle.badge.plus"
        case .booking_confirmed:
            return "checkmark.seal"
        case .shift_reminder:
            return "calendar.badge.clock"
        case .cancellation:
            return "xmark.circle"
        case .no_show_check:
            return "exclamationmark.triangle"
        case .payout_sent:
            return "banknote"
        case .review_request:
            return "star.bubble"
        case .credential_expiring:
            return "doc.badge.clock"
        case .verification_decided:
            return "checkmark.shield"
        case .message_received:
            return "message"
        }
    }
}
