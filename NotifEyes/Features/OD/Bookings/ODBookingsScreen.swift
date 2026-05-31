import SwiftUI

struct ODBookingsScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var bookings: [BookingSummary] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if bookings.isEmpty {
                EmptyStateView(title: "No active bookings", message: "Booked shifts will appear here with contract and check-in actions.", systemImage: "checklist.checked")
            }

            ForEach(bookings) { booking in
                NavigationLink(value: Route.bookingDetail(booking.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(booking.practice.name)
                            .font(.headline)
                        Text(booking.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                        Text(formatUsd(booking.booking.totalCents - booking.booking.platformFeeCents))
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .refreshable {
            await load()
        }
        .task(id: session.user.id) {
            await load()
        }
    }

    private func load() async {
        guard let odId = session.user.odId else { return }
        do {
            bookings = try await env.api.myBookings(role: .od, subjectId: odId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}
