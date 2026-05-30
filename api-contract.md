# NotifEyes Mobile API — Contract (v0, draft)

> **Status:** DRAFT / forward-looking. **None of these endpoints exist yet.**
> The iOS shell runs entirely on mock data; this document specifies what the web
> team (Claude) will build later as `/api/mobile/*` so the iOS `LiveAPI` can drop
> into the `NotifEyesAPI` seam with **zero view changes**. It is owned and
> versioned on the **web side**; a copy is mirrored into the `notifeyes-ios` repo.
>
> Why a dedicated layer at all: the web app is ~95% React Server Components +
> Server Actions and exposes only 5 JSON routes today. A native client cannot
> call Server Actions, so every screen below needs a real JSON endpoint. This
> contract defines them up front so the mock→real swap is one line.

---

## 0. Conventions (lock these — they make decode-without-translation work)

- **Base path:** `/api/mobile/v1`. Versioned so we can evolve without breaking
  shipped apps.
- **Money:** integer **cents** in every payload. No decimals, no strings, no
  `Double`. (`totalCents`, `rateCentsPerHour`, `minRateCents`, …)
- **Timestamps:** ISO-8601 UTC strings (`2026-05-30T17:00:00Z`). Swift decodes
  with `.iso8601`.
- **IDs:** UUID strings.
- **Enums:** the **snake_case** string values already used in the Postgres schema
  and the iOS `Models/Enums.swift` — e.g. `fill_in`, `watch_alert`, `no_show`,
  `practice_owner`. Send these verbatim so Swift `RawRepresentable` enums decode
  directly. (Full lists in §"Enum reference".)
- **Geometry:** `geometryMeta` is a discriminated union keyed on `kind`:
  `{ "kind": "circle", "centerLat": Double, "centerLng": Double, "radiusMeters": Double }`
  **or** `{ "kind": "polygon", "points": [ { "lat": Double, "lng": Double } ] }`.
  This is the single most load-bearing shared shape — **do not** change keys.
- **`actionUrl`:** notifications carry a **parseable path** (`/shifts/:id`,
  `/bookings/:id`, `/messages/:id`) so the iOS `DeepLink.parse` keeps working
  unchanged. Never a full URL, never an opaque token.
- **Errors:** non-2xx returns `{ "error": { "code": String, "message": String } }`.
  iOS maps `401 → APIError.unauthorized`, `404 → .notFound`, `400/422 → .invalid`.
- **Lists:** cursor pagination — `?cursor=&limit=` → `{ "items": [...], "nextCursor": String? }`.
  Endpoints below show the item shape; assume this envelope for list routes.
- **Auth:** every route except `POST /auth/token` requires
  `Authorization: Bearer <accessToken>`. The token's claims carry `userId`,
  `role`, `practiceId`, `odId` (same fields the web JWT already enriches).

---

## 1. Auth / session

Auth.js on the web is cookie/JWT-session based with **no bearer path**. For mobile
we add a parallel token endpoint that validates against the same `users` table +
bcrypt and signs a JWT with `AUTH_SECRET`.

| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/auth/token` | `{ email, password }` | `{ accessToken, expiresAt, user: User }` |
| GET | `/auth/session` | — | `{ user: User }` (validates the bearer token) |
| POST | `/auth/signout` | — | `204` (client just drops the token) |

- iOS stores `accessToken` in the **Keychain** (not UserDefaults). On `401`, clear
  it and bounce to sign-in. V1 token policy: long-lived (e.g. 30d), re-login on
  expiry; add refresh later if needed.
- `User` shape: `{ id, email, name?, role, practiceId?, odId?, phone?, emailOptedIn, smsOptedIn }`.
- `switchDemoActor` (in the iOS `SessionAPI`) is **mock-only** and has **no**
  endpoint here — `LiveAPI` simply won't implement it.

---

## 2. Endpoint groups (map 1:1 to the iOS protocols)

### Shifts (`ShiftsAPI`)
| iOS method | HTTP |
|---|---|
| `browseShifts(filter:)` | `GET /shifts?status=posted&type=&minRate=&nearLat=&nearLng=&radiusMi=&cursor=&limit=` → `[ShiftSummary]` |
| `shift(id:)` | `GET /shifts/:id` → **`ShiftDetail`** (aggregated: shift + practice + costBreakdown + `viewerApplication?`) |
| `shiftsForPractice(_:status:)` | `GET /practices/:id/shifts?status=` → `[ShiftSummary]` |
| `createShift(_:)` | `POST /shifts` (body `CreateShiftInput`) → `Shift` (status `draft`) |
| `updateShiftStatus(_:to:)` | `PATCH /shifts/:id` `{ status }` → `Shift` (`posted` enqueues fanout; `cancelled`) |
| `applicants(for:)` | `GET /shifts/:id/applicants` → `[ApplicantSummary]` (application + OD summary) |

`ShiftSummary`: id, practiceName, practiceId, startsAt, endsAt, type, rateCentsPerHour, bumpRateCentsPerHour?, status, urgent, location `LatLng?`, distanceMi?.
`ShiftDetail`: `shift: Shift`, `practice: Practice`, `cost: ShiftCost`, `viewerApplication: Application?`.

### Watch zones (`WatchZonesAPI`)
| iOS method | HTTP |
|---|---|
| `watchZones(for:)` | `GET /watch-zones` (scoped to the bearer's OD) → `[WatchZone]` |
| `createWatchZone(_:)` | `POST /watch-zones` (`CreateWatchZoneInput` incl. `geometryMeta`) → `WatchZone` |
| `updateWatchZone(_:_:)` | `PATCH /watch-zones/:id` (`UpdateWatchZoneInput`) → `WatchZone` |
| `setWatchZonePaused(_:paused:)` | `PATCH /watch-zones/:id` `{ paused }` → `WatchZone` |
| `deleteWatchZone(_:)` | `DELETE /watch-zones/:id` → `204` |
| `simulateMatchingShift(for:)` | **mock-only — no endpoint** |

`CreateWatchZoneInput`: name, geometryMeta, daysOfWeek:[Int], timeStart:String?, timeEnd:String?, minRateCents, shiftTypes:[ShiftType], notifyChannels:[Channel]. The server derives the queryable PostGIS `geometry` from `geometryMeta` (it already does this for the web action).

### Applications (`ApplicationsAPI`)
| iOS method | HTTP |
|---|---|
| `apply(to:message:source:)` | `POST /shifts/:id/applications` `{ message?, source }` → `Application` |
| `myApplications(od:)` | `GET /ods/:id/applications` → `[Application]` |
| `respondToInvite(_:accept:)` | `PATCH /applications/:id` `{ status: accepted|declined }` → `Application` |
| `updateApplicationStatus(_:to:)` | `PATCH /applications/:id` `{ status }` → `Application` (practice shortlist/offer) |

### Bookings (`BookingsAPI`)
| iOS method | HTTP |
|---|---|
| `booking(id:)` | `GET /bookings/:id` → **`BookingDetail`** (booking + shift + practice + od + contract + thread?) |
| `myBookings(role:subjectId:)` | `GET /bookings?role=&subjectId=` → `[BookingSummary]` |
| `bookApplicant(_:)` | `POST /applications/:id/book` → `Booking` (creates booking + contract + thread atomically) |
| `signContract(booking:as:)` | `POST /bookings/:id/contract/sign` `{ role }` → `Contract` |
| `checkIn(booking:)` | `POST /bookings/:id/check-in` → `Booking` |
| `checkOut(booking:)` | `POST /bookings/:id/check-out` → `Booking` |
| `cancelBooking(_:reason:)` | `POST /bookings/:id/cancel` `{ reason }` → `Booking` (server computes `cancellationFeeCents`) |

### Messaging (`MessagingAPI`)
| iOS method | HTTP |
|---|---|
| `threads(for:)` | `GET /threads` → `[ThreadSummary]` |
| `messages(in:)` | `GET /threads/:id/messages` → `[Message]` |
| `sendMessage(thread:body:)` | `POST /threads/:id/messages` `{ body }` → `Message` |
| `startThread(withContextShift:participants:)` | `POST /threads` `{ contextShiftId?, participants:[id] }` → `MessageThread` |
| `markThreadRead(_:by:)` | `POST /threads/:id/read` → `204` |

### Notifications (`NotificationsAPI`)
| iOS method | HTTP |
|---|---|
| `notifications(for:)` | `GET /notifications` → `[AppNotification]` |
| `markRead(_:)` | `PATCH /notifications/:id/read` → `204` |
| `markAllRead(for:)` | `POST /notifications/read-all` → `204` |
| `unreadCount(for:)` | `GET /notifications/unread-count` → `{ notifications, messages, total }` |
| `notificationStream(for:)` | `GET /notifications/stream` (SSE) — `event: notification`, `data: { userId, notificationId, kind }` |

The SSE endpoint **already exists** on the web (`/api/notifications/stream`).
`LiveAPI.notificationStream` backs the same `AsyncStream` signature with SSE; if
SSE is unreliable in a given environment, fall back to polling `unread-count`
every ~5s (the web app already does exactly this — see launch-plan decision
2026-05-29). Either way the iOS view code is unchanged.

### Profiles (`ProfilesAPI`)
| iOS method | HTTP |
|---|---|
| `optometrist(id:)` | `GET /ods/:id` → `Optometrist` |
| `practice(id:)` | `GET /practices/:id` → `Practice` |
| `updateODProfile(_:_:)` | `PATCH /ods/:id` (`UpdateODInput`) → `Optometrist` |
| `updatePractice(_:_:)` | `PATCH /practices/:id` (`UpdatePracticeInput`) → `Practice` |

### Payouts / Billing / Reviews
| iOS method | HTTP |
|---|---|
| `payouts(for:)` | `GET /ods/:id/payouts` → `[Payout]` |
| `invoices(for:)` | `GET /practices/:id/billing` → `[BillingLine]` (derived from bookings) |
| `review(forBooking:role:)` | `GET /bookings/:id/reviews?role=` → `Review?` |
| `submitReview(_:)` | `POST /reviews` (`SubmitReviewInput`) → `Review` |

---

## 3. Aggregated read-models (server joins, not client)

The web RSC pages already join server-side; the mobile API must do the same so the
client never orchestrates N calls per screen. Return these as single payloads:

- **`ShiftDetail`** = shift + practice + `cost: ShiftCost` + `viewerApplication?`.
- **`BookingDetail`** = booking + shift + practice + od + contract + `thread?`.
- **`ApplicantSummary`** = application + OD summary (name, rating, verification).
- **`ShiftCost`** = `{ hours, subtotalCents, feeCents, totalCents, odPayoutCents, sameDay }`
  (server computes via the existing `computeShiftCost`).

---

## 4. Enum reference (raw values — send verbatim)

- **UserRole:** practice_owner, practice_scheduler, od, admin
- **ShiftType:** fill_in, half_day, weekend, recurring, permanent
- **ShiftStatus:** draft, posted, booked, completed, cancelled
- **ShiftVisibility:** public, favorites, invite_only
- **ApplicationSource:** apply, invite, watch_alert
- **ApplicationStatus:** applied, shortlisted, offered, accepted, declined, withdrawn
- **BookingStatus:** confirmed, in_progress, completed, cancelled, no_show
- **PayoutStatus:** scheduled, sent, failed
- **WatchZoneShape:** circle, polygon
- **ReviewAuthor:** practice, od
- **VerificationStatus:** pending, verified, rejected
- **Channel:** push, email, sms
- **NotificationKind:** watch_match, invite_received, new_applicant,
  booking_confirmed, shift_reminder, cancellation, no_show_check, payout_sent,
  review_request, credential_expiring, verification_decided, message_received

---

## 5. Open decisions to settle before building the endpoints

- **Token lifetime + refresh:** long-lived + re-login (simplest) vs. access +
  refresh pair. Default: long-lived for V1.
- **Authorization granularity:** confirm role checks per route reuse the existing
  `guards.ts` helpers (`requireOd`, `requirePractice`, `requireVerifiedOd`).
- **APNs:** when push moves from deferred to real, add `POST /push/register`
  `{ apnsToken }` and a new server-side APNs channel alongside the existing Web
  Push (`pushSubscriptions` table is Web-Push-shaped today).
- **Rate limiting / pagination defaults** for the public-ish browse endpoints.
- **Geocoding:** whether `browseShifts` distance sorting is server-side
  (`ST_Distance`) — recommended — or client-side from `LatLng`.

> Build order on the web side (later): start with `/auth/token` +
> `GET /shifts` + `GET /shifts/:id` + `POST /shifts/:id/applications` — that's the
> minimum to take the iOS signature loop from mock to live.
