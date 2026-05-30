import Foundation

struct StoreState: Sendable {
    var users: [User]
    var practices: [Practice]
    var optometrists: [Optometrist]
    var watchZones: [WatchZone]
    var shifts: [Shift]
    var applications: [Application]
    var bookings: [Booking]
    var contracts: [Contract]
    var payouts: [Payout]
    var reviews: [Review]
    var threads: [MessageThread]
    var messages: [Message]
    var notifications: [AppNotification]
    var threadParticipants: [MessageThread.ID: [User.ID]]
    var threadReadAt: [MessageThread.ID: [User.ID: Date]]
    var demoActorUserIds: [DemoActor: User.ID]
    var currentUserId: User.ID?
}

actor MockStore {
    private var state: StoreState
    private var notificationContinuations: [User.ID: [UUID: AsyncStream<AppNotification>.Continuation]] = [:]

    init(seed: StoreState = SeedData.makeSeed()) {
        self.state = seed
    }

    func addNotificationContinuation(
        for userId: User.ID,
        listenerId: UUID,
        continuation: AsyncStream<AppNotification>.Continuation
    ) {
        notificationContinuations[userId, default: [:]][listenerId] = continuation
    }

    func removeNotificationContinuation(for userId: User.ID, listenerId: UUID) {
        notificationContinuations[userId]?[listenerId] = nil
        if notificationContinuations[userId]?.isEmpty == true {
            notificationContinuations[userId] = nil
        }
    }

    func signIn(email: String, password: String) throws -> Session {
        guard !email.isEmpty, !password.isEmpty else {
            throw APIError.invalid("Email and password are required.")
        }
        guard let user = state.users.first(where: { $0.email.caseInsensitiveCompare(email) == .orderedSame }) else {
            throw APIError.unauthorized
        }
        state.currentUserId = user.id
        return try makeSession(user)
    }

    func currentSession() throws -> Session? {
        guard let currentUserId = state.currentUserId else { return nil }
        return try makeSession(user(id: currentUserId))
    }

    func signOut() {
        state.currentUserId = nil
    }

    func switchDemoActor(to actor: DemoActor) throws -> Session {
        guard let userId = state.demoActorUserIds[actor] else {
            throw APIError.notFound
        }
        let user = try user(id: userId)
        state.currentUserId = user.id
        return try makeSession(user)
    }

    func browseShifts(filter: ShiftFilter) throws -> [ShiftSummary] {
        try state.shifts
            .filter { $0.status == .posted }
            .filter { shift in
                if let minRateCents = filter.minRateCents, shift.rateCentsPerHour < minRateCents {
                    return false
                }
                if !filter.types.isEmpty, !filter.types.contains(shift.type) {
                    return false
                }
                if let near = filter.near, let radiusMi = filter.radiusMi {
                    guard
                        let practice = state.practices.first(where: { $0.id == shift.practiceId }),
                        let location = practice.location
                    else { return false }
                    return distanceMeters(near, location) / 1_609.344 <= radiusMi
                }
                return true
            }
            .sorted { $0.startsAt < $1.startsAt }
            .map { try shiftSummary(for: $0, near: filter.near) }
    }

    func shift(id: Shift.ID) throws -> ShiftDetail {
        let shift = try shiftValue(id: id)
        let practice = try practice(id: shift.practiceId)
        let viewerApplication: Application?

        if let current = try currentSession(), current.role == .od, let odId = current.user.odId {
            viewerApplication = state.applications.first { $0.shiftId == id && $0.odId == odId }
        } else {
            viewerApplication = nil
        }

        return ShiftDetail(
            shift: shift,
            practice: practice,
            cost: computeShiftCost(
                rateCentsPerHour: shift.rateCentsPerHour,
                startsAt: shift.startsAt,
                endsAt: shift.endsAt,
                lunchMinutes: shift.lunchMinutes,
                urgent: shift.urgent
            ),
            viewerApplication: viewerApplication
        )
    }

    func shiftsForPractice(_ id: Practice.ID, status: ShiftStatus?) throws -> [ShiftSummary] {
        try state.shifts
            .filter { $0.practiceId == id }
            .filter { status == nil || $0.status == status }
            .sorted { $0.startsAt < $1.startsAt }
            .map { try shiftSummary(for: $0, near: nil) }
    }

    func createShift(_ input: CreateShiftInput) throws -> Shift {
        let session = try requireCurrentSession()
        guard session.role == .practice, let practiceId = session.user.practiceId else {
            throw APIError.unauthorized
        }

        let shift = Shift(
            id: UUID(),
            practiceId: practiceId,
            startsAt: input.startsAt,
            endsAt: input.endsAt,
            lunchMinutes: input.lunchMinutes,
            type: input.type,
            rateCentsPerHour: input.rateCentsPerHour,
            bumpRateCentsPerHour: input.bumpRateCentsPerHour,
            bumpRadiusMeters: input.bumpRadiusMeters,
            servicesNeeded: input.servicesNeeded,
            notesForOd: input.notesForOd,
            visibility: input.visibility,
            status: .draft,
            urgent: input.urgent,
            bookedApplicationId: nil,
            postedAt: nil
        )
        state.shifts.append(shift)
        return shift
    }

    func updateShiftStatus(_ id: Shift.ID, to status: ShiftStatus) throws -> Shift {
        guard let index = state.shifts.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }

        let wasPosted = state.shifts[index].status == .posted
        state.shifts[index].status = status
        if status == .posted, !wasPosted {
            state.shifts[index].postedAt = Date()
            try emitWatchMatches(for: state.shifts[index])
        }
        return state.shifts[index]
    }

    func applicants(for id: Shift.ID) throws -> [ApplicantSummary] {
        try state.applications
            .filter { $0.shiftId == id }
            .sorted { $0.createdAt < $1.createdAt }
            .map { application in
                ApplicantSummary(
                    application: application,
                    optometrist: try optometrist(id: application.odId)
                )
            }
    }

    func watchZones(for od: Optometrist.ID) -> [WatchZone] {
        state.watchZones
            .filter { $0.odId == od }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func createWatchZone(_ input: CreateWatchZoneInput) throws -> WatchZone {
        let session = try requireCurrentSession()
        guard session.role == .od, let odId = session.user.odId else {
            throw APIError.unauthorized
        }

        let zone = WatchZone(
            id: UUID(),
            odId: odId,
            name: input.name,
            shape: shape(for: input.geometryMeta),
            geometryMeta: input.geometryMeta,
            daysOfWeek: input.daysOfWeek,
            timeStart: input.timeStart,
            timeEnd: input.timeEnd,
            minRateCents: input.minRateCents,
            shiftTypes: input.shiftTypes,
            notifyChannels: input.notifyChannels,
            paused: false
        )
        state.watchZones.append(zone)
        return zone
    }

    func updateWatchZone(_ id: WatchZone.ID, _ input: UpdateWatchZoneInput) throws -> WatchZone {
        guard let index = state.watchZones.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }

        if let name = input.name {
            state.watchZones[index].name = name
        }
        if let geometryMeta = input.geometryMeta {
            state.watchZones[index].geometryMeta = geometryMeta
            state.watchZones[index].shape = shape(for: geometryMeta)
        }
        if let daysOfWeek = input.daysOfWeek {
            state.watchZones[index].daysOfWeek = daysOfWeek
        }
        if let timeStart = input.timeStart {
            state.watchZones[index].timeStart = timeStart
        }
        if let timeEnd = input.timeEnd {
            state.watchZones[index].timeEnd = timeEnd
        }
        if let minRateCents = input.minRateCents {
            state.watchZones[index].minRateCents = minRateCents
        }
        if let shiftTypes = input.shiftTypes {
            state.watchZones[index].shiftTypes = shiftTypes
        }
        if let notifyChannels = input.notifyChannels {
            state.watchZones[index].notifyChannels = notifyChannels
        }
        return state.watchZones[index]
    }

    func setWatchZonePaused(_ id: WatchZone.ID, paused: Bool) throws -> WatchZone {
        guard let index = state.watchZones.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.watchZones[index].paused = paused
        return state.watchZones[index]
    }

    func deleteWatchZone(_ id: WatchZone.ID) throws {
        guard let index = state.watchZones.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.watchZones.remove(at: index)
    }

    func simulateMatchingShift(for zoneId: WatchZone.ID) throws -> AppNotification {
        let zone = try watchZone(id: zoneId)
        let practice = try practice(id: SeedIDs.bayviewPractice)
        let startsAt = Date().addingTimeInterval(2 * 24 * 60 * 60)
        let endsAt = startsAt.addingTimeInterval(8 * 60 * 60)
        let shift = Shift(
            id: UUID(),
            practiceId: practice.id,
            startsAt: startsAt,
            endsAt: endsAt,
            lunchMinutes: 30,
            type: zone.shiftTypes.first ?? .fill_in,
            rateCentsPerHour: max(zone.minRateCents, 12_000),
            bumpRateCentsPerHour: nil,
            bumpRadiusMeters: nil,
            servicesNeeded: practice.services,
            notesForOd: "Mock watch-match shift generated from \(zone.name).",
            visibility: .public,
            status: .posted,
            urgent: true,
            bookedApplicationId: nil,
            postedAt: Date()
        )
        state.shifts.append(shift)

        let notification = try watchMatchNotification(for: shift, zone: zone)
        storeAndEmit(notification)
        return notification
    }

    func apply(to shiftId: Shift.ID, message: String?, source: ApplicationSource) throws -> Application {
        let session = try requireCurrentSession()
        guard session.role == .od, let odId = session.user.odId else {
            throw APIError.unauthorized
        }
        let shift = try shiftValue(id: shiftId)
        guard shift.status == .posted else {
            throw APIError.invalid("Applications are only open for posted shifts.")
        }
        if let existing = state.applications.first(where: { $0.shiftId == shiftId && $0.odId == odId }) {
            return existing
        }

        let application = Application(
            id: UUID(),
            shiftId: shiftId,
            odId: odId,
            source: source,
            message: message,
            status: .applied,
            createdAt: Date()
        )
        state.applications.append(application)

        for user in state.users where user.practiceId == shift.practiceId {
            storeAndEmit(AppNotification(
                id: UUID(),
                userId: user.id,
                kind: .new_applicant,
                payload: ["shiftId": shiftId.uuidString, "applicationId": application.id.uuidString],
                actionUrl: "/shifts/\(shiftId.uuidString)",
                readAt: nil,
                createdAt: Date()
            ))
        }
        return application
    }

    func myApplications(od: Optometrist.ID) -> [Application] {
        state.applications
            .filter { $0.odId == od }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func respondToInvite(_ id: Application.ID, accept: Bool) throws -> Application {
        try updateApplicationStatus(id, to: accept ? .accepted : .declined)
    }

    func updateApplicationStatus(_ id: Application.ID, to status: ApplicationStatus) throws -> Application {
        guard let index = state.applications.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.applications[index].status = status
        return state.applications[index]
    }

    func booking(id: Booking.ID) throws -> BookingDetail {
        let booking = try bookingValue(id: id)
        let shift = try shiftValue(id: booking.shiftId)
        return BookingDetail(
            booking: booking,
            shift: shift,
            practice: try practice(id: booking.practiceId),
            optometrist: try optometrist(id: booking.odId),
            contract: booking.contractId.flatMap { try? contract(id: $0) },
            thread: state.threads.first { $0.contextBookingId == id }
        )
    }

    func myBookings(role: SessionRole, subjectId: UUID) throws -> [BookingSummary] {
        try state.bookings
            .filter { booking in
                switch role {
                case .od:
                    return booking.odId == subjectId
                case .practice:
                    return booking.practiceId == subjectId
                }
            }
            .sorted { bookingA, bookingB in
                (try? shiftValue(id: bookingA.shiftId).startsAt) ?? .distantPast < (try? shiftValue(id: bookingB.shiftId).startsAt) ?? .distantPast
            }
            .map { booking in
                let shift = try shiftValue(id: booking.shiftId)
                return BookingSummary(
                    booking: booking,
                    shift: shift,
                    practice: try practice(id: booking.practiceId),
                    optometrist: try optometrist(id: booking.odId),
                    contract: booking.contractId.flatMap { try? contract(id: $0) }
                )
            }
    }

    func bookApplicant(_ applicationId: Application.ID) throws -> Booking {
        guard let appIndex = state.applications.firstIndex(where: { $0.id == applicationId }) else {
            throw APIError.notFound
        }
        let application = state.applications[appIndex]
        let shift = try shiftValue(id: application.shiftId)
        let cost = computeShiftCost(
            rateCentsPerHour: shift.rateCentsPerHour,
            startsAt: shift.startsAt,
            endsAt: shift.endsAt,
            lunchMinutes: shift.lunchMinutes,
            urgent: shift.urgent
        )
        let bookingId = UUID()
        let contractId = UUID()
        var booking = Booking(
            id: bookingId,
            shiftId: shift.id,
            odId: application.odId,
            practiceId: shift.practiceId,
            applicationId: application.id,
            contractId: contractId,
            totalCents: cost.totalCents,
            platformFeeCents: cost.feeCents,
            status: .confirmed,
            checkInAt: nil,
            checkOutAt: nil,
            cancellationReason: nil,
            cancellationFeeCents: nil,
            paymentStatus: "authorized"
        )
        let contract = Contract(
            id: contractId,
            bookingId: bookingId,
            templateVersion: "mock-v1",
            bodyText: "NotifEyes fill-in OD agreement.",
            signedByPracticeAt: Date(),
            signedByOdAt: nil
        )

        state.applications[appIndex].status = .accepted
        if let shiftIndex = state.shifts.firstIndex(where: { $0.id == shift.id }) {
            state.shifts[shiftIndex].status = .booked
            state.shifts[shiftIndex].bookedApplicationId = application.id
        }
        state.contracts.append(contract)
        booking.contractId = contract.id
        state.bookings.append(booking)

        let thread = MessageThread(id: UUID(), contextBookingId: booking.id, contextShiftId: shift.id, lastMessageAt: Date())
        state.threads.append(thread)
        let participants = usersForPractice(shift.practiceId).map(\.id) + usersForOD(application.odId).map(\.id)
        state.threadParticipants[thread.id] = participants
        state.messages.append(Message(id: UUID(), threadId: thread.id, senderUserId: nil, body: "Booking confirmed.", createdAt: Date(), systemKind: "booking_confirmed"))

        for userId in participants {
            storeAndEmit(AppNotification(
                id: UUID(),
                userId: userId,
                kind: .booking_confirmed,
                payload: ["bookingId": booking.id.uuidString],
                actionUrl: "/bookings/\(booking.id.uuidString)",
                readAt: nil,
                createdAt: Date()
            ))
        }
        return booking
    }

    func signContract(booking id: Booking.ID, as role: SessionRole) throws -> Contract {
        let booking = try bookingValue(id: id)
        guard let contractId = booking.contractId, let index = state.contracts.firstIndex(where: { $0.id == contractId }) else {
            throw APIError.notFound
        }
        switch role {
        case .od:
            state.contracts[index].signedByOdAt = Date()
        case .practice:
            state.contracts[index].signedByPracticeAt = Date()
        }
        return state.contracts[index]
    }

    func checkIn(booking id: Booking.ID) throws -> Booking {
        guard let index = state.bookings.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.bookings[index].status = .in_progress
        state.bookings[index].checkInAt = Date()
        return state.bookings[index]
    }

    func checkOut(booking id: Booking.ID) throws -> Booking {
        guard let index = state.bookings.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.bookings[index].status = .completed
        state.bookings[index].checkOutAt = Date()
        if let shiftIndex = state.shifts.firstIndex(where: { $0.id == state.bookings[index].shiftId }) {
            state.shifts[shiftIndex].status = .completed
        }
        return state.bookings[index]
    }

    func cancelBooking(_ id: Booking.ID, reason: String) throws -> Booking {
        guard let index = state.bookings.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.bookings[index].status = .cancelled
        state.bookings[index].cancellationReason = reason
        state.bookings[index].cancellationFeeCents = 5_000
        return state.bookings[index]
    }

    func threads(for user: User.ID) -> [ThreadSummary] {
        state.threads
            .filter { state.threadParticipants[$0.id, default: []].contains(user) }
            .sorted { ($0.lastMessageAt ?? .distantPast) > ($1.lastMessageAt ?? .distantPast) }
            .map { thread in
                let participantIds = state.threadParticipants[thread.id, default: []]
                let participants = state.users.filter { participantIds.contains($0.id) }
                let readAt = state.threadReadAt[thread.id]?[user] ?? .distantPast
                let messages = state.messages.filter { $0.threadId == thread.id }
                let unreadCount = messages.filter { $0.senderUserId != user && $0.createdAt > readAt }.count
                return ThreadSummary(
                    thread: thread,
                    participants: participants,
                    lastMessage: messages.sorted { $0.createdAt < $1.createdAt }.last,
                    unreadCount: unreadCount
                )
            }
    }

    func messages(in thread: MessageThread.ID) throws -> [Message] {
        guard state.threads.contains(where: { $0.id == thread }) else {
            throw APIError.notFound
        }
        return state.messages
            .filter { $0.threadId == thread }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func sendMessage(thread threadId: MessageThread.ID, body: String) throws -> Message {
        let session = try requireCurrentSession()
        guard state.threads.contains(where: { $0.id == threadId }) else {
            throw APIError.notFound
        }
        let message = Message(id: UUID(), threadId: threadId, senderUserId: session.user.id, body: body, createdAt: Date(), systemKind: nil)
        state.messages.append(message)
        if let index = state.threads.firstIndex(where: { $0.id == threadId }) {
            state.threads[index].lastMessageAt = message.createdAt
        }

        for userId in state.threadParticipants[threadId, default: []] where userId != session.user.id {
            storeAndEmit(AppNotification(
                id: UUID(),
                userId: userId,
                kind: .message_received,
                payload: ["threadId": threadId.uuidString],
                actionUrl: "/messages/\(threadId.uuidString)",
                readAt: nil,
                createdAt: Date()
            ))
        }
        return message
    }

    func startThread(withContextShift shiftId: Shift.ID?, participants: [User.ID]) throws -> MessageThread {
        var participantIds = participants
        if let currentUserId = state.currentUserId, !participantIds.contains(currentUserId) {
            participantIds.append(currentUserId)
        }
        let thread = MessageThread(id: UUID(), contextBookingId: nil, contextShiftId: shiftId, lastMessageAt: nil)
        state.threads.append(thread)
        state.threadParticipants[thread.id] = participantIds
        return thread
    }

    func markThreadRead(_ id: MessageThread.ID, by user: User.ID) {
        state.threadReadAt[id, default: [:]][user] = Date()
    }

    func notifications(for user: User.ID) -> [AppNotification] {
        state.notifications
            .filter { $0.userId == user }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func markRead(_ id: AppNotification.ID) throws {
        guard let index = state.notifications.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        state.notifications[index].readAt = Date()
    }

    func markAllRead(for user: User.ID) {
        for index in state.notifications.indices where state.notifications[index].userId == user {
            state.notifications[index].readAt = Date()
        }
    }

    func unreadCount(for user: User.ID) -> Int {
        state.notifications.filter { $0.userId == user && $0.readAt == nil }.count
    }

    func optometrist(id: Optometrist.ID) throws -> Optometrist {
        guard let optometrist = state.optometrists.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return optometrist
    }

    func practice(id: Practice.ID) throws -> Practice {
        guard let practice = state.practices.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return practice
    }

    func updateODProfile(_ id: Optometrist.ID, _ input: UpdateODInput) throws -> Optometrist {
        guard let index = state.optometrists.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        if let name = input.name { state.optometrists[index].name = name }
        if let displayName = input.displayName { state.optometrists[index].displayName = displayName }
        if let bio = input.bio { state.optometrists[index].bio = bio }
        if let headshotUrl = input.headshotUrl { state.optometrists[index].headshotUrl = headshotUrl }
        if let homeLocation = input.homeLocation { state.optometrists[index].homeLocation = homeLocation }
        if let travelRadiusMi = input.travelRadiusMi { state.optometrists[index].travelRadiusMi = travelRadiusMi }
        if let licenseState = input.licenseState { state.optometrists[index].licenseState = licenseState }
        if let specialties = input.specialties { state.optometrists[index].specialties = specialties }
        if let ehrExperience = input.ehrExperience { state.optometrists[index].ehrExperience = ehrExperience }
        return state.optometrists[index]
    }

    func updatePractice(_ id: Practice.ID, _ input: UpdatePracticeInput) throws -> Practice {
        guard let index = state.practices.firstIndex(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        if let name = input.name { state.practices[index].name = name }
        if let dba = input.dba { state.practices[index].dba = dba }
        if let bio = input.bio { state.practices[index].bio = bio }
        if let addressLine = input.addressLine { state.practices[index].addressLine = addressLine }
        if let city = input.city { state.practices[index].city = city }
        if let stateValue = input.state { state.practices[index].state = stateValue }
        if let zip = input.zip { state.practices[index].zip = zip }
        if let location = input.location { state.practices[index].location = location }
        if let services = input.services { state.practices[index].services = services }
        if let languages = input.languages { state.practices[index].languages = languages }
        return state.practices[index]
    }

    func payouts(for od: Optometrist.ID) -> [Payout] {
        state.payouts
            .filter { $0.odId == od }
            .sorted { $0.scheduledFor > $1.scheduledFor }
    }

    func invoices(for practiceId: Practice.ID) throws -> [BillingLine] {
        try state.bookings
            .filter { $0.practiceId == practiceId }
            .sorted { bookingA, bookingB in
                (try? shiftValue(id: bookingA.shiftId).startsAt) ?? .distantPast > (try? shiftValue(id: bookingB.shiftId).startsAt) ?? .distantPast
            }
            .map { booking in
                let shift = try shiftValue(id: booking.shiftId)
                return BillingLine(
                    id: booking.id,
                    bookingId: booking.id,
                    description: "OD coverage on \(shift.startsAt.formatted(date: .abbreviated, time: .omitted))",
                    subtotalCents: booking.totalCents - booking.platformFeeCents,
                    platformFeeCents: booking.platformFeeCents,
                    totalCents: booking.totalCents,
                    status: booking.paymentStatus,
                    issuedAt: shift.endsAt
                )
            }
    }

    func review(forBooking id: Booking.ID, role: ReviewAuthor) -> Review? {
        state.reviews.first { $0.bookingId == id && $0.authorRole == role }
    }

    func submitReview(_ input: SubmitReviewInput) throws -> Review {
        guard (1...5).contains(input.ratingOverall) else {
            throw APIError.invalid("Rating must be between 1 and 5.")
        }
        let review = Review(
            id: UUID(),
            bookingId: input.bookingId,
            authorRole: input.authorRole,
            ratingOverall: input.ratingOverall,
            ratingSpecifics: input.ratingSpecifics,
            publicComment: input.publicComment,
            privateFeedback: input.privateFeedback,
            publishedAt: Date()
        )
        if let index = state.reviews.firstIndex(where: { $0.bookingId == input.bookingId && $0.authorRole == input.authorRole }) {
            state.reviews[index] = review
        } else {
            state.reviews.append(review)
        }
        return review
    }
}

private extension MockStore {
    func user(id: User.ID) throws -> User {
        guard let user = state.users.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return user
    }

    func requireCurrentSession() throws -> Session {
        guard let session = try currentSession() else {
            throw APIError.unauthorized
        }
        return session
    }

    func makeSession(_ user: User) throws -> Session {
        Session(user: user, role: try SessionRole(user: user))
    }

    func shiftValue(id: Shift.ID) throws -> Shift {
        guard let shift = state.shifts.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return shift
    }

    func bookingValue(id: Booking.ID) throws -> Booking {
        guard let booking = state.bookings.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return booking
    }

    func contract(id: Contract.ID) throws -> Contract {
        guard let contract = state.contracts.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return contract
    }

    func watchZone(id: WatchZone.ID) throws -> WatchZone {
        guard let zone = state.watchZones.first(where: { $0.id == id }) else {
            throw APIError.notFound
        }
        return zone
    }

    func usersForOD(_ odId: Optometrist.ID) -> [User] {
        state.users.filter { $0.odId == odId }
    }

    func usersForPractice(_ practiceId: Practice.ID) -> [User] {
        state.users.filter { $0.practiceId == practiceId }
    }

    func shiftSummary(for shift: Shift, near: LatLng?) throws -> ShiftSummary {
        let practice = try practice(id: shift.practiceId)
        let distanceMi: Double?
        if let near, let location = practice.location {
            distanceMi = distanceMeters(near, location) / 1_609.344
        } else {
            distanceMi = nil
        }

        return ShiftSummary(
            id: shift.id,
            practiceName: practice.name,
            practiceId: practice.id,
            startsAt: shift.startsAt,
            endsAt: shift.endsAt,
            type: shift.type,
            rateCentsPerHour: shift.rateCentsPerHour,
            bumpRateCentsPerHour: shift.bumpRateCentsPerHour,
            status: shift.status,
            urgent: shift.urgent,
            location: practice.location,
            distanceMi: distanceMi
        )
    }

    func emitWatchMatches(for shift: Shift) throws {
        let practice = try practice(id: shift.practiceId)
        for zone in state.watchZones where matches(zone: zone, shift: shift, practice: practice) {
            storeAndEmit(try watchMatchNotification(for: shift, zone: zone))
        }
    }

    func watchMatchNotification(for shift: Shift, zone: WatchZone) throws -> AppNotification {
        guard let user = usersForOD(zone.odId).first else {
            throw APIError.notFound
        }
        return AppNotification(
            id: UUID(),
            userId: user.id,
            kind: .watch_match,
            payload: ["shiftId": shift.id.uuidString, "watchZoneId": zone.id.uuidString],
            actionUrl: "/shifts/\(shift.id.uuidString)",
            readAt: nil,
            createdAt: Date()
        )
    }

    func storeAndEmit(_ notification: AppNotification) {
        state.notifications.append(notification)
        emit(notification)
    }

    func emit(_ notification: AppNotification) {
        guard let continuations = notificationContinuations[notification.userId] else { return }
        for continuation in continuations.values {
            continuation.yield(notification)
        }
    }

    func matches(zone: WatchZone, shift: Shift, practice: Practice) -> Bool {
        guard !zone.paused else { return false }
        guard zone.shiftTypes.contains(shift.type) else { return false }
        guard shift.rateCentsPerHour >= zone.minRateCents else { return false }
        guard zone.daysOfWeek.contains(dayOfWeek(for: shift.startsAt)) else { return false }
        guard matchesTimeWindow(zone: zone, startsAt: shift.startsAt) else { return false }
        guard let practiceLocation = practice.location else { return false }

        switch zone.geometryMeta {
        case let .circle(centerLat, centerLng, radiusMeters):
            return distanceMeters(LatLng(lat: centerLat, lng: centerLng), practiceLocation) <= radiusMeters
        case let .polygon(points):
            return polygon(points, contains: practiceLocation)
        }
    }

    func matchesTimeWindow(zone: WatchZone, startsAt: Date) -> Bool {
        let startMinutes = minutesSinceMidnight(startsAt)
        if let timeStart = zone.timeStart, let min = minutes(timeStart), startMinutes < min {
            return false
        }
        if let timeEnd = zone.timeEnd, let max = minutes(timeEnd), startMinutes > max {
            return false
        }
        return true
    }

    func dayOfWeek(for date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.component(.weekday, from: date) - 1
    }

    func minutesSinceMidnight(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }

    func minutes(_ hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }

    func shape(for geometryMeta: GeometryMeta) -> WatchZoneShape {
        switch geometryMeta {
        case .circle:
            return .circle
        case .polygon:
            return .polygon
        }
    }

    func distanceMeters(_ lhs: LatLng, _ rhs: LatLng) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lhsLat = lhs.lat * .pi / 180
        let rhsLat = rhs.lat * .pi / 180
        let deltaLat = (rhs.lat - lhs.lat) * .pi / 180
        let deltaLng = (rhs.lng - lhs.lng) * .pi / 180
        let a = sin(deltaLat / 2) * sin(deltaLat / 2)
            + cos(lhsLat) * cos(rhsLat) * sin(deltaLng / 2) * sin(deltaLng / 2)
        return earthRadiusMeters * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    func polygon(_ points: [LatLng], contains point: LatLng) -> Bool {
        guard points.count >= 3 else { return false }
        var inside = false
        var j = points.count - 1
        for i in points.indices {
            let yi = points[i].lat
            let yj = points[j].lat
            let xi = points[i].lng
            let xj = points[j].lng
            if ((yi > point.lat) != (yj > point.lat))
                && (point.lng < (xj - xi) * (point.lat - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}
