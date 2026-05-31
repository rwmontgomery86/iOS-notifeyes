import SwiftUI

struct PracticeDashboardScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session
    var openShift: (Shift.ID) -> Void
    var openApplicants: (Shift.ID) -> Void

    @State private var openRows: [PracticeShiftRow] = []
    @State private var bookings: [BookingSummary] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.user.name ?? "Practice dashboard")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.notifEyesInk)
                    Text("Open shifts and applicant counts stay front and center.")
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    MetricTile(title: "Open shifts", value: "\(openRows.filter { $0.shift.status == .posted }.count)", footnote: "posted")
                    MetricTile(title: "Applicants", value: "\(openRows.reduce(0) { $0 + $1.applicantCount })", footnote: "active")
                    MetricTile(title: "Bookings", value: "\(activeBookings.count)", footnote: "confirmed")
                    MetricTile(title: "Authorized", value: formatUsd(activeBookings.reduce(0) { $0 + $1.booking.totalCents }), footnote: "practice total")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Open shifts")
                        .font(.headline)

                    if openRows.isEmpty {
                        EmptyStateView(title: "No posted shifts", message: "Post a shift to start receiving applicants.", systemImage: "calendar.badge.plus")
                    } else {
                        ForEach(openRows) { row in
                            PracticeShiftCard(row: row, openShift: openShift, openApplicants: openApplicants)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming bookings")
                        .font(.headline)
                    if bookings.isEmpty {
                        Text("Booked ODs will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(bookings.prefix(3)) { booking in
                            NavigationLink(value: Route.bookingDetail(booking.id)) {
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(booking.optometrist.displayName ?? booking.optometrist.name)
                                            .font(.headline)
                                        Text(booking.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                                            .foregroundStyle(.secondary)
                                        Text(formatUsd(booking.booking.totalCents))
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 8) {
                                        StatusBadge(
                                            text: booking.booking.status.rawValue.replacingOccurrences(of: "_", with: " "),
                                            color: booking.booking.status == .confirmed ? Color.notifEyesGreen : Color.notifEyesBlue
                                        )
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(12)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
        }
        .background(Color.notifEyesCanvas)
        .refreshable {
            await load()
        }
        .task(id: session.user.id) {
            await load()
        }
    }

    private var activeBookings: [BookingSummary] {
        bookings.filter { $0.booking.status == .confirmed || $0.booking.status == .in_progress }
    }

    private func load() async {
        guard let practiceId = session.user.practiceId else { return }
        do {
            let shifts = try await env.api.shiftsForPractice(practiceId, status: nil)
            var rows: [PracticeShiftRow] = []
            for shift in shifts {
                let applicants = try await env.api.applicants(for: shift.id)
                rows.append(PracticeShiftRow(shift: shift, applicantCount: applicants.count))
            }
            openRows = rows.filter { $0.shift.status == .posted || $0.applicantCount > 0 }
            bookings = try await env.api.myBookings(role: .practice, subjectId: practiceId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

struct PracticeShiftRow: Identifiable {
    var shift: ShiftSummary
    var applicantCount: Int

    var id: Shift.ID { shift.id }
}

struct PracticeShiftCard: View {
    var row: PracticeShiftRow
    var openShift: (Shift.ID) -> Void
    var openApplicants: (Shift.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                openShift(row.shift.id)
            } label: {
                ShiftCard(shift: row.shift)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            HStack {
                StatusBadge(text: "\(row.applicantCount) applicant\(row.applicantCount == 1 ? "" : "s")", color: Color.notifEyesBlue)
                Spacer()
                Button("Applicants") {
                    openApplicants(row.shift.id)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.notifEyesLine, lineWidth: 1)
        }
    }
}
