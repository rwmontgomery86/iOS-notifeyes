# NotifEyes iOS — Build Brief (mock-data shell / MVP)

> **Audience:** the coding agent (Codex) building the first iOS app for NotifEyes.
> This document is self-contained — you do not need access to the web repo to
> build the shell. When you spin up the `notifeyes-ios` repo, copy this file in
> as `AGENTS.md`. The companion file [`api-contract.md`](./api-contract.md)
> describes the *future* backend; you do **not** need it for the shell (mock
> data only), but read its "Cross-cutting rules" so your model shapes match.

---

## 0. TL;DR — what you're building

A **native SwiftUI iOS app** for NotifEyes, a two-sided optometry staffing
marketplace. This first deliverable is a **UI shell on mock data**: fully
navigable, demoable in the simulator, **no network calls**. It covers **both**
sides of the marketplace — Optometrists ("ODs") and Practices — with a demo
role-switcher.

The single most important architectural rule: **all data flows through one
protocol (`NotifEyesAPI`)**. Today a `MockAPI` (in-memory store) conforms to it.
Later, a `LiveAPI` (real HTTP) will conform to the same protocol and the app
swaps over by changing **one line**. Build every screen against the protocol,
never against the mock store directly.

**Do not** add third-party dependencies, real auth, real networking, push
notifications, or a real map geocoder. Those are out of scope (see §2).

---

## 1. Product context

Practices post short-notice **fill-in shifts** (a clinic needs an OD for a day).
ODs draw a geographic **watch zone** on a map; when a practice posts a shift that
matches the zone's area + filters, the OD is **alerted within ~10 seconds**, taps
the notification, views the shift, and **applies**. The practice reviews
applicants, **books** one, both **sign a contract**, the OD **checks in/out** on
the day, then both leave **reviews** and the OD gets **paid**.

**The signature loop you must make feel real on mock data:**

```
Practice posts a shift  →  it matches an OD's watch zone  →
OD gets a "watch_match" notification (live, across tabs)  →
OD taps it  →  Shift detail  →  Apply  →
the application shows up in the Practice's Applicants list
```

This loop is the demo's money shot. Build it end-to-end early (phase 2).

---

## 2. Constraints & decisions (locked — do not relitigate)

| Topic | Decision |
|---|---|
| Language / UI | **Swift 5.9+, SwiftUI**, Observation (`@Observable`) |
| Min OS | **iOS 17.0** (needed for `@Observable`, `MapCircle`, `MapPolygon`) |
| Data | **Mock only.** In-memory store. No network, no persistence required. |
| Sides | **Both** OD and Practice, plus a demo role-switcher (no real auth) |
| Dependencies | **Zero third-party.** SwiftUI + MapKit + Swift Concurrency only. |
| Maps | **MapKit** (native, no API key) |
| Push | **Deferred.** Alerts come from mock data; **no APNs**. |
| Money | Integer **cents** everywhere (`typealias Cents = Int`). Never `Double`. |
| The seam | Every screen depends on the `NotifEyesAPI` protocol, never on `MockStore`. |

**Demo personas** (the role-switcher exposes exactly these three):
- **Maya Patel** — verified OD
- **Yara Brennan** — pending (unverified) OD
- **Bayview Eye Care (owner)** — practice

---

## 3. Project setup

- Create a standard Xcode **App** project (SwiftUI lifecycle), single target
  `NotifEyes`, plus a unit-test target. Not a Swift Package for the app itself.
- No `Package.swift` dependencies. If you ever feel you need one, stop and leave
  a `// NEEDS-DECISION:` comment instead of adding it.
- Group/folder layout (groups mirror folders on disk):

```
NotifEyes/
  App/            NotifEyesApp.swift, RootView.swift, AppEnvironment.swift
  Models/         User, Practice, Optometrist, WatchZone, Shift, Application,
                  Booking, Contract, Payout, Review, Messaging, AppNotification,
                  Enums, Money, Geo
  API/            NotifEyesAPI.swift, DTOs.swift, APIError.swift
    Mock/         MockAPI.swift, MockStore.swift, SeedData.swift
    Live/         LiveAPI.swift   (stub — every method throws .notImplemented)
  Session/        SessionStore.swift
  Navigation/     Route.swift, Router.swift, DeepLink.swift
  Features/
    OD/           Shifts/, Watch/, Payouts/, ODProfile/
    Practice/     Dashboard/, PostShift/, Billing/, PracticeSettings/
    Shared/       Notifications/, Messages/, ShiftDetail/, BookingDetail/,
                  ODPublicProfile/, PracticePublicProfile/, Review/
  Components/     MoneyText, StatusBadge, RatingStars, AvatarView,
                  EmptyStateView, ShiftCard, ChannelChips, SectionCard
  Map/            WatchZoneMap.swift, ZoneDrawController.swift,
                  GeometryMeta+MapKit.swift
  Support/        Formatters, Date+Shift, Color+Theme, Haptics
  Resources/      Assets.xcassets
```

