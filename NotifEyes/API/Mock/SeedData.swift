import Foundation

enum SeedIDs {
    static let mayaUser = UUID(uuidString: "00000000-0000-4000-8000-000000000101")!
    static let yaraUser = UUID(uuidString: "00000000-0000-4000-8000-000000000102")!
    static let bayviewUser = UUID(uuidString: "00000000-0000-4000-8000-000000000103")!
    static let oaklandUser = UUID(uuidString: "00000000-0000-4000-8000-000000000104")!
    static let campbellUser = UUID(uuidString: "00000000-0000-4000-8000-000000000105")!
    static let lenaUser = UUID(uuidString: "00000000-0000-4000-8000-000000000106")!
    static let theoUser = UUID(uuidString: "00000000-0000-4000-8000-000000000107")!
    static let priyaUser = UUID(uuidString: "00000000-0000-4000-8000-000000000108")!

    static let mayaOD = UUID(uuidString: "00000000-0000-4000-8000-000000000201")!
    static let yaraOD = UUID(uuidString: "00000000-0000-4000-8000-000000000202")!
    static let lenaOD = UUID(uuidString: "00000000-0000-4000-8000-000000000203")!
    static let theoOD = UUID(uuidString: "00000000-0000-4000-8000-000000000204")!
    static let priyaOD = UUID(uuidString: "00000000-0000-4000-8000-000000000205")!
    static let jordanOD = UUID(uuidString: "00000000-0000-4000-8000-000000000206")!

    static let bayviewPractice = UUID(uuidString: "00000000-0000-4000-8000-000000000301")!
    static let oaklandPractice = UUID(uuidString: "00000000-0000-4000-8000-000000000302")!
    static let campbellPractice = UUID(uuidString: "00000000-0000-4000-8000-000000000303")!
    static let marinPractice = UUID(uuidString: "00000000-0000-4000-8000-000000000304")!
    static let paloAltoPractice = UUID(uuidString: "00000000-0000-4000-8000-000000000305")!

    static let mayaZone = UUID(uuidString: "00000000-0000-4000-8000-000000000401")!
    static let mayaPolygonZone = UUID(uuidString: "00000000-0000-4000-8000-000000000402")!
    static let yaraZone = UUID(uuidString: "00000000-0000-4000-8000-000000000403")!

    static let shiftBayviewPosted = UUID(uuidString: "00000000-0000-4000-8000-000000000501")!
    static let shiftOaklandPosted = UUID(uuidString: "00000000-0000-4000-8000-000000000502")!
    static let shiftCampbellPosted = UUID(uuidString: "00000000-0000-4000-8000-000000000503")!
    static let shiftBooked = UUID(uuidString: "00000000-0000-4000-8000-000000000504")!
    static let shiftCompleted = UUID(uuidString: "00000000-0000-4000-8000-000000000505")!

    static let appYaraBayview = UUID(uuidString: "00000000-0000-4000-8000-000000000601")!
    static let appMayaBooked = UUID(uuidString: "00000000-0000-4000-8000-000000000602")!

    static let bookingMaya = UUID(uuidString: "00000000-0000-4000-8000-000000000701")!
    static let bookingCompleted = UUID(uuidString: "00000000-0000-4000-8000-000000000702")!

    static let contractMaya = UUID(uuidString: "00000000-0000-4000-8000-000000000801")!
    static let contractCompleted = UUID(uuidString: "00000000-0000-4000-8000-000000000802")!

    static let payoutMaya = UUID(uuidString: "00000000-0000-4000-8000-000000000901")!
    static let reviewMaya = UUID(uuidString: "00000000-0000-4000-8000-000000000A01")!

    static let threadBooking = UUID(uuidString: "00000000-0000-4000-8000-000000000B01")!
    static let threadBayviewShift = UUID(uuidString: "00000000-0000-4000-8000-000000000B02")!

    static let messageOne = UUID(uuidString: "00000000-0000-4000-8000-000000000C01")!
    static let messageTwo = UUID(uuidString: "00000000-0000-4000-8000-000000000C02")!
    static let messageThree = UUID(uuidString: "00000000-0000-4000-8000-000000000C03")!

