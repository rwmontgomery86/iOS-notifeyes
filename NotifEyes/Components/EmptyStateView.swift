import SwiftUI

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String = "tray"

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}
