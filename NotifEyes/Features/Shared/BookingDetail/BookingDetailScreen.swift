import SwiftUI

struct BookingDetailScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var bookingId: Booking.ID

    @State private var detail: BookingDetail?
    @State private var isLoading = false
    @State private var isSigning = false
    @State private var isCheckingIn = false
    @State private var isCheckingOut = false
    @State private var isCancelling = false
    @State private var cancelReason = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let detail {
                headerSection(detail)
                peopleSection(detail)
                coverageSection(detail)
                moneySection(detail)
                contractSection(detail)
                shiftDaySection(detail)
                conversationSection(detail)
                cancellationSection(detail)
            } else if isLoading {
                ProgressView("Loading booking")
            } else {
                ProgressView("Loading booking")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Booking")
        .refreshable {
            await load()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DemoSwitcherMenu()
            }
        }
        .task {
            await load()
        }
    }

    private func headerSection(_ detail: BookingDetail) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.practice.name)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.notifEyesInk)
                        Text(detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(text: detail.booking.status.displayName, color: statusColor(for: detail.booking.status))
                }

                HStack(spacing: 10) {
                    Label(detail.shift.type.displayName, systemImage: "calendar")
                    Label(formatUsd(odPayoutCents(detail)), systemImage: "banknote")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.notifEyesMuted)
            }
            .padding(.vertical, 4)
        }
    }

    private func peopleSection(_ detail: BookingDetail) -> some View {
        Section("People") {
            NavigationLink(value: Route.practiceProfile(detail.practice.id)) {
                BookingPartyRow(
                    title: detail.practice.name,
                    subtitle: address(detail.practice),
                    badge: detail.practice.paymentMethodVerified ? "Payment verified" : "Payment pending"
                )
            }

            NavigationLink(value: Route.odProfile(detail.optometrist.id)) {
                BookingPartyRow(
                    title: detail.optometrist.displayName ?? detail.optometrist.name,
                    subtitle: [
                        detail.optometrist.licenseState.map { "\($0) license" },
                        "\(detail.optometrist.shiftsCompleted) shifts"
                    ].compactMap { $0 }.joined(separator: " · "),
                    badge: detail.optometrist.verificationStatus.displayName
                )
            }
        }
    }

    private func coverageSection(_ detail: BookingDetail) -> some View {
        Section("Coverage") {
            LabeledContent("Starts", value: detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Ends", value: detail.shift.endsAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Lunch", value: "\(detail.shift.lunchMinutes) min")
            if !detail.shift.servicesNeeded.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Services")
                        .font(.subheadline.weight(.semibold))
                    ForEach(detail.shift.servicesNeeded, id: \.self) { service in
                        Label(service, systemImage: "checkmark.circle")
                    }
                    .font(.subheadline)
                }
            }
            if let notes = detail.shift.notesForOd, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Practice notes")
                        .font(.subheadline.weight(.semibold))
                    Text(notes)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func moneySection(_ detail: BookingDetail) -> some View {
        Section("Money") {
            LabeledContent("OD payout", value: formatUsd(odPayoutCents(detail)))
            LabeledContent("Platform fee", value: formatUsd(detail.booking.platformFeeCents))
            LabeledContent("Practice total", value: formatUsd(detail.booking.totalCents))
            LabeledContent("Payment", value: detail.booking.paymentStatus.capitalized)
        }
    }

    private func contractSection(_ detail: BookingDetail) -> some View {
        Section("Contract") {
            if let contract = detail.contract {
                ContractSignatureRow(title: "Practice", signedAt: contract.signedByPracticeAt)
                ContractSignatureRow(title: "OD", signedAt: contract.signedByOdAt)

                Text(contract.bodyText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await signContract() }
                } label: {
                    Label(signButtonTitle(contract), systemImage: signedForCurrentRole(contract) ? "checkmark.seal.fill" : "signature")
                }
                .disabled(isSigning || signedForCurrentRole(contract) || detail.booking.status == .cancelled)
            } else {
                Text("Contract will appear once the booking is confirmed.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func shiftDaySection(_ detail: BookingDetail) -> some View {
        Section("Day of shift") {
            BookingEventRow(title: "Check in", date: detail.booking.checkInAt, fallback: "Not checked in")
            BookingEventRow(title: "Check out", date: detail.booking.checkOutAt, fallback: "Not checked out")

            Button {
                Task { await checkIn() }
            } label: {
                Label(isCheckingIn ? "Checking in..." : "Check in", systemImage: "location.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isCheckingIn || detail.booking.status != .confirmed)

            Button {
                Task { await checkOut() }
            } label: {
                Label(isCheckingOut ? "Checking out..." : "Check out", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle(isProminent: false))
            .disabled(isCheckingOut || detail.booking.status != .in_progress)
        }
    }

    @ViewBuilder
    private func conversationSection(_ detail: BookingDetail) -> some View {
        if let thread = detail.thread {
            Section("Conversation") {
                NavigationLink(value: Route.messageThread(thread.id)) {
                    Label("Open booking thread", systemImage: "message")
                }
            }
        }
    }

    private func cancellationSection(_ detail: BookingDetail) -> some View {
        Section("Cancellation") {
            if detail.booking.status == .cancelled {
                LabeledContent("Reason", value: detail.booking.cancellationReason ?? "No reason provided")
                if let fee = detail.booking.cancellationFeeCents {
                    LabeledContent("Fee", value: formatUsd(fee))
                }
            } else if detail.booking.status == .completed {
                Text("Completed bookings cannot be cancelled.")
                    .foregroundStyle(.secondary)
            } else {
                TextField("Reason", text: $cancelReason, axis: .vertical)
                    .lineLimit(2...4)

                Button(role: .destructive) {
                    Task { await cancelBooking() }
                } label: {
                    Label(isCancelling ? "Cancelling..." : "Cancel booking", systemImage: "xmark.circle")
                }
                .disabled(isCancelling || trimmedCancelReason.isEmpty)
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            detail = try await env.api.booking(id: bookingId)
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func signContract() async {
        guard let role = sessionStore.role else { return }
        isSigning = true
        defer { isSigning = false }
        do {
            _ = try await env.api.signContract(booking: bookingId, as: role)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func checkIn() async {
        isCheckingIn = true
        defer { isCheckingIn = false }
        do {
            _ = try await env.api.checkIn(booking: bookingId)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func checkOut() async {
        isCheckingOut = true
        defer { isCheckingOut = false }
        do {
            _ = try await env.api.checkOut(booking: bookingId)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func cancelBooking() async {
        isCancelling = true
        defer { isCancelling = false }
        do {
            _ = try await env.api.cancelBooking(bookingId, reason: trimmedCancelReason)
            cancelReason = ""
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private var trimmedCancelReason: String {
        cancelReason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func signButtonTitle(_ contract: Contract) -> String {
        if signedForCurrentRole(contract) {
            return "Signed as \(currentSignerName)"
        }
        return isSigning ? "Signing..." : "Sign as \(currentSignerName)"
    }

    private func signedForCurrentRole(_ contract: Contract) -> Bool {
        switch sessionStore.role {
        case .od:
            return contract.signedByOdAt != nil
        case .practice:
            return contract.signedByPracticeAt != nil
        case nil:
            return false
        }
    }

    private var currentSignerName: String {
        switch sessionStore.role {
        case .od:
            return "OD"
        case .practice:
            return "practice"
        case nil:
            return "user"
        }
    }

    private func odPayoutCents(_ detail: BookingDetail) -> Cents {
        detail.booking.totalCents - detail.booking.platformFeeCents
    }

    private func address(_ practice: Practice) -> String {
        [practice.addressLine, practice.city, practice.state, practice.zip]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    private func statusColor(for status: BookingStatus) -> Color {
        switch status {
        case .confirmed:
            return Color.notifEyesGreen
        case .in_progress:
            return Color.notifEyesBlue
        case .completed:
            return Color.secondary
        case .cancelled, .no_show:
            return Color.red
        }
    }
}

private struct BookingPartyRow: View {
    var title: String
    var subtitle: String
    var badge: String

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: title)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            StatusBadge(text: badge, color: Color.notifEyesBlue)
        }
        .padding(.vertical, 4)
    }
}

private struct ContractSignatureRow: View {
    var title: String
    var signedAt: Date?

    var body: some View {
        LabeledContent(title) {
            if let signedAt {
                Label(signedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Color.notifEyesGreen)
            } else {
                Label("Waiting", systemImage: "clock")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct BookingEventRow: View {
    var title: String
    var date: Date?
    var fallback: String

    var body: some View {
        LabeledContent(title) {
            Text(date?.formatted(date: .abbreviated, time: .shortened) ?? fallback)
                .foregroundStyle(date == nil ? .secondary : Color.notifEyesInk)
        }
    }
}
