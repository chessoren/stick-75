import AppIntents
import SwiftUI
import WidgetKit

/// Control Center button: ring yourself right now.
struct CallStickControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(kind: "app.stick.callNow") {
      ControlWidgetButton(action: StartCallIntent(callKind: "intercept")) {
        Label("Call me", systemImage: "phone.fill")
      }
    }
    .displayName("Call Stick")
    .description("Ring yourself with your own voice, right now.")
  }
}
