import SwiftUI

struct MessagesListScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var threads: [ThreadSummary] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if threads.isEmpty {
                EmptyStateView(
                    title: "No messages yet",
                    message: "Booking and shift conversations appear here.",
                    systemImage: "message"
                )
            }

            ForEach(threads) { thread in
                NavigationLink(value: Route.messageThread(thread.id)) {
                    MessageThreadRow(thread: thread, currentUserId: session.user.id)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .refreshable {
            await load()
        }
        .task(id: session.user.id) {
            await load()
        }
    }

    private func load() async {
        do {
            threads = try await env.api.threads(for: session.user.id)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct MessageThreadRow: View {
    var thread: ThreadSummary
    var currentUserId: User.ID

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(name: title)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.notifEyesInk)
                    Spacer()
                    if let lastMessageAt = thread.thread.lastMessageAt {
                        Text(lastMessageAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    if thread.thread.contextBookingId != nil {
                        StatusBadge(text: "Booking", color: Color.notifEyesGreen)
                    } else if thread.thread.contextShiftId != nil {
                        StatusBadge(text: "Shift", color: Color.notifEyesBlue)
                    }

                    if thread.unreadCount > 0 {
                        StatusBadge(text: "\(thread.unreadCount) new", color: Color.orange)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var title: String {
        let names = thread.participants
            .filter { $0.id != currentUserId }
            .compactMap { $0.name ?? $0.email }

        if names.isEmpty {
            return "Conversation"
        }
        return names.joined(separator: ", ")
    }

    private var preview: String {
        guard let lastMessage = thread.lastMessage else {
            return "No messages yet."
        }
        return lastMessage.body
    }
}