`Models/` and `API/` must **not** import SwiftUI or MapKit — keep them portable
and testable.

---

## 4. Architecture

**Pattern: MV with an `@Observable` store (observable-store), not full MVVM.**

- **`actor MockStore`** is the single source of truth: it holds the arrays of
  entities and all mutation methods. Being an `actor` serializes mutations and
  prevents data races when multiple tabs touch the same data.
- **`@Observable final class AppEnvironment`** holds the `api: NotifEyesAPI` and
  is injected through the SwiftUI `Environment`. `SessionStore` and per-tab
  `Router` are also `@Observable` and injected.
- Views are thin: they read already-shaped data and call `async` methods on
  `env.api`. Use a small **local** `@Observable` "screen model" only where a form
  needs validation/derived state (e.g. Post-a-shift). Don't make one per screen.
- View-facing observable classes are `@MainActor`. All `NotifEyesAPI` methods are
  `async throws`.

```swift
@main
struct NotifEyesApp: App {
    @State private var env = AppEnvironment(api: MockAPI())   // ← the swap point
    var body: some Scene {
        WindowGroup { RootView().environment(env) }
    }
}
```

No Redux/TCA, no Combine, no coordinator framework, no DI container —
SwiftUI's `Environment` *is* the DI container.

---

## 5. The API seam (build this first, in phase 0)

One umbrella protocol composed of per-domain protocols. **Every screen depends on
this, never on `MockStore`.** Every method `async throws`; every parameter and
return type is a value type from `Models/` or `DTOs.swift`. **Nothing from
SwiftUI/MapKit and no mock internals cross this boundary.**

