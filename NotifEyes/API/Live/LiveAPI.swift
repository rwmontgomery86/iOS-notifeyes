import Foundation

struct LiveAPI: NotifEyesAPI {
    func signIn(email: String, password: String) async throws -> Session {
        throw APIError.notImplemented
    }

    func currentSession() async throws -> Session? {
        throw APIError.notImplemented
    }

    func signOut() async throws {
        throw APIError.notImplemented
    }

    func switchDemoActor(to actor: DemoActor) async throws -> Session {
        throw APIError.notImplemented
    }

    func browseShifts(filter: ShiftFilter) async throws -> [ShiftSummary] {
        throw APIError.notImplemented
    }

    func shift(id: Shift.ID) async throws -> ShiftDetail {
        throw APIError.notImplemented
    }

    func shiftsForPractice(_ id: Practice.ID, status: ShiftStatus?) async throws -> [ShiftSummary] {
        throw APIError.notImplemented
    }

    func createShift(_ input: CreateShiftInput) async throws -> Shift {
        throw APIError.notImplemented
    }

    func updateShiftStatus(_ id: Shift.ID, to status: ShiftStatus) async throws -> Shift {
        throw APIError.notImplemented
    }

    func applicants(for id: Shift.ID) async throws -> [ApplicantSummary] {
        throw APIError.notImplemented
    }

    func watchZones(for od: Optometrist.ID) async throws -> [WatchZone] {
        throw APIError.notImplemented
    }

    func createWatchZone(_ input: CreateWatchZoneInput) async throws -> WatchZone {
        throw APIError.notImplemented
    }

    func updateWatchZone(_ id: WatchZone.ID, _ input: UpdateWatchZoneInput) async throws -> WatchZone {
        throw APIError.notImplemented
    }

    func setWatchZonePaused(_ id: WatchZone.ID, paused: Bool) async throws -> WatchZone {
        throw APIError.notImplemented
    }

    func deleteWatchZone(_ id: WatchZone.ID) async throws {
        throw APIError.notImplemented
    }

    func simulateMatchingShift(for zone: WatchZone.ID) async throws -> AppNotification {
        throw APIError.notImplemented
    }

    func apply(to shift: Shift.ID, message: String?, source: ApplicationSource) async throws -> Application {
        throw APIError.notImplemented
    }

    func myApplications(od: Optometrist.ID) async throws -> [Application] {
        throw APIError.notImplemented
    }

    func respondToInvite(_ id: Application.ID, accept: Bool) async throws -> Application {
        throw APIError.notImplemented
    }

    func updateApplicationStatus(_ id: Application.ID, to status: ApplicationStatus) async throws -> Application {
        throw APIError.notImplemented
    }

    func booking(id: Booking.ID) async throws -> BookingDetail {
        throw APIError.notImplemented
    }

    func myBookings(role: SessionRole, subjectId: UUID) async throws -> [BookingSummary] {
        throw APIError.notImplemented
    }

    func bookApplicant(_ application: Application.ID) async throws -> Booking {
        throw APIError.notImplemented
    }

    func signContract(booking: Booking.ID, as role: SessionRole) async throws -> Contract {
        throw APIError.notImplemented
    }

    func checkIn(booking: Booking.ID) async throws -> Booking {
        throw APIError.notImplemented
    }

    func checkOut(booking: Booking.ID) async throws -> Booking {
        throw APIError.notImplemented
    }

    func cancelBooking(_ id: Booking.ID, reason: String) async throws -> Booking {
        throw APIError.notImplemented
    }

    func threads(for user: User.ID) async throws -> [ThreadSummary] {
        throw APIError.notImplemented
    }

    func messages(in thread: MessageThread.ID) async throws -> [Message] {
        throw APIError.notImplemented
    }

    func sendMessage(thread: MessageThread.ID, body: String) async throws -> Message {
        throw APIError.notImplemented
    }

    func startThread(withContextShift shift: Shift.ID?, participants: [User.ID]) async throws -> MessageThread {
        throw APIError.notImplemented
    }

    func markThreadRead(_ id: MessageThread.ID, by user: User.ID) async throws {
        throw APIError.notImplemented
    }

    func notifications(for user: User.ID) async throws -> [AppNotification] {
        throw APIError.notImplemented
    }

    func markRead(_ id: AppNotification.ID) async throws {
        throw APIError.notImplemented
    }

    func markAllRead(for user: User.ID) async throws {
        throw APIError.notImplemented
    }

    func unreadCount(for user: User.ID) async throws -> Int {
        throw APIError.notImplemented
    }

    func notificationStream(for user: User.ID) -> AsyncStream<AppNotification> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func optometrist(id: Optometrist.ID) async throws -> Optometrist {
        throw APIError.notImplemented
    }

    func practice(id: Practice.ID) async throws -> Practice {
        throw APIError.notImplemented
    }

    func updateODProfile(_ id: Optometrist.ID, _ input: UpdateODInput) async throws -> Optometrist {
        throw APIError.notImplemented
    }

    func updatePractice(_ id: Practice.ID, _ input: UpdatePracticeInput) async throws -> Practice {
        throw APIError.notImplemented
    }

    func payouts(for od: Optometrist.ID) async throws -> [Payout] {
        throw APIError.notImplemented
    }

    func invoices(for practice: Practice.ID) async throws -> [BillingLine] {
        throw APIError.notImplemented
    }

    func review(forBooking id: Booking.ID, role: ReviewAuthor) async throws -> Review? {
        throw APIError.notImplemented
    }

    func submitReview(_ input: SubmitReviewInput) async throws -> Review {
        throw APIError.notImplemented
    }
}
