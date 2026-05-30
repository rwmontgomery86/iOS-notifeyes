import SwiftUI

struct ShiftCard: View {
    var shift: ShiftSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(shift.practiceName)
                    .font(.headline)
                Spacer()
                if shift.urgent {
                    StatusBadge(text: "Urgent", color: .red)
                }
            }
            Text("\(shift.startsAt.formatted(date: .abbreviated, time: .shortened)) - \(shift.endsAt.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            MoneyText(cents: shift.rateCentsPerHour)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 6)
    }
}
