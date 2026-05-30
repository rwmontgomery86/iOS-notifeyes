import Foundation

enum APIError: Error, Equatable {
    case notImplemented
    case notFound
    case invalid(String)
    case unauthorized
}
