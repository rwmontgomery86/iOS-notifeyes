import SwiftUI

struct PostShiftScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session
    var onPosted: (Shift.ID) -> Void

    @State private var step = 0
    @State private var date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var lunchMinutes = 30
    @State private var rateCents: Cents = 12_000
    @State private var shiftType: ShiftType = .fill_in
    @State private var services = "Comprehensive exams, Contacts"
    @State private var notes = "Tech performs pretesting. EHR is Eyefinity."
    @State private var urgent = true
    @State private var practice: Practice?
    @State private var isPosting = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Picker("Step", selection: $step) {
                    Text("Time").tag(0)
                    Text("Details").tag(1)
                    Text("Preview").tag(2)
                }
                .pickerStyle(.segmented)
            }

            if step == 0 {
                timeStep
            } else if step == 1 {
                detailsStep
            } else {
                previewStep
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .task(id: session.user.id) {
            await loadPractice()
        }
    }

    private var timeStep: some View {
        Section("Date, hours, location") {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
            Picker("Lunch duration", selection: $lunchMinutes) {
                Text("None").tag(0)
                Text("30 min").tag(30)
                Text("60 min").tag(60)
            }
            LabeledContent("Location", value: practice.map(address) ?? "Practice address")
            Button("Next") {
                step = 1
            }
        }
    }

    private var detailsStep: some View {
        Section("Rate and services") {
            Picker("Shift type", selection: $shiftType) {
                ForEach([ShiftType.fill_in, .half_day, .weekend], id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            Stepper("Hourly rate \(formatUsd(rateCents))", value: $rateCents, in: 8_000...20_000, step: 500)
            TextField("Services", text: $services)
            TextEditor(text: $notes)
                .frame(minHeight: 96)
            Toggle("Urgent / same-day fee preview", isOn: $urgent)
            Button("Next") {
                step = 2
            }
        }
    }

    private var previewStep: some View {
        Section("Cost preview") {
            LabeledContent("Hours", value: String(format: "%.1f", cost.hours))
            LabeledContent("OD payout", value: formatUsd(cost.odPayoutCents))
            LabeledContent("Platform fee", value: formatUsd(cost.feeCents))
            LabeledContent("Practice total", value: formatUsd(cost.totalCents))

            Button(isPosting ? "Posting..." : "Post shift") {
                Task { await postShift() }
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isPosting)
        }
    }

    private var startsAt: Date {
        combined(date: date, time: startTime)
    }

    private var endsAt: Date {
        combined(date: date, time: endTime)
    }

    private var cost: ShiftCost {
        computeShiftCost(
            rateCentsPerHour: rateCents,
            startsAt: startsAt,
            endsAt: endsAt,
            lunchMinutes: lunchMinutes,
            urgent: urgent
        )
    }

    private func loadPractice() async {
        guard let practiceId = session.user.practiceId else { return }
        do {
            practice = try await env.api.practice(id: practiceId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func postShift() async {
        isPosting = true
        defer { isPosting = false }
        do {
            let shift = try await env.api.createShift(CreateShiftInput(
                startsAt: startsAt,
                endsAt: endsAt,
                lunchMinutes: lunchMinutes,
                type: shiftType,
                rateCentsPerHour: rateCents,
                bumpRateCentsPerHour: nil,
                bumpRadiusMeters: nil,
                servicesNeeded: services.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                notesForOd: notes,
                visibility: .public,
                urgent: urgent
            ))
            let posted = try await env.api.updateShiftStatus(shift.id, to: .posted)
            onPosted(posted.id)
            reset()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func reset() {
        step = 0
        date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        rateCents = 12_000
        urgent = true
    }

    private func combined(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateParts = calendar.dateComponents([.year, .month, .day], from: date)
        let timeParts = calendar.dateComponents([.hour, .minute], from: time)
        var components = DateComponents()
        components.year = dateParts.year
        components.month = dateParts.month
        components.day = dateParts.day
        components.hour = timeParts.hour
        components.minute = timeParts.minute
        return calendar.date(from: components) ?? date
    }

    private func address(_ practice: Practice) -> String {
        [practice.addressLine, practice.city, practice.state].compactMap { $0 }.joined(separator: ", ")
    }
}
