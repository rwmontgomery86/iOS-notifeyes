import SwiftUI

struct MetricTile: View {
    var title: String
    var value: String
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.notifEyesBlue)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.notifEyesInk)
            if let footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.notifEyesPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.notifEyesLine, lineWidth: 1)
        }
    }
}
