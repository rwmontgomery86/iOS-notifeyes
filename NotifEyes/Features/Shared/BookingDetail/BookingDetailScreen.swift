import SwiftUI

struct BookingDetailScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var bookingId: Booking.ID

    @State private var detail: BookingDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let detail {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail.practice.name)
                            .font(.title3.weight(.bold))
                        Text(detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                            .foregroundStyle(.secondary)
                        StatusBadge(text: detail.booking.status.rawValue.replacingOccurrences(of: "_", with: " "), color: .blue)
                    }
                    .padding(.vertical, 4)
                }

                Section("Contract") {
                    LabeledContent("Practice signed") {
                        Text(detail.contract?.signedByPracticeAt == nil ? "No" : "Yes")
                    }
                    LabeledContent("OD signed") {
                        Text(detail.contract?.signedByOdAt == nil ? "No" : "Yes")
                    }
                    Button("Sign contract") {
                        Task { await signContract() }
                    }
                    .disabled(detail.contract == nil)
                }

                Section("Day of shift") {
                    Button("Check in") {
                        Task { await checkIn() }
                    }
                    .disabled(detail.booking.status != .confirmed)

                    Button("Check out") {
                        Task { await checkOut() }
                    }
                    .disabled(detail.booking.status != .in_progress)
                }
            } else if isLoading {
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DemoSwitcherMenu()
            }
        }
        .task {
            await load()
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
        do {
            _ = try await env.api.signContract(booking: bookingId, as: role)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func checkIn() async {
        do {
            _ = try await env.api.checkIn(booking: bookingId)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func checkOut() async {
        do {
            _ = try await env.api.checkOut(booking: bookingId)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}
