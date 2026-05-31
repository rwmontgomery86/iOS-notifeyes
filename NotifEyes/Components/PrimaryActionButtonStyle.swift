import SwiftUI

struct PrimaryActionButtonStyle: ButtonStyle {
    var isProminent = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(isProminent ? .white : Color.notifEyesInk)
            .background(isProminent ? Color.notifEyesBlue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isProminent ? Color.clear : Color.notifEyesLine, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
