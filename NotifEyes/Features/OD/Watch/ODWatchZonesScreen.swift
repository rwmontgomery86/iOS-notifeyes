import SwiftUI

struct ODWatchZonesScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session
    var openEditor: (WatchZone.ID?) -> Void

    @State private var zones: [WatchZone] = []
    @State private var shifts: [ShiftSummary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                WatchZoneMap(zones: zones, shifts: shifts)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            Section {
                Button {
                    openEditor(nil)
                } label: {
                    Label("New watch zone", systemImage: "plus.circle.fill")
                }

                if let firstActiveZone = zones.first(where: { !$0.paused }) {
                    Button {
                        Task { await simulate(zone: firstActiveZone) }
                    } label: {
                        Label("Simulate a matching shift", systemImage: "bell.badge")
                    }
                }
            }

            Section("Your zones") {
                if zones.isEmpty && !isLoading {
                    EmptyStateView(title: "No watch zones yet", message: "Create a zone to get matched when shifts post inside it.", systemImage: "scope")
                }

                ForEach(zones) { zone in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(zone.name)
                                    .font(.headline)
                                Text(zoneSubtitle(zone))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            StatusBadge(text: zone.paused ? "Paused" : "Active", color: zone.paused ? Color.secondary : Color.notifEyesGreen)
                        }

                        HStack {
                            Button("Edit") {
                                openEditor(zone.id)
                            }
                            .buttonStyle(.bordered)

                            Button(zone.paused ? "Resume" : "Pause") {
                                Task { await setPaused(zone, paused: !zone.paused) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { offsets in
                    Task { await delete(offsets: offsets) }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
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
        guard let odId = session.user.odId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let od = try await env.api.optometrist(id: odId)
            zones = try await env.api.watchZones(for: odId)
            shifts = try await env.api.browseShifts(filter: ShiftFilter(near: od.homeLocation, radiusMi: od.travelRadiusMi))
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func setPaused(_ zone: WatchZone, paused: Bool) async {
        do {
            _ = try await env.api.setWatchZonePaused(zone.id, paused: paused)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func delete(offsets: IndexSet) async {
        do {
            for index in offsets {
                try await env.api.deleteWatchZone(zones[index].id)
            }
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func simulate(zone: WatchZone) async {
        do {
            _ = try await env.api.simulateMatchingShift(for: zone.id)
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func zoneSubtitle(_ zone: WatchZone) -> String {
        let rate = "\(formatUsd(zone.minRateCents))/hr"
        let types = zone.shiftTypes.map(\.displayName).joined(separator: ", ")
        switch zone.geometryMeta {
        case let .circle(_, _, radiusMeters):
            return "\(Int(radiusMeters / 1_609.344)) mi circle · \(rate) · \(types)"
        case let .polygon(points):
            return "\(points.count)-point polygon · \(rate) · \(types)"
        }
    }
}
