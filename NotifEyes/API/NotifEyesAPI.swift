import Foundation

protocol NotifEyesAPI:
    SessionAPI,
    ShiftsAPI,
    WatchZonesAPI,
    ApplicationsAPI,
    BookingsAPI,
    MessagingAPI,
    NotificationsAPI,
    ProfilesAPI,
    PayoutsAPI,
    ReviewsAPI,
    BillingAPI {}

protocol SessionAPI {
    func signIn(email: String, password: String) async throws -> Session
    func currentSession() async throws -> Session?
    func signOut() async throws
    func switchDemoActor(to actor: DemoActor) async throws -> Session
}

protocol ShiftsAPI {
    func browseShifts(filter: ShiftFilter) async throws -> [ShiftSummary]
    func shift(id: Shift.ID) async throws -> ShiftDetail
    func shiftsForPractice(_ id: Practice.ID, status: ShiftStatus?) async throws -> [ShiftSummary]
    func createShift(_ input: CreateShiftInput) async throws -> Shift
    func updateShiftStatus(_ id: Shift.ID, to: ShiftStatus) async throws -> Shift
    func applicants(for id: Shift.ID) async throws -> [ApplicantSummary]
}

protocol WatchZonesAPI {
    func watchZones(for od: Optometrist.ID) async throws -> [WatchZone]
    func createWatchZone(_ input: CreateWatchZoneInput) async throws -> WatchZone
    func updateWatchZone(_ id: WatchZone.ID, _ input: UpdateWatchZoneInput) async throws -> WatchZone
    func setWatchZonePaused(_ id: WatchZone.ID, paused: Bool) async throws -> WatchZone
    func deleteWatchZone(_ id: WatchZone.ID) async throws
    func simulateMatchingShift(for zone: WatchZone.ID) async throws -> AppNotification
}

protocol ApplicationsAPI {
    func apply(to shift: Shift.ID, message: String?, source: ApplicationSource) async throws -> Application
    func myApplications(od: Optometrist.ID) async throws -> [Application]
    func respondToInvite(_ id: Application.ID, accept: Bool) async throws -> Application
    func updateApplicationStatus(_ id: Application.ID, to: ApplicationStatus) async throws -> Application
}

protocol BookingsAPI {
    func booking(id: Booking.ID) async throws -> BookingDetail
    func myBookings(role: SessionRole, subjectId: UUID) async throws -> [BookingSummary]
    func bookApplicant(_ application: Application.ID) async throws -> Booking
    func signContract(booking: Booking.ID, as role: SessionRole) async throws -> Contract
    func checkIn(booking: Booking.ID) async throws -> Booking
    func checkOut(booking: Booking.ID) async throws -> Booking
    func cancelBooking(_ id: Booking.ID, reason: String) async throws -> Booking
}

protocol MessagingAPI {
    func threads(for user: User.ID) async throws -> [ThreadSummary]
    func messages(in thread: MessageThread.ID) async throws -> [Message]
    func sendMessage(thread: MessageThread.ID, body: String) async throws -> Message
    func startThread(withContextShift: Shift.ID?, participants: [User.ID]) async throws -> MessageThread
    func markThreadRead(_ id: MessageThread.ID, by user: User.ID) async throws
}

protocol NotificationsAPI {
    func notifications(for user: User.ID) async throws -> [AppNotification]
    func markRead(_ id: AppNotification.ID) async throws
    func markAllRead(for user: User.ID) async throws
    func unreadCount(for user: User.ID) async throws -> Int
    func notificationStream(for user: User.ID) -> AsyncStream<AppNotification>
}

protocol ProfilesAPI {
    func optometrist(id: Optometrist.ID) async throws -> Optometrist
    func practice(id: Practice.ID) async throws -> Practice
    func updateODProfile(_ id: Optometrist.ID, _ input: UpdateODInput) async throws -> Optometrist
    func updatePractice(_ id: Practice.ID, _ input: UpdatePracticeInput) async throws -> Practice
}

protocol PayoutsAPI {
    func payouts(for od: Optometrist.ID) async throws -> [Payout]
}

protocol BillingAPI {
    func invoices(for practice: Practice.ID) async throws -> [BillingLine]
}

protocol ReviewsAPI {
    func review(forBooking id: Booking.ID, role: ReviewAuthor) async throws -> Review?
    func submitReview(_ input: SubmitReviewInput) async throws -> Review
}
