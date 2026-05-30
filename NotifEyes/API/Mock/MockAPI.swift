import Foundation

struct MockAPI: NotifEyesAPI {
    let store: MockStore

    init(store: MockStore = MockStore()) {
        self.store = store
    }

    func signIn(email: String, password: String) async throws -> Session {
        try await store.signIn(email: email, password: password)
    }

    func currentSession() async throws -> Session? {
        try await store.currentSession()
    }

    func signOut() async throws {
        await store.signOut()
    }

    func switchDemoActor(to actor: DemoActor) async throws -> Session {
        try await store.switchDemoActor(to: actor)
    }

    func browseShifts(filter: ShiftFilter) async throws -> [ShiftSummary] {
        try await store.browseShifts(filter: filter)
    }

    func shift(id: Shift.ID) async throws -> ShiftDetail {
        try await store.shift(id: id)
    }

    func shiftsForPractice(_ id: Practice.ID, status: ShiftStatus?) async throws -> [ShiftSummary] {
        try await store.shiftsForPractice(id, status: status)
    }

    func createShift(_ input: CreateShiftInput) async throws -> Shift {
        try await store.createShift(input)
    }

    func updateShiftStatus(_ id: Shift.ID, to status: ShiftStatus) async throws -> Shift {
        try await store.updateShiftStatus(id, to: status)
    }

    func applicants(for id: Shift.ID) async throws -> [ApplicantSummary] {
        try await store.applicants(for: id)
    }

    func watchZones(for od: Optometrist.ID) async throws -> [WatchZone] {
        await store.watchZones(for: od)
    }

    func createWatchZone(_ input: CreateWatchZoneInput) async throws -> WatchZone {
        try await store.createWatchZone(input)
    }

    func updateWatchZone(_ id: WatchZone.ID, _ input: UpdateWatchZoneInput) async throws -> WatchZone {
        try await store.updateWatchZone(id, input)
    }

    func setWatchZonePaused(_ id: WatchZone.ID, paused: Bool) async throws -> WatchZone {
        try await store.setWatchZonePaused(id, paused: paused)
    }

    func deleteWatchZone(_ id: WatchZone.ID) async throws {
        try await store.deleteWatchZone(id)
    }

    func simulateMatchingShift(for zone: WatchZone.ID) async throws -> AppNotification {
        try await store.simulateMatchingShift(for: zone)
    }

    func apply(to shift: Shift.ID, message: String?, source: ApplicationSource) async throws -> Application {
        try await store.apply(to: shift, message: message, source: source)
    }

    func myApplications(od: Optometrist.ID) async throws -> [Application] {
        await store.myApplications(od: od)
    }

    func respondToInvite(_ id: Application.ID, accept: Bool) async throws -> Application {
        try await store.respondToInvite(id, accept: accept)
    }

    func updateApplicationStatus(_ id: Application.ID, to status: ApplicationStatus) async throws -> Application {
        try await store.updateApplicationStatus(id, to: status)
    }

    func booking(id: Booking.ID) async throws -> BookingDetail {
        try await store.booking(id: id)
    }

    func myBookings(role: SessionRole, subjectId: UUID) async throws -> [BookingSummary] {
        try await store.myBookings(role: role, subjectId: subjectId)
    }

    func bookApplicant(_ application: Application.ID) async throws -> Booking {
        try await store.bookApplicant(application)
    }

    func signContract(booking: Booking.ID, as role: SessionRole) async throws -> Contract {
        try await store.signContract(booking: booking, as: role)
    }

    func checkIn(booking: Booking.ID) async throws -> Booking {
        try await store.checkIn(booking: booking)
    }

    func checkOut(booking: Booking.ID) async throws -> Booking {
        try await store.checkOut(booking: booking)
    }

    func cancelBooking(_ id: Booking.ID, reason: String) async throws -> Booking {
        try await store.cancelBooking(id, reason: reason)
    }

    func threads(for user: User.ID) async throws -> [ThreadSummary] {
        await store.threads(for: user)
    }

    func messages(in thread: MessageThread.ID) async throws -> [Message] {
        try await store.messages(in: thread)
    }

    func sendMessage(thread: MessageThread.ID, body: String) async throws -> Message {
        try await store.sendMessage(thread: thread, body: body)
    }

    func startThread(withContextShift shift: Shift.ID?, participants: [User.ID]) async throws -> MessageThread {
        try await store.startThread(withContextShift: shift, participants: participants)
    }

    func markThreadRead(_ id: MessageThread.ID, by user: User.ID) async throws {
        await store.markThreadRead(id, by: user)
    }

    func notifications(for user: User.ID) async throws -> [AppNotification] {
        await store.notifications(for: user)
    }

    func markRead(_ id: AppNotification.ID) async throws {
        try await store.markRead(id)
    }

    func markAllRead(for user: User.ID) async throws {
        await store.markAllRead(for: user)
    }

    func unreadCount(for user: User.ID) async throws -> Int {
        await store.unreadCount(for: user)
    }

    func notificationStream(for user: User.ID) -> AsyncStream<AppNotification> {
        AsyncStream { continuation in
            let listenerId = UUID()
            Task {
                await store.addNotificationContinuation(for: user, listenerId: listenerId, continuation: continuation)
            }
            continuation.onTermination = { _ in
                Task {
                    await store.removeNotificationContinuation(for: user, listenerId: listenerId)
                }
            }
        }
    }

    func optometrist(id: Optometrist.ID) async throws -> Optometrist {
        try await store.optometrist(id: id)
    }

    func practice(id: Practice.ID) async throws -> Practice {
        try await store.practice(id: id)
    }

    func updateODProfile(_ id: Optometrist.ID, _ input: UpdateODInput) async throws -> Optometrist {
        try await store.updateODProfile(id, input)
    }

    func updatePractice(_ id: Practice.ID, _ input: UpdatePracticeInput) async throws -> Practice {
        try await store.updatePractice(id, input)
    }

    func payouts(for od: Optometrist.ID) async throws -> [Payout] {
        await store.payouts(for: od)
    }

    func invoices(for practice: Practice.ID) async throws -> [BillingLine] {
        try await store.invoices(for: practice)
    }

    func review(forBooking id: Booking.ID, role: ReviewAuthor) async throws -> Review? {
        await store.review(forBooking: id, role: role)
    }

    func submitReview(_ input: SubmitReviewInput) async throws -> Review {
        try await store.submitReview(input)
    }
}
