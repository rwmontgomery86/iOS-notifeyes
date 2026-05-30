import Observation

@MainActor
@Observable
final class AppEnvironment {
    let api: any NotifEyesAPI

    init(api: any NotifEyesAPI) {
        self.api = api
    }
}
