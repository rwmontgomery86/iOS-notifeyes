import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    var session: Session?
    var isLoading = false
    var errorMessage: String?

    var role: SessionRole? {
        session?.role
    }

    var currentUser: User? {
        session?.user
    }

    func load(api: any NotifEyesAPI) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            session = try await api.currentSession()
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func signIn(email: String, password: String, api: any NotifEyesAPI) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            session = try await api.signIn(email: email, password: password)
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func signOut(api: any NotifEyesAPI) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await api.signOut()
            session = nil
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    func switchDemoActor(to actor: DemoActor, api: any NotifEyesAPI) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            session = try await api.switchDemoActor(to: actor)
        } catch {
            errorMessage = Self.message(for: error)
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case APIError.notImplemented:
            return "This API is not implemented yet."
        case APIError.notFound:
            return "That record could not be found."
        case let APIError.invalid(message):
            return message
        case APIError.unauthorized:
            return "You are not authorized for that action."
        default:
            return error.localizedDescription
        }
    }
}
