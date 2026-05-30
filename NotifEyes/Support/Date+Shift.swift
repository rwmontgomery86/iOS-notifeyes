import Foundation

extension Date {
    func hoursUntil(_ other: Date) -> Double {
        other.timeIntervalSince(self) / 3_600
    }
}