    static let notificationMaya = UUID(uuidString: "00000000-0000-4000-8000-000000000D01")!
    static let notificationBayview = UUID(uuidString: "00000000-0000-4000-8000-000000000D02")!
}

enum SeedData {
    static func makeSeed() -> StoreState {
        let users = makeUsers()
        let optometrists = makeOptometrists()
        let practices = makePractices()
        let shifts = makeShifts()
        let applications = makeApplications()
        let bookings = makeBookings()
        let contracts = makeContracts()
        let payouts = makePayouts()
        let reviews = makeReviews()
        let threads = makeThreads()
        let messages = makeMessages()

        return StoreState(
            users: users,
            practices: practices,
            optometrists: optometrists,
            watchZones: makeWatchZones(),
            shifts: shifts,
            applications: applications,
            bookings: bookings,
            contracts: contracts,
            payouts: payouts,
            reviews: reviews,
            threads: threads,
            messages: messages,
            notifications: makeNotifications(),
            threadParticipants: [
                SeedIDs.threadBooking: [SeedIDs.mayaUser, SeedIDs.bayviewUser],
                SeedIDs.threadBayviewShift: [SeedIDs.yaraUser, SeedIDs.bayviewUser]
            ],
            threadReadAt: [
                SeedIDs.threadBooking: [
                    SeedIDs.mayaUser: date(2026, 5, 26, 15, 30),
                    SeedIDs.bayviewUser: date(2026, 5, 26, 15, 30)
                ]
            ],
            demoActorUserIds: [
                .mayaPatel: SeedIDs.mayaUser,
                .yaraBrennan: SeedIDs.yaraUser,
                .bayviewEyeCare: SeedIDs.bayviewUser
            ],
            currentUserId: nil
        )
    }

    private static func makeUsers() -> [User] {
        [
            User(id: SeedIDs.mayaUser, email: "maya@example.com", role: .od, name: "Maya Patel", practiceId: nil, odId: SeedIDs.mayaOD, phone: "415-555-0101", emailOptedIn: true, smsOptedIn: true),
            User(id: SeedIDs.yaraUser, email: "yara@example.com", role: .od, name: "Yara Brennan", practiceId: nil, odId: SeedIDs.yaraOD, phone: "415-555-0102", emailOptedIn: true, smsOptedIn: false),
            User(id: SeedIDs.bayviewUser, email: "owner@bayview.example.com", role: .practice_owner, name: "Bayview Eye Care", practiceId: SeedIDs.bayviewPractice, odId: nil, phone: "415-555-0103", emailOptedIn: true, smsOptedIn: true),
            User(id: SeedIDs.oaklandUser, email: "ops@oakland.example.com", role: .practice_owner, name: "Oakland Optometry Group", practiceId: SeedIDs.oaklandPractice, odId: nil, phone: nil, emailOptedIn: true, smsOptedIn: false),
            User(id: SeedIDs.campbellUser, email: "admin@campbell.example.com", role: .practice_scheduler, name: "Campbell Vision Studio", practiceId: SeedIDs.campbellPractice, odId: nil, phone: nil, emailOptedIn: true, smsOptedIn: false),
            User(id: SeedIDs.lenaUser, email: "lena@example.com", role: .od, name: "Lena Ortiz", practiceId: nil, odId: SeedIDs.lenaOD, phone: nil, emailOptedIn: true, smsOptedIn: false),
            User(id: SeedIDs.theoUser, email: "theo@example.com", role: .od, name: "Theo Walsh", practiceId: nil, odId: SeedIDs.theoOD, phone: nil, emailOptedIn: true, smsOptedIn: false),
            User(id: SeedIDs.priyaUser, email: "priya@example.com", role: .od, name: "Priya Shah", practiceId: nil, odId: SeedIDs.priyaOD, phone: nil, emailOptedIn: true, smsOptedIn: false)
        ]
    }

