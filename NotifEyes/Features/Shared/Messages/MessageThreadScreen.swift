import SwiftUI

struct MessageThreadScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var threadId: MessageThread.ID

    @State private var thread: ThreadSummary?
    @State private var messages: [Message] = []
    @State private var draft = ""
    @State private var isLoading = false
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let thread {
                Section {
                    MessageThreadHeader(thread: thread, currentUserId: currentUserId)
                }
            }

            if isLoading && messages.isEmpty {
                ProgressView("Loading messages")
            } else if messages.isEmpty {
                EmptyStateView(
                    title: "No messages yet",
                    message: "Start the conversation from the composer below.",
                    systemImage: "message"
                )
            } else {
                Section {
                    ForEach(messages) { message in
                        MessageBubble(
                            message: message,
                            senderName: senderName(for: message.senderUserId),
                            isMine: message.senderUserId == currentUserId
                        )
                        .listRowSeparator(.hidden)
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
        .listStyle(.plain)
        .navigationTitle("Messages")
        .safeAreaInset(edge: .bottom) {
            composer
        }
        .refreshable {
            await load()
        }
        .task(id: threadId) {
            await load()
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await send() }
            } label: {
                Image(systemName: isSending ? "hourglass" : "paperplane.fill")
                    .font(.headline)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.borderedProminent)
            .disabled(trimmedDraft.isEmpty || isSending)
            .accessibilityLabel("Send message")
        }
        .padding(12)
        .background(.bar)
    }

    private var currentUserId: User.ID? {
        sessionStore.session?.user.id
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func load() async {
        guard let currentUserId else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await env.api.markThreadRead(threadId, by: currentUserId)
            let threads = try await env.api.threads(for: currentUserId)
            thread = threads.first { $0.id == threadId }
            messages = try await env.api.messages(in: threadId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func send() async {
        let body = trimmedDraft
        guard !body.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            _ = try await env.api.sendMessage(thread: threadId, body: body)
            draft = ""
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func senderName(for userId: User.ID?) -> String {
        guard let userId else { return "NotifEyes" }
        return thread?.participants.first { $0.id == userId }?.name ?? "Unknown"
    }
}

private struct MessageThreadHeader: View {
    var thread: ThreadSummary
    var currentUserId: User.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.notifEyesInk)

            HStack(spacing: 8) {
                if thread.thread.contextBookingId != nil {
                    StatusBadge(text: "Booking thread", color: Color.notifEyesGreen)
                } else if thread.thread.contextShiftId != nil {
                    StatusBadge(text: "Shift thread", color: Color.notifEyesBlue)
                }

                if thread.unreadCount > 0 {
                    StatusBadge(text: "\(thread.unreadCount) unread", color: Color.orange)
                }
            }
        }
        .padding(.vertical, 4)
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
}

private struct MessageBubble: View {
    var message: Message
    var senderName: String
    var isMine: Bool

    var body: some View {
        if message.senderUserId == nil {
            HStack {
                Spacer()
                Text(message.body)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.notifEyesLine.opacity(0.45), in: Capsule())
                Spacer()
            }
            .padding(.vertical, 4)
        } else {
            HStack(alignment: .bottom) {
                if isMine {
                    Spacer(minLength: 42)
                }

                VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                    Text(senderName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(message.body)
                        .font(.body)
                        .foregroundStyle(isMine ? .white : Color.notifEyesInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            isMine ? Color.notifEyesBlue : Color.notifEyesPanel,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                        .overlay {
                            if !isMine {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.notifEyesLine, lineWidth: 1)
                            }
                        }

                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: 280, alignment: isMine ? .trailing : .leading)

                if !isMine {
                    Spacer(minLength: 42)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
