import SwiftUI
import UserNotifications

@main
struct StickApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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

/// Routes notification taps (backup ringer) into a call.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return true
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    if let kind = response.notification.request.content.userInfo["callKind"] as? String {
      AppGroup.defaults.set(kind, forKey: "stick.pendingCall")
      AppGroup.defaults.set(Date.now.timeIntervalSince1970, forKey: "stick.pendingCall.at")
    }
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
    [.banner, .sound]
  }
}
