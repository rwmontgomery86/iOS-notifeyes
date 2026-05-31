import SwiftUI

struct ODPayoutsScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var payouts: [Payout] = []
    @State private var bookingDetails: [Booking.ID: BookingDetail] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                LabeledContent("Total payouts", value: formatUsd(totalCents))
                LabeledContent("Sent", value: formatUsd(totalCents(for: .sent)))
                LabeledContent("Scheduled", value: formatUsd(totalCents(for: .scheduled)))
            }

            if payouts.isEmpty && !isLoading {
                EmptyStateView(
                    title: "No payouts yet",
                    message: "Completed coverage payouts appear here once NotifEyes schedules them.",
                    systemImage: "banknote"
                )
            }

            ForEach(groupedStatuses, id: \.self) { status in
                Section("\(status.displayName) · \(formatUsd(totalCents(for: status)))") {
                    ForEach(payouts.filter { $0.status == status }) { payout in
                        NavigationLink(value: Route.bookingDetail(payout.bookingId)) {
                            PayoutRow(payout: payout, detail: bookingDetails[payout.bookingId])
                        }
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .refreshable {
            await load()
        }
        .task(id: session.user.id) {
            await load()
        }
    }

    private var groupedStatuses: [PayoutStatus] {
        [.scheduled, .sent, .failed].filter { status in
            payouts.contains { $0.status == status }
        }
    }

    private var totalCents: Cents {
        payouts.reduce(0) { $0 + $1.amountCents }
    }

    private func totalCents(for status: PayoutStatus) -> Cents {
        payouts
            .filter { $0.status == status }
            .reduce(0) { $0 + $1.amountCents }
    }

    private func load() async {
        guard let odId = session.user.odId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedPayouts = try await env.api.payouts(for: odId)
            var loadedDetails: [Booking.ID: BookingDetail] = [:]
            for payout in loadedPayouts {
                loadedDetails[payout.bookingId] = try? await env.api.booking(id: payout.bookingId)
            }
            payouts = loadedPayouts
            bookingDetails = loadedDetails
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct PayoutRow: View {
    var payout: Payout
    var detail: BookingDetail?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "banknote")
                .font(.headline)
                .foregroundStyle(Color.notifEyesGreen)
                .frame(width: 38, height: 38)
                .background(Color.notifEyesGreen.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.notifEyesInk)

                    Spacer(minLength: 8)

                    Text(formatUsd(payout.amountCents))
                        .font(.headline)
                        .foregroundStyle(Color.notifEyesInk)
                }

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    StatusBadge(text: payout.status.displayName, color: statusColor)
                    Text(payoutDateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var title: String {
        detail?.practice.name ?? "Booking payout"
    }

    private var subtitle: String {
        guard let detail else { return "Coverage payout" }
        return detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened)
    }

    private var payoutDateText: String {
        if let sentAt = payout.sentAt {
            return "Sent \(sentAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Scheduled \(payout.scheduledFor.formatted(date: .abbreviated, time: .omitted))"
    }

    private var statusColor: Color {
        switch payout.status {
        case .scheduled:
            return Color.notifEyesBlue
        case .sent:
            return Color.notifEyesGreen
        case .failed:
            return Color.red
        }
    }
}