    private static func makePractices() -> [Practice] {
        [
            Practice(id: SeedIDs.bayviewPractice, name: "Bayview Eye Care", dba: nil, bio: "Independent SF practice with a modern exam lane and friendly support team.", addressLine: "2211 Divisadero St", city: "San Francisco", state: "CA", zip: "94115", location: LatLng(lat: 37.7849, lng: -122.4444), services: ["Comprehensive exams", "Contacts", "Medical optometry"], languages: ["English", "Spanish"], ratingAvg: 4.9, ratingCount: 42, shiftsCompleted: 128, businessLicenseVerified: true, paymentMethodVerified: true),
            Practice(id: SeedIDs.oaklandPractice, name: "Oakland Optometry Group", dba: nil, bio: "Busy East Bay group practice near transit.", addressLine: "1900 Broadway", city: "Oakland", state: "CA", zip: "94612", location: LatLng(lat: 37.8268, lng: -122.2632), services: ["Comprehensive exams", "Dry eye", "Glaucoma"], languages: ["English"], ratingAvg: 4.7, ratingCount: 31, shiftsCompleted: 89, businessLicenseVerified: true, paymentMethodVerified: true),
            Practice(id: SeedIDs.campbellPractice, name: "Campbell Vision Studio", dba: nil, bio: "South Bay clinic with high contact lens volume.", addressLine: "2290 S Bascom Ave", city: "Campbell", state: "CA", zip: "95008", location: LatLng(lat: 37.2872, lng: -121.9499), services: ["Contacts", "Pediatrics"], languages: ["English", "Vietnamese"], ratingAvg: 4.8, ratingCount: 18, shiftsCompleted: 56, businessLicenseVerified: true, paymentMethodVerified: true),
            Practice(id: SeedIDs.marinPractice, name: "Marin Family Optometry", dba: nil, bio: "Family-focused practice north of the bridge.", addressLine: "700 Irwin St", city: "San Rafael", state: "CA", zip: "94901", location: LatLng(lat: 37.9735, lng: -122.5311), services: ["Comprehensive exams", "Pediatrics"], languages: ["English"], ratingAvg: 4.6, ratingCount: 15, shiftsCompleted: 44, businessLicenseVerified: true, paymentMethodVerified: false),
            Practice(id: SeedIDs.paloAltoPractice, name: "Palo Alto Eye Clinic", dba: nil, bio: "Medical optometry clinic close to downtown Palo Alto.", addressLine: "855 El Camino Real", city: "Palo Alto", state: "CA", zip: "94301", location: LatLng(lat: 37.4419, lng: -122.1430), services: ["Medical optometry", "Glaucoma", "OCT"], languages: ["English", "Mandarin"], ratingAvg: 4.9, ratingCount: 27, shiftsCompleted: 73, businessLicenseVerified: true, paymentMethodVerified: true)
        ]
    }

