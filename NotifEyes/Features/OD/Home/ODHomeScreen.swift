import SwiftUI

struct ODHomeScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session
    var openShift: (Shift.ID) -> Void
    var openWatch: () -> Void

    @State private var od: Optometrist?
    @State private var zones: [WatchZone] = []
    @State private var nearbyShifts: [ShiftSummary] = []
    @State private var latestWatchMatch: AppNotification?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let latestWatchMatch {
                    Button {
                        if let route = latestWatchMatch.actionUrl.flatMap(DeepLink.parse),
                           case let .shiftDetail(id) = route {
                            openShift(id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "scope")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(Color.notifEyesBlue)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Watch match ready")
                                    .font(.headline)
                                    .foregroundStyle(Color.notifEyesInk)
                                Text(latestWatchMatch.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundStyle(Color.notifEyesBlue)
                        }
                        .padding(16)
                        .background(Color.notifEyesPanel)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.notifEyesLine, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    MetricTile(title: "Watch zones", value: "\(zones.filter { !$0.paused }.count)", footnote: "active")
                    MetricTile(title: "Nearby shifts", value: "\(nearbyShifts.count)", footnote: "open")
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Nearby shifts")
                            .font(.headline)
                        Spacer()
                        Button("View all", action: openWatch)
                            .font(.subheadline.weight(.semibold))
                    }

                    if nearbyShifts.isEmpty && !isLoading {
                        EmptyStateView(title: "No nearby shifts yet", message: "Try widening your distance filter or create a watch zone.")
                    } else {
                        ForEach(nearbyShifts.prefix(3)) { shift in
                            Button {
                                openShift(shift.id)
                            } label: {
                                ShiftCard(shift: shift)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome, \(od?.displayName ?? session.user.name ?? "doctor")")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.notifEyesInk)
            Text("Watch-match alerts and nearby coverage days surface here first.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func load() async {
        guard let odId = session.user.odId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedOD = try await env.api.optometrist(id: odId)
            od = loadedOD
            zones = try await env.api.watchZones(for: odId)
            latestWatchMatch = try await env.api.notifications(for: session.user.id)
                .first { $0.kind == .watch_match && $0.readAt == nil }
            nearbyShifts = try await env.api.browseShifts(filter: ShiftFilter(
                minRateCents: zones.first(where: { !$0.paused })?.minRateCents,
                types: [],
                near: loadedOD.homeLocation,
                radiusMi: loadedOD.travelRadiusMi
            ))
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}
