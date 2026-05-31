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
        let bookingDetail = try await api.booking(id: booking.id)
        let yaraNotifications = try await api.notifications(for: SeedIDs.yaraUser)

        XCTAssertEqual(booking.applicationId, application.id)
        XCTAssertEqual(detail.shift.status, .booked)
        XCTAssertEqual(detail.shift.bookedApplicationId, application.id)
        XCTAssertNotNil(bookingDetail.contract)
        XCTAssertNotNil(bookingDetail.thread)
        XCTAssertTrue(yaraNotifications.contains {
            $0.kind == .booking_confirmed && $0.payload["bookingId"] == booking.id.uuidString
        })
    }

    func testPracticeCanMoveApplicantThroughReviewStates() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .yaraBrennan)
        let application = try await api.apply(to: SeedIDs.shiftBayviewPosted, message: "Available.", source: .apply)

        _ = try await api.switchDemoActor(to: .bayviewEyeCare)
        let shortlisted = try await api.updateApplicationStatus(application.id, to: .shortlisted)
        let offered = try await api.updateApplicationStatus(application.id, to: .offered)

        XCTAssertEqual(shortlisted.status, .shortlisted)
        XCTAssertEqual(offered.status, .offered)
    }

    func testBookingDetailLifecycleActionsMutateState() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .mayaPatel)
        let signedContract = try await api.signContract(booking: SeedIDs.bookingMaya, as: .od)
        XCTAssertNotNil(signedContract.signedByOdAt)

        let checkedIn = try await api.checkIn(booking: SeedIDs.bookingMaya)
        XCTAssertEqual(checkedIn.status, .in_progress)
        XCTAssertNotNil(checkedIn.checkInAt)

        let checkedOut = try await api.checkOut(booking: SeedIDs.bookingMaya)
        XCTAssertEqual(checkedOut.status, .completed)
        XCTAssertNotNil(checkedOut.checkOutAt)

        let detail = try await api.booking(id: SeedIDs.bookingMaya)
        XCTAssertEqual(detail.booking.status, .completed)
    }

    func testCancelBookingClosesShiftAndNotifiesParticipants() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .bayviewEyeCare)
        let booking = try await api.bookApplicant(SeedIDs.appYaraBayview)
        let cancelled = try await api.cancelBooking(booking.id, reason: "Practice schedule changed.")
        let shiftDetail = try await api.shift(id: SeedIDs.shiftBayviewPosted)
        let yaraNotifications = try await api.notifications(for: SeedIDs.yaraUser)

        XCTAssertEqual(cancelled.status, .cancelled)
        XCTAssertEqual(cancelled.paymentStatus, "cancelled")
        XCTAssertEqual(cancelled.cancellationReason, "Practice schedule changed.")
        XCTAssertEqual(shiftDetail.shift.status, .cancelled)
        XCTAssertTrue(yaraNotifications.contains {
            $0.kind == .cancellation && $0.payload["bookingId"] == booking.id.uuidString
        })
    }

    func testSendingMessageAppendsAndNotifiesOtherParticipant() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .bayviewEyeCare)
        let message = try await api.sendMessage(thread: SeedIDs.threadBooking, body: "  See you Wednesday morning.  ")

        _ = try await api.switchDemoActor(to: .mayaPatel)
        let messages = try await api.messages(in: SeedIDs.threadBooking)
        let notifications = try await api.notifications(for: SeedIDs.mayaUser)
        let threadsBeforeRead = try await api.threads(for: SeedIDs.mayaUser)

        XCTAssertEqual(message.body, "See you Wednesday morning.")
        XCTAssertTrue(messages.contains(message))
        XCTAssertTrue(notifications.contains {
            $0.kind == .message_received && $0.payload["threadId"] == SeedIDs.threadBooking.uuidString
        })
        XCTAssertTrue(threadsBeforeRead.first { $0.id == SeedIDs.threadBooking }?.unreadCount ?? 0 > 0)

        try await api.markThreadRead(SeedIDs.threadBooking, by: SeedIDs.mayaUser)
        let threadsAfterRead = try await api.threads(for: SeedIDs.mayaUser)
        XCTAssertEqual(threadsAfterRead.first { $0.id == SeedIDs.threadBooking }?.unreadCount, 0)
    }

    func testSubmitReviewRequiresCompletedBookingAndPersistsByRole() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .mayaPatel)
        let review = try await api.submitReview(SubmitReviewInput(
            bookingId: SeedIDs.bookingCompleted,
            authorRole: .od,
            ratingOverall: 5,
            ratingSpecifics: ["communication": 5, "professionalism": 5],
            publicComment: "Great support team and a smooth day.",
            privateFeedback: nil
        ))

        let loaded = try await api.review(forBooking: SeedIDs.bookingCompleted, role: .od)
        XCTAssertEqual(loaded, review)
        XCTAssertEqual(loaded?.publicComment, "Great support team and a smooth day.")
    }

    func testSubmitReviewRejectsIncompleteBooking() async throws {
        let api = MockAPI()

        _ = try await api.switchDemoActor(to: .mayaPatel)

        do {
            _ = try await api.submitReview(SubmitReviewInput(
                bookingId: SeedIDs.bookingMaya,
                authorRole: .od,
                ratingOverall: 5,
                ratingSpecifics: [:],
                publicComment: nil,
                privateFeedback: nil
            ))
            XCTFail("Review should require a completed booking.")
        } catch APIError.invalid {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
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