    private static func makeOptometrists() -> [Optometrist] {
        [
            Optometrist(id: SeedIDs.mayaOD, name: "Maya Patel", displayName: "Dr. Maya Patel", bio: "Fill-in OD focused on efficient comprehensive exams and warm patient handoffs.", headshotUrl: nil, homeLocation: LatLng(lat: 37.7749, lng: -122.4194), travelRadiusMi: 35, licenseState: "CA", verificationStatus: .verified, specialties: ["Contacts", "Dry eye", "Medical optometry"], ehrExperience: ["Eyefinity", "RevolutionEHR"], ratingAvg: 4.95, ratingCount: 38, shiftsCompleted: 112, noShowCount: 0),
            Optometrist(id: SeedIDs.yaraOD, name: "Yara Brennan", displayName: "Dr. Yara Brennan", bio: "Recently relocated OD finishing NotifEyes credential verification.", headshotUrl: nil, homeLocation: LatLng(lat: 37.8044, lng: -122.2712), travelRadiusMi: 20, licenseState: "CA", verificationStatus: .pending, specialties: ["Comprehensive exams", "Contacts"], ehrExperience: ["Crystal PM"], ratingAvg: nil, ratingCount: 0, shiftsCompleted: 0, noShowCount: 0),
            Optometrist(id: SeedIDs.lenaOD, name: "Lena Ortiz", displayName: "Dr. Lena Ortiz", bio: "Experienced weekend coverage around the Peninsula.", headshotUrl: nil, homeLocation: LatLng(lat: 37.5630, lng: -122.3255), travelRadiusMi: 30, licenseState: "CA", verificationStatus: .verified, specialties: ["Pediatrics", "Contacts"], ehrExperience: ["Eyefinity"], ratingAvg: 4.8, ratingCount: 21, shiftsCompleted: 66, noShowCount: 0),
            Optometrist(id: SeedIDs.theoOD, name: "Theo Walsh", displayName: "Dr. Theo Walsh", bio: "Medical optometry and glaucoma co-management.", headshotUrl: nil, homeLocation: LatLng(lat: 37.3382, lng: -121.8863), travelRadiusMi: 40, licenseState: "CA", verificationStatus: .verified, specialties: ["Glaucoma", "OCT", "Medical optometry"], ehrExperience: ["RevolutionEHR", "Compulink"], ratingAvg: 4.7, ratingCount: 16, shiftsCompleted: 49, noShowCount: 1),
            Optometrist(id: SeedIDs.priyaOD, name: "Priya Shah", displayName: "Dr. Priya Shah", bio: "Flexible coverage for high-volume contact lens clinics.", headshotUrl: nil, homeLocation: LatLng(lat: 37.7749, lng: -122.4194), travelRadiusMi: 25, licenseState: "CA", verificationStatus: .verified, specialties: ["Contacts", "Dry eye"], ehrExperience: ["Crystal PM", "Eyefinity"], ratingAvg: 4.9, ratingCount: 12, shiftsCompleted: 33, noShowCount: 0),
            Optometrist(id: SeedIDs.jordanOD, name: "Jordan Kim", displayName: "Dr. Jordan Kim", bio: "Half-day coverage across Marin and SF.", headshotUrl: nil, homeLocation: LatLng(lat: 37.9735, lng: -122.5311), travelRadiusMi: 25, licenseState: "CA", verificationStatus: .verified, specialties: ["Comprehensive exams"], ehrExperience: ["OfficeMate"], ratingAvg: 4.6, ratingCount: 9, shiftsCompleted: 24, noShowCount: 0)
        ]
    }

    private static func makeWatchZones() -> [WatchZone] {
        [
            WatchZone(id: SeedIDs.mayaZone, odId: SeedIDs.mayaOD, name: "SF + East Bay", shape: .circle, geometryMeta: .circle(centerLat: 37.7749, centerLng: -122.4194, radiusMeters: 25 * 1_609.344), daysOfWeek: [1, 2, 3, 4, 5, 6, 0], timeStart: "08:00", timeEnd: "18:00", minRateCents: 10_000, shiftTypes: [.fill_in, .half_day, .weekend], notifyChannels: [.push, .email], paused: false),
            WatchZone(id: SeedIDs.mayaPolygonZone, odId: SeedIDs.mayaOD, name: "Peninsula polygon", shape: .polygon, geometryMeta: .polygon(points: [
                LatLng(lat: 37.70, lng: -122.50),
                LatLng(lat: 37.55, lng: -122.37),
                LatLng(lat: 37.43, lng: -122.18),
                LatLng(lat: 37.62, lng: -122.13)
            ]), daysOfWeek: [2, 3, 4], timeStart: nil, timeEnd: nil, minRateCents: 11_000, shiftTypes: [.fill_in, .half_day], notifyChannels: [.email], paused: true),
            WatchZone(id: SeedIDs.yaraZone, odId: SeedIDs.yaraOD, name: "Oakland starter zone", shape: .circle, geometryMeta: .circle(centerLat: 37.8044, centerLng: -122.2712, radiusMeters: 15 * 1_609.344), daysOfWeek: [1, 2, 3, 4, 5], timeStart: nil, timeEnd: nil, minRateCents: 9_500, shiftTypes: [.fill_in, .half_day], notifyChannels: [.email], paused: false)
        ]
    }

