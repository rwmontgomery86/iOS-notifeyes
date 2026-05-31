import SwiftUI

struct ShiftDetailScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var shiftId: Shift.ID

    @State private var detail: ShiftDetail?
    @State private var isApplying = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let detail {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(detail.practice.name)
                                    .font(.title2.weight(.bold))
                                Text(address(detail.practice))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(text: detail.shift.status.displayName, color: detail.shift.status == .posted ? Color.notifEyesGreen : Color.notifEyesBlue)
                        }

                        Text("\(detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened)) - \(detail.shift.endsAt.formatted(date: .omitted, time: .shortened))")
                            .font(.headline)
                        Text("\(formatUsd(detail.shift.rateCentsPerHour))/hr · \(detail.shift.lunchMinutes) min lunch")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                }

                Section("Pay") {
                    LabeledContent("Hours", value: String(format: "%.1f", detail.cost.hours))
                    LabeledContent("OD payout", value: formatUsd(detail.cost.odPayoutCents))
                    LabeledContent("Practice total", value: formatUsd(detail.cost.totalCents))
                }

                Section("Services") {
                    ForEach(detail.shift.servicesNeeded, id: \.self) { service in
                        Label(service, systemImage: "checkmark.circle")
                    }
                }

                if let notes = detail.shift.notesForOd, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                actionSection(detail)
            } else {
                ProgressView("Loading shift")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Shift detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DemoSwitcherMenu()
            }
        }
        .task(id: shiftId) {
            await load()
        }
    }

    @ViewBuilder
    private func actionSection(_ detail: ShiftDetail) -> some View {
        if sessionStore.role == .od {
            Section {
                if let application = detail.viewerApplication {
                    HStack {
                        Label("Application \(application.status.displayName.lowercased())", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.notifEyesGreen)
                        Spacer()
                        Text(application.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        Task { await apply() }
                    } label: {
                        Text(isApplying ? "Applying..." : "Apply")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(isApplying || detail.shift.status != .posted)
                }
            }
        } else if sessionStore.role == .practice {
            Section {
                NavigationLink(value: Route.applicants(shiftId)) {
                    Label("View applicants", systemImage: "person.crop.circle.badge.checkmark")
                }
            }
        }
    }

    private func load() async {
        do {
            detail = try await env.api.shift(id: shiftId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func apply() async {
        isApplying = true
        defer { isApplying = false }

        do {
            _ = try await env.api.apply(to: shiftId, message: nil, source: .apply)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func address(_ practice: Practice) -> String {
        [practice.addressLine, practice.city, practice.state].compactMap { $0 }.joined(separator: ", ")
    }
}
