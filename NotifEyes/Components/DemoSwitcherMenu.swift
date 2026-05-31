import SwiftUI

struct DemoSwitcherMenu: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        Menu {
            ForEach(DemoActor.allCases) { actor in
                Button {
                    Task {
                        await sessionStore.switchDemoActor(to: actor, api: env.api)
                    }
                } label: {
                    if isCurrent(actor) {
                        Label(actor.displayName, systemImage: "checkmark")
                    } else {
                        Text(actor.displayName)
                    }
                }
            }
        } label: {
            Label("Switch demo actor", systemImage: "person.2")
        }
        .disabled(sessionStore.isLoading)
    }

    private func isCurrent(_ actor: DemoActor) -> Bool {
        sessionStore.session?.user.email == actor.demoEmail
    }
}