    private static func makeShifts() -> [Shift] {
        [
            Shift(id: SeedIDs.shiftBayviewPosted, practiceId: SeedIDs.bayviewPractice, startsAt: date(2026, 6, 3, 9, 0), endsAt: date(2026, 6, 3, 17, 0), lunchMinutes: 30, type: .fill_in, rateCentsPerHour: 12_000, bumpRateCentsPerHour: nil, bumpRadiusMeters: nil, servicesNeeded: ["Comprehensive exams", "Contacts"], notesForOd: "Tech performs pretesting. EHR is Eyefinity.", visibility: .public, status: .posted, urgent: true, bookedApplicationId: nil, postedAt: date(2026, 5, 28, 13, 0)),
            Shift(id: SeedIDs.shiftOaklandPosted, practiceId: SeedIDs.oaklandPractice, startsAt: date(2026, 6, 5, 8, 30), endsAt: date(2026, 6, 5, 16, 30), lunchMinutes: 60, type: .fill_in, rateCentsPerHour: 11_500, bumpRateCentsPerHour: nil, bumpRadiusMeters: nil, servicesNeeded: ["Dry eye", "Comprehensive exams"], notesForOd: "Parking validated in the garage.", visibility: .public, status: .posted, urgent: false, bookedApplicationId: nil, postedAt: date(2026, 5, 24, 10, 0)),
            Shift(id: SeedIDs.shiftCampbellPosted, practiceId: SeedIDs.campbellPractice, startsAt: date(2026, 6, 7, 10, 0), endsAt: date(2026, 6, 7, 15, 0), lunchMinutes: 0, type: .weekend, rateCentsPerHour: 13_000, bumpRateCentsPerHour: 14_000, bumpRadiusMeters: 40_000, servicesNeeded: ["Contacts"], notesForOd: "High-volume contact lens refits.", visibility: .public, status: .posted, urgent: false, bookedApplicationId: nil, postedAt: date(2026, 5, 25, 12, 0)),
            Shift(id: SeedIDs.shiftBooked, practiceId: SeedIDs.bayviewPractice, startsAt: date(2026, 6, 10, 9, 0), endsAt: date(2026, 6, 10, 17, 0), lunchMinutes: 30, type: .fill_in, rateCentsPerHour: 12_500, bumpRateCentsPerHour: nil, bumpRadiusMeters: nil, servicesNeeded: ["Medical optometry"], notesForOd: "Booked with Maya.", visibility: .public, status: .booked, urgent: false, bookedApplicationId: SeedIDs.appMayaBooked, postedAt: date(2026, 5, 22, 9, 0)),
            Shift(id: SeedIDs.shiftCompleted, practiceId: SeedIDs.oaklandPractice, startsAt: date(2026, 5, 20, 9, 0), endsAt: date(2026, 5, 20, 17, 0), lunchMinutes: 30, type: .fill_in, rateCentsPerHour: 11_000, bumpRateCentsPerHour: nil, bumpRadiusMeters: nil, servicesNeeded: ["Comprehensive exams"], notesForOd: nil, visibility: .public, status: .completed, urgent: false, bookedApplicationId: nil, postedAt: date(2026, 5, 1, 9, 0))
        ]
    }

    private static func makeApplications() -> [Application] {
        [
            Application(id: SeedIDs.appYaraBayview, shiftId: SeedIDs.shiftBayviewPosted, odId: SeedIDs.yaraOD, source: .apply, message: "I can cover the full day and have Eyefinity experience.", status: .applied, createdAt: date(2026, 5, 28, 16, 0)),
            Application(id: SeedIDs.appMayaBooked, shiftId: SeedIDs.shiftBooked, odId: SeedIDs.mayaOD, source: .watch_alert, message: "Happy to cover this Bayview day.", status: .accepted, createdAt: date(2026, 5, 22, 10, 0))
        ]
    }

    private static func makeBookings() -> [Booking] {
        [
            Booking(id: SeedIDs.bookingMaya, shiftId: SeedIDs.shiftBooked, odId: SeedIDs.mayaOD, practiceId: SeedIDs.bayviewPractice, applicationId: SeedIDs.appMayaBooked, contractId: SeedIDs.contractMaya, totalCents: 94_749, platformFeeCents: matchFeeCents, status: .confirmed, checkInAt: nil, checkOutAt: nil, cancellationReason: nil, cancellationFeeCents: nil, paymentStatus: "authorized"),
            Booking(id: SeedIDs.bookingCompleted, shiftId: SeedIDs.shiftCompleted, odId: SeedIDs.mayaOD, practiceId: SeedIDs.oaklandPractice, applicationId: SeedIDs.appMayaBooked, contractId: SeedIDs.contractCompleted, totalCents: 83_499, platformFeeCents: matchFeeCents, status: .completed, checkInAt: date(2026, 5, 20, 8, 55), checkOutAt: date(2026, 5, 20, 17, 5), cancellationReason: nil, cancellationFeeCents: nil, paymentStatus: "paid")
        ]
    }

