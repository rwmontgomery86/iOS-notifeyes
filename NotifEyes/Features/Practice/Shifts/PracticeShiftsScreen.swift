import SwiftUI

struct PracticeShiftsScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session
    var openShift: (Shift.ID) -> Void
    var openApplicants: (Shift.ID) -> Void

    @State private var rows: [PracticeShiftRow] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if rows.isEmpty {
                EmptyStateView(title: "No shifts yet", message: "Posted shifts appear here with live applicant counts.", systemImage: "calendar")
            }

            ForEach(rows) { row in
                PracticeShiftCard(row: row, openShift: openShift, openApplicants: openApplicants)
                    .listRowSeparator(.hidden)
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .listStyle(.plain)
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
            var nextRows: [PracticeShiftRow] = []
            for shift in shifts {
                let applicants = try await env.api.applicants(for: shift.id)
                nextRows.append(PracticeShiftRow(shift: shift, applicantCount: applicants.count))
            }
            rows = nextRows
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}
