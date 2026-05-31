import SwiftUI

struct ApplicantsScreen: View {
    @Environment(AppEnvironment.self) private var env

    var shiftId: Shift.ID

    @State private var detail: ShiftDetail?
    @State private var applicants: [ApplicantSummary] = []
    @State private var isBooking: Application.ID?
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
            _ = try await env.api.bookApplicant(application.id)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct ApplicantRow: View {
    var applicant: ApplicantSummary
    var isBooking: Bool
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
                    if let message = applicant.application.message, !message.isEmpty {
                        Text(message)
                            .font(.subheadline)
                    }
                }
                Spacer()
                StatusBadge(text: applicant.application.status.displayName, color: applicant.application.status == .accepted ? Color.notifEyesGreen : Color.notifEyesBlue)
            }

            Button(isBooking ? "Booking..." : "Book OD") {
                book()
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isBooking || applicant.application.status == .accepted)
        }
        .padding(.vertical, 6)
    }
}