```swift
protocol NotifEyesAPI:
    SessionAPI, ShiftsAPI, WatchZonesAPI, ApplicationsAPI, BookingsAPI,
    MessagingAPI, NotificationsAPI, ProfilesAPI, PayoutsAPI, ReviewsAPI, BillingAPI {}

// --- Session / auth (mock returns seeded users; Live does bearer-token login) ---
protocol SessionAPI {
    func signIn(email: String, password: String) async throws -> Session
    func currentSession() async throws -> Session?
    func signOut() async throws
    func switchDemoActor(to actor: DemoActor) async throws -> Session   // DEMO ONLY — not in LiveAPI
}

// --- Shifts ---
protocol ShiftsAPI {
    func browseShifts(filter: ShiftFilter) async throws -> [ShiftSummary]        // OD: posted/public
    func shift(id: Shift.ID) async throws -> ShiftDetail                          // aggregated read-model
    func shiftsForPractice(_ id: Practice.ID, status: ShiftStatus?) async throws -> [ShiftSummary]
    func createShift(_ input: CreateShiftInput) async throws -> Shift
    func updateShiftStatus(_ id: Shift.ID, to: ShiftStatus) async throws -> Shift // post / cancel
    func applicants(for id: Shift.ID) async throws -> [ApplicantSummary]
}

// --- Watch zones (the differentiator) ---
protocol WatchZonesAPI {
    func watchZones(for od: Optometrist.ID) async throws -> [WatchZone]
    func createWatchZone(_ input: CreateWatchZoneInput) async throws -> WatchZone
    func updateWatchZone(_ id: WatchZone.ID, _ input: UpdateWatchZoneInput) async throws -> WatchZone
    func setWatchZonePaused(_ id: WatchZone.ID, paused: Bool) async throws -> WatchZone
    func deleteWatchZone(_ id: WatchZone.ID) async throws
    func simulateMatchingShift(for zone: WatchZone.ID) async throws -> AppNotification  // mock-only demo trigger
}

// --- Applications (the apply loop) ---
protocol ApplicationsAPI {
    func apply(to shift: Shift.ID, message: String?, source: ApplicationSource) async throws -> Application
    func myApplications(od: Optometrist.ID) async throws -> [Application]
    func respondToInvite(_ id: Application.ID, accept: Bool) async throws -> Application
    func updateApplicationStatus(_ id: Application.ID, to: ApplicationStatus) async throws -> Application
}

// --- Bookings ---
protocol BookingsAPI {
    func booking(id: Booking.ID) async throws -> BookingDetail                    // aggregated read-model
    func myBookings(role: SessionRole, subjectId: UUID) async throws -> [BookingSummary]
    func bookApplicant(_ application: Application.ID) async throws -> Booking      // practice confirms
    func signContract(booking: Booking.ID, as role: SessionRole) async throws -> Contract
    func checkIn(booking: Booking.ID) async throws -> Booking
    func checkOut(booking: Booking.ID) async throws -> Booking
    func cancelBooking(_ id: Booking.ID, reason: String) async throws -> Booking
}

// --- Messaging ---
protocol MessagingAPI {
    func threads(for user: User.ID) async throws -> [ThreadSummary]
    func messages(in thread: MessageThread.ID) async throws -> [Message]
    func sendMessage(thread: MessageThread.ID, body: String) async throws -> Message
    func startThread(withContextShift: Shift.ID?, participants: [User.ID]) async throws -> MessageThread
    func markThreadRead(_ id: MessageThread.ID, by user: User.ID) async throws
}

// --- Notifications (alert → shift → apply) ---
protocol NotificationsAPI {
    func notifications(for user: User.ID) async throws -> [AppNotification]
    func markRead(_ id: AppNotification.ID) async throws
    func markAllRead(for user: User.ID) async throws
    func unreadCount(for user: User.ID) async throws -> Int
    func notificationStream(for user: User.ID) -> AsyncStream<AppNotification>     // mock analog of web SSE
}

// --- Profiles ---
protocol ProfilesAPI {
    func optometrist(id: Optometrist.ID) async throws -> Optometrist
    func practice(id: Practice.ID) async throws -> Practice
    func updateODProfile(_ id: Optometrist.ID, _ input: UpdateODInput) async throws -> Optometrist
    func updatePractice(_ id: Practice.ID, _ input: UpdatePracticeInput) async throws -> Practice
}

// --- Payouts (OD) + Billing (practice) ---
protocol PayoutsAPI { func payouts(for od: Optometrist.ID) async throws -> [Payout] }
protocol BillingAPI { func invoices(for practice: Practice.ID) async throws -> [BillingLine] }

// --- Reviews ---
protocol ReviewsAPI {
    func review(forBooking id: Booking.ID, role: ReviewAuthor) async throws -> Review?
    func submitReview(_ input: SubmitReviewInput) async throws -> Review
}
```

