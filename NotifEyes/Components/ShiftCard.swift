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
                } else if shift.status != .posted {
                    StatusBadge(text: shift.status.displayName, color: Color.secondary)
                }
            }
            Text("\(shift.startsAt.formatted(date: .abbreviated, time: .shortened)) - \(shift.endsAt.formatted(date: .omitted, time: .shortened))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Text("\(formatUsd(shift.rateCentsPerHour))/hr")
                    .font(.subheadline.weight(.semibold))
                Text(shift.type.displayName)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if let distanceMi = shift.distanceMi {
                    Text("\(distanceMi, specifier: "%.0f") mi")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
