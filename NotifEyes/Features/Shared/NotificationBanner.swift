import SwiftUI

struct NotificationBanner: View {
    var notification: AppNotification
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.notifEyesBlue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.kind.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.notifEyesInk)
                    Text(notification.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss notification")
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.notifEyesLine, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 12)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch notification.kind {
        case .watch_match:
            return "scope"
        case .new_applicant:
            return "person.crop.circle.badge.plus"
        case .booking_confirmed:
            return "checkmark.seal"
        case .message_received:
            return "message"
        default:
            return "bell"
        }
    }
}
