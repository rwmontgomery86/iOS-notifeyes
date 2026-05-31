import SwiftUI

struct PracticeBillingScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var lines: [BillingLine] = []
    @State private var bookingDetails: [Booking.ID: BookingDetail] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                LabeledContent("Practice total", value: formatUsd(totalCents))
                LabeledContent("OD coverage", value: formatUsd(subtotalCents))
                LabeledContent("NotifEyes fees", value: formatUsd(platformFeeCents))
            }

            Section("Invoices") {
                if lines.isEmpty && !isLoading {
                    EmptyStateView(
                        title: "No billing yet",
                        message: "Booked shifts create invoice lines here with platform fees and payment status.",
                        systemImage: "creditcard"
                    )
                }

                ForEach(lines) { line in
                    NavigationLink(value: Route.bookingDetail(line.bookingId)) {
                        BillingLineRow(line: line, detail: bookingDetails[line.bookingId])
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

    private var totalCents: Cents {
        lines.reduce(0) { $0 + $1.totalCents }
    }

    private var subtotalCents: Cents {
        lines.reduce(0) { $0 + $1.subtotalCents }
    }

    private var platformFeeCents: Cents {
        lines.reduce(0) { $0 + $1.platformFeeCents }
    }

    private func load() async {
        guard let practiceId = session.user.practiceId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedLines = try await env.api.invoices(for: practiceId)
            var loadedDetails: [Booking.ID: BookingDetail] = [:]
            for line in loadedLines {
                loadedDetails[line.bookingId] = try? await env.api.booking(id: line.bookingId)
            }
            lines = loadedLines
            bookingDetails = loadedDetails
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct BillingLineRow: View {
    var line: BillingLine
    var detail: BookingDetail?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.notifEyesInk)
                    Text(line.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(formatUsd(line.totalCents))
                    .font(.headline)
                    .foregroundStyle(Color.notifEyesInk)
            }

            HStack(spacing: 8) {
                StatusBadge(text: statusText, color: statusColor)
                Text("Issued \(line.issuedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 4) {
                LabeledContent("OD coverage", value: formatUsd(line.subtotalCents))
                LabeledContent("Platform fee", value: formatUsd(line.platformFeeCents))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var title: String {
        detail.map { $0.optometrist.displayName ?? $0.optometrist.name } ?? "OD coverage"
    }

    private var statusText: String {
        line.status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private var statusColor: Color {
        switch line.status {
        case "paid":
            return Color.notifEyesGreen
        case "authorized":
            return Color.notifEyesBlue
        case "cancelled":
            return Color.secondary
        default:
            return Color.orange
        }
    }
}
