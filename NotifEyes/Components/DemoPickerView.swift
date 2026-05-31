import SwiftUI

struct DemoPickerView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(spacing: 14) {
                        Image("NotifEyesMark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notif Eyes")
                                .font(.system(size: 34, weight: .bold, design: .default))
                                .foregroundStyle(Color.notifEyesInk)
                            Text("Demo workspace")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.notifEyesMuted)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fill-in shifts, on a platform.")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Color.notifEyesInk)
                        Text("Pick a seeded persona to explore both sides of the marketplace.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        ForEach(DemoActor.allCases) { actor in
                            Button {
                                Task {
                                    await sessionStore.switchDemoActor(to: actor, api: env.api)
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    ActorAvatar(actor: actor)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(actor.displayName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(actor.subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                        .foregroundStyle(Color.notifEyesBlue)
                                }
                                .padding(16)
                                .background(.background)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.notifEyesLine, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let errorMessage = sessionStore.errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
                .padding(24)
            }
            .background(Color.notifEyesCanvas)
            .navigationTitle("NotifEyes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DemoSwitcherMenu()
                }
            }
        }
    }
}

private struct ActorAvatar: View {
    var actor: DemoActor

    var body: some View {
        ZStack {
            Circle()
                .fill(background)
            Text(initials)
                .font(.headline.weight(.bold))
                .foregroundStyle(foreground)
        }
        .frame(width: 44, height: 44)
    }

    private var initials: String {
        switch actor {
        case .mayaPatel:
            return "MP"
        case .yaraBrennan:
            return "YB"
        case .bayviewEyeCare:
            return "BV"
        }
    }

    private var background: Color {
        actor == .bayviewEyeCare ? Color.notifEyesBlue.opacity(0.16) : Color.notifEyesGreen.opacity(0.18)
    }

    private var foreground: Color {
        actor == .bayviewEyeCare ? Color.notifEyesBlue : Color.notifEyesGreen
    }
}
