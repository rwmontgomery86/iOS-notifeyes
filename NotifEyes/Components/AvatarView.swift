import SwiftUI

struct AvatarView: View {
    var name: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(.tint.opacity(0.14))
            Text(initials)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.tint)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }

    private var initials: String {
        let parts = (name ?? "NE")
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        return parts.isEmpty ? "NE" : String(parts)
    }
}
