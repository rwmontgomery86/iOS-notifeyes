import MapKit
import SwiftUI

struct WatchZoneEditorScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    var zoneId: WatchZone.ID?
    var session: Session

    @State private var controller = ZoneDrawController()
    @State private var mapPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7)
    ))
    @State private var searchText = ""
    @State private var hasLoaded = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Picker("Shape", selection: $controller.shape) {
                    ForEach(ZoneDrawController.DrawShape.allCases) { shape in
                        Text(shape.rawValue.capitalized).tag(shape)
                    }
                }
                .pickerStyle(.segmented)

                zoneMap
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    TextField("City or ZIP", text: $searchText)
                        .textInputAutocapitalization(.words)
                    Button("Search") {
                        applySearch()
                    }
                }

                if controller.shape == .circle {
                    VStack(alignment: .leading) {
                        Text("Radius \(Int(controller.radiusMiles)) mi")
                        Slider(value: $controller.radiusMiles, in: 1...100, step: 1)
                    }
                } else {
                    HStack {
                        Text("\(controller.polygonPoints.count) points")
                        Spacer()
                        Button("Undo") {
                            controller.removeLastPolygonPoint()
                        }
                        .disabled(controller.polygonPoints.isEmpty)
                        Button("Clear") {
                            controller.clearPolygon()
                        }
                        .disabled(controller.polygonPoints.isEmpty)
                    }
                }
            } header: {
                Text("Map")
            } footer: {
                Text(controller.shape == .circle ? "Tap the map or search to move the center." : "Tap the map to add polygon points. Save requires at least three points.")
            }

            Section("Preferences") {
                TextField("Zone name", text: $controller.name)

                Stepper("Minimum rate \(formatUsd(controller.minRateCents))/hr", value: $controller.minRateCents, in: 8_000...20_000, step: 500)

                DaysOfWeekPicker(selectedDays: $controller.daysOfWeek)

                TextField("Earliest start, HH:MM", text: Binding(
                    get: { controller.timeStart ?? "" },
                    set: { controller.timeStart = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.numbersAndPunctuation)

                TextField("Latest start, HH:MM", text: Binding(
                    get: { controller.timeEnd ?? "" },
                    set: { controller.timeEnd = $0.isEmpty ? nil : $0 }
                ))
                .keyboardType(.numbersAndPunctuation)
            }

            Section("Shift types") {
                ForEach([ShiftType.fill_in, .half_day, .weekend], id: \.self) { type in
                    Toggle(type.displayName, isOn: binding(for: type))
                }
            }

            Section("Notifications") {
                ForEach([Channel.push, .email, .sms], id: \.self) { channel in
                    Toggle(channel.displayName, isOn: channelBinding(for: channel))
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(zoneId == nil ? "New zone" : "Edit zone")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? "Saving..." : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || !controller.canSave)
            }
            ToolbarItem(placement: .topBarTrailing) {
                DemoSwitcherMenu()
            }
        }
        .task(id: zoneId) {
            guard !hasLoaded else { return }
            hasLoaded = true
            await loadExistingZone()
        }
    }

    private var zoneMap: some View {
        MapReader { proxy in
            Map(position: $mapPosition) {
                switch controller.geometryMeta {
                case let .circle(centerLat, centerLng, radiusMeters):
                    MapCircle(center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng), radius: radiusMeters)
                        .foregroundStyle(Color.notifEyesBlue.opacity(0.18))
                        .stroke(Color.notifEyesBlue, lineWidth: 2)
                    Annotation("Center", coordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)) {
                        Image(systemName: "smallcircle.filled.circle")
                            .font(.title2)
                            .foregroundStyle(Color.notifEyesBlue)
                    }
                case let .polygon(points):
                    if points.count >= 3 {
                        MapPolygon(coordinates: points.map(\.coordinate))
                            .foregroundStyle(Color.notifEyesGreen.opacity(0.18))
                            .stroke(Color.notifEyesGreen, lineWidth: 2)
                    }
                    ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                        Annotation("\(index + 1)", coordinate: point.coordinate) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(Color.notifEyesGreen)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .gesture(
                SpatialTapGesture().onEnded { value in
                    if let coordinate = proxy.convert(value.location, from: .local) {
                        controller.addMapPoint(LatLng(lat: coordinate.latitude, lng: coordinate.longitude))
                    }
                }
            )
        }
    }

    private func loadExistingZone() async {
        guard let zoneId, let odId = session.user.odId else { return }
        do {
            let zones = try await env.api.watchZones(for: odId)
            if let zone = zones.first(where: { $0.id == zoneId }) {
                controller.load(zone: zone)
                mapPosition = .region(zone.geometryMeta.region)
            }
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            if let zoneId {
                _ = try await env.api.updateWatchZone(zoneId, controller.makeUpdateInput())
            } else {
                _ = try await env.api.createWatchZone(controller.makeInput())
            }
            dismiss()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func applySearch() {
        guard let coordinate = BayAreaLookup.coordinate(for: searchText) else {
            errorMessage = "Try San Francisco, Oakland, Campbell, Palo Alto, Marin, or a seeded ZIP."
            return
        }
        controller.center = coordinate
        mapPosition = .region(MKCoordinateRegion(
            center: coordinate.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.55, longitudeDelta: 0.55)
        ))
        if controller.shape == .polygon {
            controller.polygonPoints.append(coordinate)
        }
        errorMessage = nil
    }

    private func binding(for type: ShiftType) -> Binding<Bool> {
        Binding {
            controller.shiftTypes.contains(type)
        } set: { isSelected in
            if isSelected {
                if !controller.shiftTypes.contains(type) {
                    controller.shiftTypes.append(type)
                }
            } else {
                controller.shiftTypes.removeAll { $0 == type }
            }
        }
    }

    private func channelBinding(for channel: Channel) -> Binding<Bool> {
        Binding {
            controller.notifyChannels.contains(channel)
        } set: { isSelected in
            if isSelected {
                if !controller.notifyChannels.contains(channel) {
                    controller.notifyChannels.append(channel)
                }
            } else {
                controller.notifyChannels.removeAll { $0 == channel }
            }
        }
    }
}

private struct DaysOfWeekPicker: View {
    @Binding var selectedDays: [Int]

    private let days = [(1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S"), (0, "S")]

    var body: some View {
        HStack {
            ForEach(days, id: \.0) { day, label in
                FilterChip(title: label, isSelected: selectedDays.contains(day)) {
                    if selectedDays.contains(day) {
                        selectedDays.removeAll { $0 == day }
                    } else {
                        selectedDays.append(day)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private enum BayAreaLookup {
    private static let table: [String: LatLng] = [
        "san francisco": LatLng(lat: 37.7749, lng: -122.4194),
        "sf": LatLng(lat: 37.7749, lng: -122.4194),
        "94115": LatLng(lat: 37.7849, lng: -122.4444),
        "oakland": LatLng(lat: 37.8044, lng: -122.2712),
        "94612": LatLng(lat: 37.8268, lng: -122.2632),
        "campbell": LatLng(lat: 37.2872, lng: -121.9499),
        "95008": LatLng(lat: 37.2872, lng: -121.9499),
        "palo alto": LatLng(lat: 37.4419, lng: -122.1430),
        "94301": LatLng(lat: 37.4419, lng: -122.1430),
        "marin": LatLng(lat: 37.9735, lng: -122.5311),
        "san rafael": LatLng(lat: 37.9735, lng: -122.5311)
    ]

    static func coordinate(for text: String) -> LatLng? {
        table[text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }
}
