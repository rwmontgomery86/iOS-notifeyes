import Foundation

enum DeepLink {
    static func parse(_ path: String) -> Route? {
        let components = path
            .split(separator: "/")
            .map(String.init)

        guard components.count >= 2, let id = UUID(uuidString: components[1]) else {
            return nil
        }

        switch components[0] {
        case "shifts":
            return .shiftDetail(id)
        case "bookings":
            return .bookingDetail(id)
        case "messages":
            return .messageThread(id)
        case "ods":
            return .odProfile(id)
        case "practices":
            return .practiceProfile(id)
        case "reviews":
            return .review(id)
        default:
            return nil
        }
    }
}