    private static func makeContracts() -> [Contract] {
        [
            Contract(id: SeedIDs.contractMaya, bookingId: SeedIDs.bookingMaya, templateVersion: "mock-v1", bodyText: "NotifEyes fill-in OD agreement for Bayview Eye Care and Dr. Maya Patel.", signedByPracticeAt: date(2026, 5, 22, 11, 0), signedByOdAt: nil),
            Contract(id: SeedIDs.contractCompleted, bookingId: SeedIDs.bookingCompleted, templateVersion: "mock-v1", bodyText: "Completed Oakland Optometry Group coverage agreement.", signedByPracticeAt: date(2026, 5, 1, 12, 0), signedByOdAt: date(2026, 5, 1, 13, 0))
        ]
    }

    private static func makePayouts() -> [Payout] {
        [
            Payout(id: SeedIDs.payoutMaya, bookingId: SeedIDs.bookingCompleted, odId: SeedIDs.mayaOD, amountCents: 82_500, status: .sent, scheduledFor: date(2026, 5, 22, 12, 0), sentAt: date(2026, 5, 22, 9, 0))
        ]
    }

    private static func makeReviews() -> [Review] {
        [
            Review(id: SeedIDs.reviewMaya, bookingId: SeedIDs.bookingCompleted, authorRole: .practice, ratingOverall: 5, ratingSpecifics: ["communication": 5, "clinical": 5], publicComment: "Maya was excellent with patients and kept the schedule moving.", privateFeedback: nil, publishedAt: date(2026, 5, 21, 14, 0))
        ]
    }

    private static func makeThreads() -> [MessageThread] {
        [
            MessageThread(id: SeedIDs.threadBooking, contextBookingId: SeedIDs.bookingMaya, contextShiftId: SeedIDs.shiftBooked, lastMessageAt: date(2026, 5, 26, 15, 0)),
            MessageThread(id: SeedIDs.threadBayviewShift, contextBookingId: nil, contextShiftId: SeedIDs.shiftBayviewPosted, lastMessageAt: date(2026, 5, 28, 16, 15))
        ]
    }

    private static func makeMessages() -> [Message] {
        [
            Message(id: SeedIDs.messageOne, threadId: SeedIDs.threadBooking, senderUserId: SeedIDs.bayviewUser, body: "Contract is ready when you have a moment.", createdAt: date(2026, 5, 26, 14, 45), systemKind: nil),
            Message(id: SeedIDs.messageTwo, threadId: SeedIDs.threadBooking, senderUserId: SeedIDs.mayaUser, body: "Thanks, I will review it today.", createdAt: date(2026, 5, 26, 15, 0), systemKind: nil),
            Message(id: SeedIDs.messageThree, threadId: SeedIDs.threadBayviewShift, senderUserId: SeedIDs.yaraUser, body: "I am available for the June 3 coverage day.", createdAt: date(2026, 5, 28, 16, 15), systemKind: nil)
        ]
    }

    private static func makeNotifications() -> [AppNotification] {
        [
            AppNotification(id: SeedIDs.notificationMaya, userId: SeedIDs.mayaUser, kind: .shift_reminder, payload: ["bookingId": SeedIDs.bookingMaya.uuidString], actionUrl: "/bookings/\(SeedIDs.bookingMaya.uuidString)", readAt: nil, createdAt: date(2026, 5, 29, 9, 0)),
            AppNotification(id: SeedIDs.notificationBayview, userId: SeedIDs.bayviewUser, kind: .new_applicant, payload: ["shiftId": SeedIDs.shiftBayviewPosted.uuidString, "applicationId": SeedIDs.appYaraBayview.uuidString], actionUrl: "/shifts/\(SeedIDs.shiftBayviewPosted.uuidString)", readAt: nil, createdAt: date(2026, 5, 28, 16, 1))
        ]
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
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
