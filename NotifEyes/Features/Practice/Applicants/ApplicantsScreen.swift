import SwiftUI

struct ApplicantsScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(Router.self) private var router

    var shiftId: Shift.ID

    @State private var detail: ShiftDetail?
    @State private var applicants: [ApplicantSummary] = []
    @State private var isBooking: Application.ID?
    @State private var isUpdating: Application.ID?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let detail {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(detail.practice.name)
                            .font(.headline)
                        Text(detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                        Text("\(applicants.count) applicant\(applicants.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Applicants") {
                if applicants.isEmpty {
                    EmptyStateView(title: "No applicants yet", message: "Applications appear here as soon as ODs apply.", systemImage: "person.crop.circle.badge.plus")
                }

                ForEach(applicants) { applicant in
                    ApplicantRow(
                        applicant: applicant,
                        isBooking: isBooking == applicant.application.id,
                        isUpdating: isUpdating == applicant.application.id,
                        shortlist: { Task { await update(applicant.application, to: .shortlisted) } },
                        offer: { Task { await update(applicant.application, to: .offered) } },
                        decline: { Task { await update(applicant.application, to: .declined) } },
                        book: { Task { await book(applicant.application) } }
                    )
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Applicants")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DemoSwitcherMenu()
            }
        }
        .refreshable {
            await load()
        }
        .task(id: shiftId) {
            await load()
        }
    }

    private func load() async {
        do {
            detail = try await env.api.shift(id: shiftId)
            applicants = try await env.api.applicants(for: shiftId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func book(_ application: Application) async {
        isBooking = application.id
        defer { isBooking = nil }
        do {
            let booking = try await env.api.bookApplicant(application.id)
            await load()
            router.append(.bookingDetail(booking.id))
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func update(_ application: Application, to status: ApplicationStatus) async {
        isUpdating = application.id
        defer { isUpdating = nil }
        do {
            _ = try await env.api.updateApplicationStatus(application.id, to: status)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct ApplicantRow: View {
    var applicant: ApplicantSummary
    var isBooking: Bool
    var isUpdating: Bool
    var shortlist: () -> Void
    var offer: () -> Void
    var decline: () -> Void
    var book: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                AvatarView(name: applicant.optometrist.displayName ?? applicant.optometrist.name)
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text(applicant.optometrist.displayName ?? applicant.optometrist.name)
                        .font(.headline)
                    Text("\(applicant.optometrist.verificationStatus.displayName) · \(applicant.optometrist.shiftsCompleted) shifts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        RatingStars(rating: applicant.optometrist.ratingAvg)
                        if let rating = applicant.optometrist.ratingAvg {
                            Text(String(format: "%.1f", rating))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    if let message = applicant.application.message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                    }
                }
                Spacer()
                StatusBadge(text: applicant.application.status.displayName, color: statusColor)
            }

            if applicant.application.status == .accepted {
                Label("Booking confirmed", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.notifEyesGreen)
            } else {
                HStack(spacing: 10) {
                    if applicant.application.status == .applied {
                        Button(isUpdating ? "Updating..." : "Shortlist") {
                            shortlist()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isUpdating || isBooking)
                    }

                    if applicant.application.status != .offered {
                        Button(isUpdating ? "Updating..." : "Offer") {
                            offer()
                        }
                        .buttonStyle(.bordered)
                        .disabled(
                            isUpdating ||
                                isBooking ||
                                applicant.application.status == .declined ||
                                applicant.application.status == .withdrawn
                        )
                    }

                    Menu("More") {
                        Button("Decline", role: .destructive) {
                            decline()
                        }
                        .disabled(applicant.application.status == .declined || applicant.application.status == .withdrawn)
                    }
                    .disabled(isUpdating || isBooking)
                }

                Button(isBooking ? "Booking..." : "Book OD") {
                    book()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(isBooking || isUpdating || applicant.application.status == .declined || applicant.application.status == .withdrawn)
            }
        }
        .padding(.vertical, 6)
    }

    private var statusColor: Color {
        switch applicant.application.status {
        case .accepted:
            return Color.notifEyesGreen
        case .declined, .withdrawn:
            return Color.red
        case .offered:
            return Color.orange
        case .shortlisted:
            return Color.notifEyesBlue
        case .applied:
            return Color.secondary
        }
    }
}
