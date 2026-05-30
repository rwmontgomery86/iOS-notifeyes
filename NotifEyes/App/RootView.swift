import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore
    @State private var hasLoadedSession = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let session = sessionStore.session {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(session.user.name ?? session.user.email)
                                .font(.title2.weight(.semibold))
                            Text(session.role == .od ? "OD shell placeholder" : "Practice shell placeholder")
                                .foregroundStyle(.secondary)
                            Text("Phase 0 is running through NotifEyesAPI.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    } else if sessionStore.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading demo session")
                        }
                    } else {
                        Text("Choose a demo persona to start.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Demo personas") {
                    ForEach(DemoActor.allCases) { actor in
                        Button {
                            Task {
                                await sessionStore.switchDemoActor(to: actor, api: env.api)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(actor.displayName)
                                        .font(.body.weight(.medium))
                                    Text(actor.subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if isCurrent(actor) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .disabled(sessionStore.isLoading)
                    }
                }

                if let errorMessage = sessionStore.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("NotifEyes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(DemoActor.allCases) { actor in
                            Button(actor.displayName) {
                                Task {
                                    await sessionStore.switchDemoActor(to: actor, api: env.api)
                                }
                            }
                        }
                    } label: {
                        Label("Switch demo actor", systemImage: "person.2")
                    }
                    .disabled(sessionStore.isLoading)
                }
            }
            .task {
                guard !hasLoadedSession else { return }
                hasLoadedSession = true
                await sessionStore.load(api: env.api)
            }
        }
    }

    private func isCurrent(_ actor: DemoActor) -> Bool {
        sessionStore.session?.user.email == actor.demoEmail
    }
}

#Preview {
    let api = MockAPI()
    RootView()
        .environment(AppEnvironment(api: api))
        .environment(SessionStore())
}
