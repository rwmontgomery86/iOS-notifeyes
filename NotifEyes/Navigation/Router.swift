import Observation
import SwiftUI

@Observable
final class Router {
    var path = NavigationPath()

    func append(_ route: Route) {
        path.append(route)
    }

    func reset() {
        path = NavigationPath()
    }
}
