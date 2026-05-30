import SwiftUI

struct MoneyText: View {
    var cents: Cents

    var body: some View {
        Text(formatUsd(cents))
            .monospacedDigit()
    }
}
