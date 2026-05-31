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
            errorMessage = userFacingMessage(for: error)
        }
    }

    func signIn(email: String, password: String, api: any NotifEyesAPI) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            session = try await api.signIn(email: email, password: password)
        } catch {
            errorMessage = userFacingMessage(for: error)
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
            errorMessage = userFacingMessage(for: error)
        }
    }

    func switchDemoActor(to actor: DemoActor, api: any NotifEyesAPI) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            session = try await api.switchDemoActor(to: actor)
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}
