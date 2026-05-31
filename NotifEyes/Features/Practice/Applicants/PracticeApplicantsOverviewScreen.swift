import SwiftUI

struct PracticeApplicantsOverviewScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var rows: [PracticeApplicantsRow] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if rows.isEmpty {
                EmptyStateView(title: "No open applicants", message: "When ODs apply, Bayview can review and book them here.", systemImage: "person.crop.circle.badge.checkmark")
            }

            ForEach(rows) { row in
                NavigationLink(value: Route.applicants(row.shift.id)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.shift.practiceName)
                            .font(.headline)
                        Text(row.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                        Text("\(row.applicants.count) applicant\(row.applicants.count == 1 ? "" : "s")")
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
        guard let practiceId = session.user.practiceId else { return }
        do {
            let shifts = try await env.api.shiftsForPractice(practiceId, status: nil)
            var nextRows: [PracticeApplicantsRow] = []
            for shift in shifts {
                let applicants = try await env.api.applicants(for: shift.id)
                if !applicants.isEmpty {
                    nextRows.append(PracticeApplicantsRow(shift: shift, applicants: applicants))
                }
            }
            rows = nextRows
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}

private struct PracticeApplicantsRow: Identifiable {
    var shift: ShiftSummary
    var applicants: [ApplicantSummary]

    var id: Shift.ID { shift.id }
}