**Aggregated read-models** (`ShiftDetail`, `BookingDetail`, `ApplicantSummary`,
`ShiftSummary`, `ThreadSummary`, `BookingSummary`, `BillingLine`) are
view-tier types that pre-join what a screen needs (e.g. `ShiftDetail` = the shift
+ its practice + a cost breakdown + the viewer's existing application, if any).
The mock builds these by joining store arrays; the future `LiveAPI` returns them
as one JSON payload per screen. This keeps screens free of client-side joins.

`APIError` (in `API/APIError.swift`):
```swift
enum APIError: Error { case notImplemented, notFound, invalid(String), unauthorized }
```

`LiveAPI` is checked in now as a **stub** whose every method is
`throw APIError.notImplemented` — so the seam is visibly two-sided and greppable
from day one. Do not implement it.

---

## 6. Domain models (`Models/`)

Mirror these as Swift value types. They come from the production Postgres schema —
match field names and especially **enum raw values** (snake_case) so a future
`Codable` `LiveAPI` decodes without a translation layer. Use
`Identifiable` with `let id: UUID` (typealias `Shift.ID = UUID`, etc.). Money
fields are `Cents` (= `Int`). Timestamps are `Date`.

**Enums (`Models/Enums.swift`)** — string-backed, raw values exactly as shown:

```swift
enum UserRole: String, Codable { case practice_owner, practice_scheduler, od, admin }
enum ShiftType: String, Codable { case fill_in, half_day, weekend, recurring, permanent }
enum ShiftStatus: String, Codable { case draft, posted, booked, completed, cancelled }
enum ShiftVisibility: String, Codable { case `public`, favorites, invite_only }
enum ApplicationSource: String, Codable { case apply, invite, watch_alert }
enum ApplicationStatus: String, Codable { case applied, shortlisted, offered, accepted, declined, withdrawn }
enum BookingStatus: String, Codable { case confirmed, in_progress, completed, cancelled, no_show }
enum PayoutStatus: String, Codable { case scheduled, sent, failed }
enum WatchZoneShape: String, Codable { case circle, polygon }
enum ReviewAuthor: String, Codable { case practice, od }
enum VerificationStatus: String, Codable { case pending, verified, rejected }
enum Channel: String, Codable { case push, email, sms }
enum NotificationKind: String, Codable {
    case watch_match, invite_received, new_applicant, booking_confirmed,
         shift_reminder, cancellation, no_show_check, payout_sent,
         review_request, credential_expiring, verification_decided, message_received
}
```

**Geo (`Models/Geo.swift`)** — the `geometryMeta` shape is the most important
shared contract; replicate it exactly:

```swift
struct LatLng: Codable, Hashable { let lat: Double; let lng: Double }

enum GeometryMeta: Codable, Hashable {       // discriminated union, key "kind"
    case circle(centerLat: Double, centerLng: Double, radiusMeters: Double)
    case polygon(points: [LatLng])
}
```

**Core entities** (fields trimmed to what screens use; keep the names):

- `User` — id, email, role: `UserRole`, name?, practiceId: `Practice.ID?`, odId: `Optometrist.ID?`, phone?, emailOptedIn, smsOptedIn.
- `Practice` — id, name, dba?, bio?, addressLine?, city?, state?, zip?, location: `LatLng?`, services: [String], languages: [String], ratingAvg: Double?, ratingCount, shiftsCompleted, businessLicenseVerified, paymentMethodVerified.
- `Optometrist` — id, name, displayName?, bio?, headshotUrl?, homeLocation: `LatLng?`, travelRadiusMi, licenseState?, verificationStatus: `VerificationStatus`, specialties: [String], ehrExperience: [String], ratingAvg: Double?, ratingCount, shiftsCompleted, noShowCount.
- `WatchZone` — id, odId, name, shape: `WatchZoneShape`, geometryMeta: `GeometryMeta`, daysOfWeek: [Int] (0=Sun…6=Sat), timeStart: String? ("HH:MM"), timeEnd: String?, minRateCents: `Cents`, shiftTypes: [ShiftType], notifyChannels: [Channel], paused: Bool.
- `Shift` — id, practiceId, startsAt, endsAt, lunchMinutes, type: `ShiftType`, rateCentsPerHour: `Cents`, bumpRateCentsPerHour: `Cents?`, bumpRadiusMeters: Int?, servicesNeeded: [String], notesForOd?, visibility: `ShiftVisibility`, status: `ShiftStatus`, urgent: Bool, bookedApplicationId: `Application.ID?`, postedAt: Date?.
- `Application` — id, shiftId, odId, source: `ApplicationSource`, message?, status: `ApplicationStatus`, createdAt.
- `Booking` — id, shiftId, odId, practiceId, applicationId, contractId?, totalCents: `Cents`, platformFeeCents: `Cents`, status: `BookingStatus`, checkInAt: Date?, checkOutAt: Date?, cancellationReason?, cancellationFeeCents: `Cents?`, paymentStatus: String.
- `Contract` — id, bookingId, templateVersion, bodyText, signedByPracticeAt: Date?, signedByOdAt: Date?.
- `Payout` — id, bookingId, odId, amountCents: `Cents`, status: `PayoutStatus`, scheduledFor, sentAt: Date?.
- `Review` — id, bookingId, authorRole: `ReviewAuthor`, ratingOverall: Int (1–5), ratingSpecifics: [String:Int], publicComment?, privateFeedback?, publishedAt: Date?.
- `MessageThread` — id, contextBookingId?, contextShiftId?, lastMessageAt: Date?.
- `Message` — id, threadId, senderUserId?, body, createdAt, systemKind?.
- `AppNotification` — id, userId, kind: `NotificationKind`, payload: [String:String] (mock-simplified), actionUrl: String?, readAt: Date?, createdAt.
- `Session` — user: `User`, role: `SessionRole`. (`SessionRole` is a 2-case view of role: `.od` / `.practice`.)

---

## 7. Navigation & routing

- **`RootView`** reads `SessionStore.role` → renders `ODTabView` or
  `PracticeTabView`. Switching personas rebuilds the tab tree (cheap & correct).
- **Tab labels** (use verbatim):
  - **OD:** Browse shifts · Watch zones · Notifications · Messages · Payouts · My profile
  - **Practice:** Dashboard · Post a shift · Messages · Notifications · Billing · Practice settings
  - Notifications & Messages tabs show an unread `.badge(count)`.
- **Per-tab `NavigationStack`** + a global `Route` enum resolved by a single
  `.navigationDestination(for: Route.self)`:

```swift
enum Route: Hashable {
    case shiftDetail(Shift.ID)
    case bookingDetail(Booking.ID)
    case odProfile(Optometrist.ID)
    case practiceProfile(Practice.ID)
    case messageThread(MessageThread.ID)
    case review(Booking.ID)
    case applicants(Shift.ID)
    case watchZoneEditor(WatchZone.ID?)   // nil = create
}

@Observable final class Router { var path = NavigationPath() }
```

- **Deep-link the alert loop:** `AppNotification.actionUrl` is a path like
  `/shifts/123` (this matches what the real backend stores). `DeepLink.parse(_:)`
  maps such a string → `Route`. Tapping a notification appends the parsed route to
  the active tab's path. The "simulate matching shift" demo action emits an
  `AppNotification` through `notificationStream`; a root-level listener shows an
  in-app banner; tapping the banner deep-links straight to the new shift.
- **Demo role-switcher:** a toolbar menu on each root listing the three personas;
  selecting one calls `switchDemoActor` and updates `SessionStore`.

---

## 8. Screen inventory

`[I]` = interactive (mutates mock state), `[R]` = read-only.

### OD tabs
- **Browse shifts** `[I]` — list + `WatchZoneMap` of posted shifts (pins) with the
  OD's zones overlaid; filter bar (min rate, type, distance). Reads `[ShiftSummary]`
  + `[WatchZone]`. Row/pin tap → Shift detail. Provide a list/map toggle.
- **Watch zones** `[I]` — list of the OD's zones with a pause toggle, delete, and a
  "New zone" button (→ Watch-zone editor). Reads `[WatchZone]`.
- **Notifications** `[I]` — feed of `[AppNotification]`; tap → deep-link via
  `actionUrl`; mark read / mark all read. Good home for the "Simulate a matching
  shift" demo button.
- **Messages** `[I]` — thread list (`[ThreadSummary]`); tap → Message thread.
- **Payouts** `[R]` — `[Payout]` grouped by status with totals (cents).
- **My profile** `[I]` — editable OD: bio, travel radius, specialties, license +
  verification badge, notify channels. Reads `Optometrist`; saves via `updateODProfile`.

### Practice tabs
- **Dashboard** `[I]` — upcoming/active bookings + open shifts with applicant
  counts + headline stats. Reads `[ShiftSummary]` + `[BookingSummary]`; rows
  deep-link to Shift detail / Applicants / Booking detail.
- **Post a shift** `[I]` — form (date/time, type, rate, optional bump, services,
  notes, urgent) with a **live cost preview** (port `computeShiftCost`, §11). On
  submit: `createShift` then `updateShiftStatus(.posted)`. The posted shift then
  appears in Browse and can trigger a watch match.
- **Messages** `[I]` — same as OD.
- **Notifications** `[I]` — same component (practice-relevant kinds:
  `new_applicant`, `booking_confirmed`, `review_request`).
- **Billing** `[R]` — `[BillingLine]` derived from the practice's bookings
  (subtotal, platform fee, total — all cents).
- **Practice settings** `[I]` — editable practice: name, bio, services, address.
  Reads `Practice`; saves via `updatePractice`.

### Shared detail screens
- **Shift detail** `/shifts/[id]` `[I]` — shift + practice header, cost breakdown,
  services, notes. OD viewer: **Apply** (appends an `Application`, `source:
  .apply`) or **Accept/Decline** if invited. Practice-owner viewer: route to
  Applicants. Reads `ShiftDetail`.
- **Applicants** `[I]` — applicant list with shortlist/offer/book actions + an
  "Invite OD" panel. Reads `[ApplicantSummary]`. Booking an applicant creates a
  `Booking` + `Contract` → Booking detail.
- **Booking detail** `/bookings/[id]` `[I]` — contract sign (both roles),
  check-in / check-out, cancel. Reads `BookingDetail`. Buttons are state-driven
  (confirmed → in_progress → completed).
- **OD public profile** `/ods/[id]` `[R]` — name, bio, specialties, rating,
  shiftsCompleted, verification badge.
- **Practice public profile** `/practices/[id]` `[R]` — name, bio, services,
  rating, stats, address (small map).
- **Review** `/reviews/[bookingId]` `[I]` — star rating + public comment; submit.
- **Message thread** `/messages/[threadId]` `[I]` — message list + composer;
  `sendMessage` appends + bumps the thread; `markThreadRead` clears the badge.
- **Watch-zone editor** (modal) `[I]` — the MapKit screen (§10); create/update a zone.

### Auth/demo
- **Sign-in / demo picker** `[I]` — minimal: pick a seeded persona (no real auth);
  sets the session.

---

## 9. Mock data & store

- **`SeedData.makeSeed() -> StoreState`** — deterministic seed mirroring the web
  dev seed: ~5 Bay Area practices with real coordinates, ~6–8 ODs (mix of
  `verified` plus one `pending` = Yara), a handful of `posted` shifts, a couple of
  existing applications/bookings/contracts/payouts/reviews, threads with messages,
  and a per-user notifications feed. Use the three demo personas by name (Maya,
  Yara, Bayview owner). Real Bay Area anchor: SF center `37.7749, -122.4194`;
  example practice coords — Bayview Eye Care `37.7849, -122.4444` (SF), Oakland
  Optometry Group `37.8268, -122.2632`, a South Bay practice near Campbell.
- **`actor MockStore`** holds the arrays + the mutation methods. Reads project
  store rows into the aggregated read-models. Mutations update the arrays and,
  where relevant, **emit an `AppNotification` into the affected user's
  `AsyncStream`** so the UI updates live across tabs (mock analog of the web's
  LISTEN/NOTIFY → SSE). Keep a `[User.ID: AsyncStream<AppNotification>.Continuation]`.
- **Mutations that must visibly land:** apply (appends `Application` + emits
  `new_applicant` to the practice), create watch zone (shows in list + on map),
  sign contract (flips the signed flag + advances button state), check-in/out
  (advances booking status), send message (appends + bumps thread + badge),
  `simulateMatchingShift` (inserts a fresh posted shift + emits a `watch_match`
  whose `actionUrl` deep-links to it).

---

## 10. MapKit watch-zone screen

**Render (read):** a SwiftUI `Map` with a content builder:
- **circle** zone → `MapCircle(center:radius:)` (radius in meters straight from
  `geometryMeta.radiusMeters`), tinted fill + stroke.
- **polygon** zone → `MapPolygon(coordinates:)` from `geometryMeta.points`.
- **shift pins** → `Annotation`/`Marker` at each shift's practice `LatLng`, tap →
  Shift detail.
- `GeometryMeta+MapKit.swift` converts `GeometryMeta` ↔ MapKit overlays and
  computes a framing `MKCoordinateRegion`.

**"Draw a zone" interaction (faked, but data-identical).** Mirror the web's
primary mode — center + radius slider:
1. Tap the map to drop/move the center. (ZIP search optional: a small **bundled
   lookup table** in `SeedData`, no network.)
2. A **radius slider, 1–100 mi, default 25**, drives a live `MapCircle`.
   Conversion: `radiusMeters = miles * 1609.344`.
3. Field set identical to the web editor: name (default "My zone"), min rate
   (default $100/hr → `minRateCents`), days-of-week chips (default all seven:
   `[1,2,3,4,5,6,0]`), optional earliest-start / latest-end time ("HH:MM"),
   shift-type chips (`fill_in`, `half_day`, `weekend`; default all three),
   notify-channel toggles (default `[.push, .email]`; `sms` shown but
   disabled-by-default).
4. Save builds **exactly** `GeometryMeta.circle(centerLat, centerLng,
   radiusMeters)` and calls `createWatchZone`.

Polygon **creation** is out of scope for the shell (we still **render** seeded
polygons). Circle-only creation is acceptable because the persisted shape is
identical and circle-by-radius is the web's primary path.

---

## 11. Money & formatting (`Support/`)

Port these two web helpers verbatim so previews match the web exactly:

```swift
typealias Cents = Int

func formatUsd(_ cents: Cents) -> String {            // Intl currency equivalent
    let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "USD"
    return f.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
}

// hours = max(0, (end - start - lunch) / 1h); subtotal = round(rate * hours)
// sameDay = urgent || (start - confirmed) <= 24h
// fee = sameDay ? sameDayFee : matchFee     (mock constants: $9.99 / $19.99)
// total = subtotal + fee ; odPayout = subtotal
struct ShiftCost { let hours: Double; let subtotalCents, feeCents, totalCents, odPayoutCents: Cents; let sameDay: Bool }
func computeShiftCost(rateCentsPerHour: Cents, startsAt: Date, endsAt: Date,
                      lunchMinutes: Int, urgent: Bool, confirmedAt: Date = .now) -> ShiftCost
```

Mock fee constants: `matchFeeCents = 999`, `sameDayFeeCents = 1999`, same-day
threshold = 24h. (The real values come from server env later; these match the web
defaults.) **Never use `Double` for stored money** — only transiently inside
`formatUsd`/`computeShiftCost`.

---

## 12. Build phases (a runnable app at every step)

**Phase 0 — Scaffold + seam.** Xcode project; `Models/` (structs + enums + Geo +
Money); `NotifEyesAPI` + `DTOs` + `APIError`; `MockStore` + `SeedData`; `MockAPI`;
`LiveAPI` stub; `AppEnvironment` injection; `SessionStore` + demo picker. App
launches to a placeholder.

**Phase 1 — Navigation skeleton.** `RootView` role router; both `TabView`s with all
six tabs each (placeholder screens); `Route` + per-tab `Router` +
`navigationDestination`; demo role-switcher working; `DeepLink.parse`.

**Phase 2 — OD core loop (do this first after nav — it's the demo).** Browse shifts
(list + `WatchZoneMap`); Watch-zone editor (circle-by-radius); Notifications feed +
`AsyncStream` banner; Shift detail + Apply; the full **simulate-match →
notification → deep-link → apply** loop.

**Phase 3 — Practice core loop.** Dashboard; Post-a-shift (+ live cost preview);
Applicants; book applicant → Booking + Contract.

**Phase 4 — Shared detail + transactional.** Booking detail (sign / check-in /
check-out / cancel); Review; Message thread + composer; OD/Practice public
profiles; Payouts; Billing; profile/settings editors.

**Phase 5 — Polish.** Empty states, badges, haptics, status-badge colors, accent
theming, loading/refresh, accessibility labels, light/dark.

---

## 13. Definition of done

The shell is done when, in the iOS simulator:
- Both role tab-trees render and every tab + detail screen navigates.
- The demo role-switcher swaps among Maya / Yara / Bayview.
- The watch-zone editor saves a circle zone that then renders on the map.
- The signature loop works on mock data end-to-end: posting a shift as Bayview →
  switching to Maya → seeing the `watch_match` banner → tapping → Shift detail →
  Apply → switching back to Bayview → the application appears under Applicants.
- No third-party dependencies; no network calls; builds clean.

---

## 14. When the real backend lands (future, not now)

The web side will publish `/api/mobile/*` JSON endpoints + a bearer-token auth
endpoint matching [`api-contract.md`](./api-contract.md). At that point someone
writes `LiveAPI` to conform to `NotifEyesAPI` (URLSession + Codable + Keychain
token storage) and changes **one line** in `NotifEyesApp.swift`
(`MockAPI()` → `LiveAPI(baseURL:)`). Because your models use the snake_case enum
raw values and the exact `geometryMeta` / `actionUrl` shapes above, decoding will
line up with no model rewrites. Keep the seam clean and that swap stays trivial.

---

## Appendix — quick reference

- **NotificationKind (12):** watch_match, invite_received, new_applicant,
  booking_confirmed, shift_reminder, cancellation, no_show_check, payout_sent,
  review_request, credential_expiring, verification_decided, message_received.
- **Channels:** push, email, sms.
- **Day-of-week:** 0=Sun … 6=Sat (matches the web; the editor lists Mon-first but
  stores these ints).
- **Radius:** 1–100 mi, default 25; meters = miles × 1609.344.
- **Watch-zone defaults:** name "My zone"; minRate $100/hr; days all seven; shift
  types all three; channels push+email.
- **Demo personas:** Maya Patel (verified OD), Yara Brennan (pending OD), Bayview
  Eye Care owner (practice).
