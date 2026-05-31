import SwiftUI

struct ODProfileScreen: View {
    @Environment(AppEnvironment.self) private var env

    var session: Session

    @State private var od: Optometrist?
    @State private var bio = ""
    @State private var licenseState = "CA"
    @State private var travelRadiusMi = 25.0
    @State private var specialties = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            if let od {
                Section {
                    LabeledContent("Verification") {
                        StatusBadge(
                            text: od.verificationStatus.displayName,
                            color: od.verificationStatus == .verified ? Color.notifEyesGreen : .orange
                        )
                    }
                    LabeledContent("Completed shifts", value: "\(od.shiftsCompleted)")
                    LabeledContent("Rating", value: od.ratingAvg.map { String(format: "%.2f", $0) } ?? "New")
                }
            }

            Section("Profile completion") {
                TextEditor(text: $bio)
                    .frame(minHeight: 96)
                TextField("License state", text: $licenseState)
                    .textInputAutocapitalization(.characters)
                Stepper("Travel radius \(Int(travelRadiusMi)) mi", value: $travelRadiusMi, in: 5...100, step: 5)
                TextField("Specialties, comma separated", text: $specialties)
            }

            Button(isSaving ? "Saving..." : "Save profile") {
                Task { await save() }
            }
            .disabled(isSaving)

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .task(id: session.user.id) {
            await load()
        }
    }

    private func load() async {
        guard let odId = session.user.odId else { return }
        do {
            let loaded = try await env.api.optometrist(id: odId)
            od = loaded
            bio = loaded.bio ?? ""
            licenseState = loaded.licenseState ?? "CA"
            travelRadiusMi = loaded.travelRadiusMi
            specialties = loaded.specialties.joined(separator: ", ")
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func save() async {
        guard let odId = session.user.odId else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            od = try await env.api.updateODProfile(odId, UpdateODInput(
                name: nil,
                displayName: nil,
                bio: bio,
                headshotUrl: nil,
                homeLocation: nil,
                travelRadiusMi: travelRadiusMi,
                licenseState: licenseState,
                specialties: specialties.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                ehrExperience: nil
            ))
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }
}
