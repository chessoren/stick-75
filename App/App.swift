import SwiftUI

@main
struct StickApp: App {
  @State private var store = StickStore()
  @State private var calls = CallCoordinator()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(store)
        .environment(calls)
        .preferredColorScheme(.light)
        .tint(.brandOrange)
    }
  }
}
