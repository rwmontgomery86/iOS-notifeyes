import SwiftUI

struct TabNavigationStack<Content: View>: View {
    @Bindable var router: Router
    var title: String
    var content: () -> Content

    init(router: Router, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.router = router
        self.title = title
        self.content = content
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            content()
                .environment(router)
                .navigationTitle(title)
                .navigationDestination(for: Route.self) { route in
                    RouteDestinationView(route: route)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        DemoSwitcherMenu()
                    }
                }
        }
    }
}
