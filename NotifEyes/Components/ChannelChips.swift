import SwiftUI

struct ChannelChips: View {
    var channels: [Channel]

    var body: some View {
        HStack {
            ForEach(channels, id: \.self) { channel in
                StatusBadge(text: channel.rawValue.uppercased(), color: .secondary)
            }
        }
    }
}
