import SwiftUI

enum ODBrowseMode: String, CaseIterable, Identifiable {
    case matching = "Matching"
    case nearby = "Nearby"
    case all = "All CA"

    var id: String { rawValue }
}

enum ShiftDateFilter: String, CaseIterable, Identifiable {
    case any = "Any"
    case week = "7 days"
    case weekend = "Weekend"

    var id: String { rawValue }
}

struct ODBrowseShiftsScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session
    var openShift: (Shift.ID) -> Void

    @State private var od: Optometrist?
    @State private var zones: [WatchZone] = []
    @State private var shifts: [ShiftSummary] = []
    @State private var browseMode: ODBrowseMode = .matching
    @State private var dateFilter: ShiftDateFilter = .any
    @State private var showMap = false
    @State private var distanceMi = 35.0
    @State private var minRateCents: Cents = 10_000
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            filters

            if showMap {
                WatchZoneMap(zones: zones, shifts: displayedShifts, onShiftTap: openShift)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if displayedShifts.isEmpty && !isLoading {
                        EmptyStateView(title: "No shifts match", message: "Try widening distance or lowering the rate filter.", systemImage: "calendar.badge.exclamationmark")
                    }

                    ForEach(displayedShifts) { shift in
                        Button {
                            openShift(shift.id)
                        } label: {
                            ShiftCard(shift: shift)
                        }
                        .buttonStyle(.plain)
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
            }
        }
        .task(id: session.user.id) {
            await load()
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Browse mode", selection: $browseMode) {
                ForEach(ODBrowseMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Picker("Date", selection: $dateFilter) {
                    ForEach(ShiftDateFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Toggle(isOn: $showMap) {
                    Label("Map", systemImage: "map")
                }
                .toggleStyle(.button)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Distance \(Int(distanceMi)) mi")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Slider(value: $distanceMi, in: 5...100, step: 5)
            }

            Stepper("Minimum rate \(formatUsd(minRateCents))/hr", value: $minRateCents, in: 8_000...18_000, step: 500)
                .font(.subheadline.weight(.medium))
        }
        .padding(12)
        .background(Color.notifEyesCanvas)
    }

    private var displayedShifts: [ShiftSummary] {
        let filtered = shifts.filter { shift in
            guard shift.rateCentsPerHour >= minRateCents else { return false }
            switch dateFilter {
            case .any:
                break
            case .week:
                guard shift.startsAt.isWithinNext(days: 7) else { return false }
            case .weekend:
                guard shift.startsAt.isNotifEyesWeekend else { return false }
            }

            switch browseMode {
            case .matching:
                return zones.contains { zoneMatches($0, shift: shift) }
            case .nearby:
                return (shift.distanceMi ?? .greatestFiniteMagnitude) <= distanceMi
            case .all:
                return true
            }
        }

        return filtered.sorted { lhs, rhs in
            switch browseMode {
            case .matching:
                return lhs.startsAt < rhs.startsAt
            case .nearby:
                return (lhs.distanceMi ?? 999) < (rhs.distanceMi ?? 999)
            case .all:
                return lhs.startsAt < rhs.startsAt
            }
        }
    }

    private func load() async {
        guard let odId = session.user.odId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loadedOD = try await env.api.optometrist(id: odId)
            od = loadedOD
            if distanceMi == 35 {
                distanceMi = loadedOD.travelRadiusMi
            }
            zones = try await env.api.watchZones(for: odId)
            if let firstZone = zones.first(where: { !$0.paused }) {
                minRateCents = firstZone.minRateCents
            }
            shifts = try await env.api.browseShifts(filter: ShiftFilter(
                minRateCents: nil,
                types: [],
                near: loadedOD.homeLocation,
                radiusMi: nil
            ))
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func zoneMatches(_ zone: WatchZone, shift: ShiftSummary) -> Bool {
        guard !zone.paused else { return false }
        guard zone.shiftTypes.contains(shift.type) else { return false }
        guard shift.rateCentsPerHour >= zone.minRateCents else { return false }
        guard zone.daysOfWeek.contains(shift.startsAt.notifEyesDayOfWeek) else { return false }
        guard let location = shift.location else { return false }

        switch zone.geometryMeta {
        case let .circle(centerLat, centerLng, radiusMeters):
            return GeoCalculations.distanceMeters(LatLng(lat: centerLat, lng: centerLng), location) <= radiusMeters
        case let .polygon(points):
            return GeoCalculations.polygon(points, contains: location)
        }
    }
}
