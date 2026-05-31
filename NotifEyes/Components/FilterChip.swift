import SwiftUI

struct FilterChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.notifEyesInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.notifEyesInk : Color.clear)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.notifEyesInk : Color.notifEyesLine, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}
