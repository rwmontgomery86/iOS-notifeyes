import SwiftUI

struct RatingStars: View {
    var rating: Double?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: Double(index) <= (rating ?? 0) ? "star.fill" : "star")
                    .imageScale(.small)
            }
        }
        .foregroundStyle(.yellow)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let rating else { return "No rating yet" }
        return "\(rating) out of 5 stars"
    }
}
