import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore
    @State private var hasLoadedSession = false

    var body: some View {
        Group {
            if sessionStore.isLoading && !hasLoadedSession {
                ProgressView("Loading demo workspace")
            } else if let session = sessionStore.session {
                switch session.role {
                case .od:
                    ODTabView(session: session)
                        .id(session.user.id)
                case .practice:
                    PracticeTabView(session: session)
                        .id(session.user.id)
                }
            } else {
                DemoPickerView()
            }
        }
        .task {
            guard !hasLoadedSession else { return }
            hasLoadedSession = true
            await sessionStore.load(api: env.api)
        }
    }
}

#Preview {
    let api = MockAPI()
    RootView()
        .environment(AppEnvironment(api: api))
        .environment(SessionStore())
}
