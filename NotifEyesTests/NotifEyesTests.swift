import XCTest
@testable import NotifEyes

final class NotifEyesTests: XCTestCase {
    func testEnumRawValuesMatchContract() {
        XCTAssertEqual(ShiftType.fill_in.rawValue, "fill_in")
        XCTAssertEqual(ApplicationSource.watch_alert.rawValue, "watch_alert")
        XCTAssertEqual(BookingStatus.no_show.rawValue, "no_show")
        XCTAssertEqual(NotificationKind.watch_match.rawValue, "watch_match")
        XCTAssertEqual(UserRole.practice_owner.rawValue, "practice_owner")
    }

    func testGeometryMetaCircleCodableWireShape() throws {
        let geometry = GeometryMeta.circle(centerLat: 37.7749, centerLng: -122.4194, radiusMeters: 40_233.6)
        let data = try JSONEncoder().encode(geometry)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["kind"] as? String, "circle")
        XCTAssertEqual(object["centerLat"] as? Double, 37.7749)
        XCTAssertEqual(object["centerLng"] as? Double, -122.4194)
        XCTAssertEqual(object["radiusMeters"] as? Double, 40_233.6)

        let decoded = try JSONDecoder().decode(GeometryMeta.self, from: data)
        XCTAssertEqual(decoded, geometry)
    }

    func testGeometryMetaPolygonCodableWireShape() throws {
        let geometry = GeometryMeta.polygon(points: [
            LatLng(lat: 37.7, lng: -122.5),
            LatLng(lat: 37.6, lng: -122.3),
            LatLng(lat: 37.8, lng: -122.2)
        ])
        let data = try JSONEncoder().encode(geometry)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(object["kind"] as? String, "polygon")
        XCTAssertNotNil(object["points"] as? [[String: Any]])
        XCTAssertNil(object["centerLat"])

        let decoded = try JSONDecoder().decode(GeometryMeta.self, from: data)
        XCTAssertEqual(decoded, geometry)
    }

    func testMoneyFormattingAndCostPreview() {
        XCTAssertEqual(formatUsd(12_345), "$123.45")

        let startsAt = makeDate(2026, 6, 3, 9, 0)
        let endsAt = makeDate(2026, 6, 3, 17, 0)
        let confirmedAt = makeDate(2026, 6, 1, 9, 0)
        let cost = computeShiftCost(
            rateCentsPerHour: 10_000,
            startsAt: startsAt,
            endsAt: endsAt,
            lunchMinutes: 30,
            urgent: false,
            confirmedAt: confirmedAt
        )

        XCTAssertEqual(cost.hours, 7.5)
        XCTAssertEqual(cost.subtotalCents, 75_000)
        XCTAssertEqual(cost.feeCents, matchFeeCents)
        XCTAssertEqual(cost.totalCents, 75_999)
        XCTAssertEqual(cost.odPayoutCents, 75_000)
        XCTAssertFalse(cost.sameDay)
    }

    func testDefaultSeedSessionAndDemoSwitching() async throws {
        let api = MockAPI()

        let currentSession = try await api.currentSession()
        XCTAssertNil(currentSession)

        let bayview = try await api.switchDemoActor(to: .bayviewEyeCare)
        XCTAssertEqual(bayview.user.email, DemoActor.bayviewEyeCare.demoEmail)
        XCTAssertEqual(bayview.role, .practice)

        let yara = try await api.switchDemoActor(to: .yaraBrennan)
        XCTAssertEqual(yara.user.email, DemoActor.yaraBrennan.demoEmail)
        XCTAssertEqual(yara.role, .od)
    }

    func testMockSignatureLoopStateMutations() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .bayviewEyeCare)
        let shift = try await api.createShift(CreateShiftInput(
            startsAt: makeDate(2026, 6, 3, 9, 0),
            endsAt: makeDate(2026, 6, 3, 17, 0),
            lunchMinutes: 30,
            type: .fill_in,
            rateCentsPerHour: 12_000,
            bumpRateCentsPerHour: nil,
            bumpRadiusMeters: nil,
            servicesNeeded: ["Comprehensive exams"],
            notesForOd: "Loop test shift.",
            visibility: .public,
            urgent: true
        ))
        _ = try await api.updateShiftStatus(shift.id, to: .posted)

        let maya = try await api.switchDemoActor(to: .mayaPatel)
        let notifications = try await api.notifications(for: maya.user.id)
        XCTAssertTrue(notifications.contains { $0.kind == .watch_match && $0.payload["shiftId"] == shift.id.uuidString })

        let application = try await api.apply(to: shift.id, message: "I can cover this.", source: .watch_alert)
        _ = try await api.switchDemoActor(to: .bayviewEyeCare)
        let applicants = try await api.applicants(for: shift.id)
        XCTAssertTrue(applicants.contains { $0.id == application.id })
    }

    func testCreatePolygonWatchZonePersistsContractShape() async throws {
        let api = MockAPI()
        let maya = try await api.switchDemoActor(to: .mayaPatel)
        let odId = try XCTUnwrap(maya.user.odId)

        let zone = try await api.createWatchZone(CreateWatchZoneInput(
            name: "Test polygon",
            geometryMeta: .polygon(points: [
                LatLng(lat: 37.7, lng: -122.5),
                LatLng(lat: 37.6, lng: -122.3),
                LatLng(lat: 37.8, lng: -122.2)
            ]),
            daysOfWeek: [1, 2, 3],
            timeStart: nil,
            timeEnd: nil,
            minRateCents: 10_000,
            shiftTypes: [.fill_in],
            notifyChannels: [.email]
        ))

        let zones = try await api.watchZones(for: odId)
        XCTAssertTrue(zones.contains(zone))
        XCTAssertEqual(zone.shape, .polygon)
    }

    func testBookApplicantCreatesBookingAndClosesShift() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .yaraBrennan)
        let application = try await api.apply(to: SeedIDs.shiftBayviewPosted, message: "Available.", source: .apply)

        _ = try await api.switchDemoActor(to: .bayviewEyeCare)
        let booking = try await api.bookApplicant(application.id)
        let detail = try await api.shift(id: SeedIDs.shiftBayviewPosted)

        XCTAssertEqual(booking.applicationId, application.id)
        XCTAssertEqual(detail.shift.status, .booked)
        XCTAssertEqual(detail.shift.bookedApplicationId, application.id)
    }

    func testLiveAPIStubsThrowNotImplemented() async {
        do {
            _ = try await LiveAPI().currentSession()
            XCTFail("LiveAPI should be a stub in Phase 0.")
        } catch APIError.notImplemented {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }
}
