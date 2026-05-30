import SwiftUI

@main
struct NotifEyesApp: App {
    @State private var env: AppEnvironment
    @State private var sessionStore: SessionStore

    init() {
        let api = MockAPI()
        _env = State(initialValue: AppEnvironment(api: api))
        _sessionStore = State(initialValue: SessionStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(env)
                .environment(sessionStore)
        }
    }
}
