import Foundation

typealias Cents = Int

let matchFeeCents: Cents = 999
let sameDayFeeCents: Cents = 1_999
let sameDayThresholdSeconds: TimeInterval = 24 * 60 * 60

struct ShiftCost: Codable, Hashable, Sendable {
    var hours: Double
    var subtotalCents: Cents
    var feeCents: Cents
    var totalCents: Cents
    var odPayoutCents: Cents
    var sameDay: Bool
}

func formatUsd(_ cents: Cents) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "USD"
    formatter.currencySymbol = "$"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.positiveFormat = "¤#,##0.00"
    formatter.negativeFormat = "-¤#,##0.00"
    return formatter.string(from: NSNumber(value: Double(cents) / 100)) ?? "$0.00"
}

func computeShiftCost(
    rateCentsPerHour: Cents,
    startsAt: Date,
    endsAt: Date,
    lunchMinutes: Int,
    urgent: Bool,
    confirmedAt: Date = .now
) -> ShiftCost {
    let workedSeconds = max(0, endsAt.timeIntervalSince(startsAt) - Double(lunchMinutes * 60))
    let hours = workedSeconds / 3_600
    let subtotalCents = Cents((Double(rateCentsPerHour) * hours).rounded())
    let sameDay = urgent || startsAt.timeIntervalSince(confirmedAt) <= sameDayThresholdSeconds
    let feeCents = sameDay ? sameDayFeeCents : matchFeeCents
    let totalCents = subtotalCents + feeCents

    return ShiftCost(
        hours: hours,
        subtotalCents: subtotalCents,
        feeCents: feeCents,
        totalCents: totalCents,
        odPayoutCents: subtotalCents,
        sameDay: sameDay
    )
}
