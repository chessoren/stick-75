import AppIntents
import Foundation
import WidgetKit

/// Marks a goal done or not from the widget.
struct ToggleGoalIntent: AppIntent {
  static let title: LocalizedStringResource = "Toggle goal"
  static let description = IntentDescription("Marks one of today's goals as done or not done.")

  @Parameter(title: "Goal")
  var goalID: String

  init() {}

  init(goalID: UUID) {
    self.goalID = goalID.uuidString
  }

  func perform() async throws -> some IntentResult {
    var snapshot = SharedSnapshot.load()
    if let index = snapshot.goals.firstIndex(where: { $0.id.uuidString == goalID }) {
      snapshot.goals[index].isDone.toggle()
      snapshot.save()
      AppGroup.defaults.set(Date.now.timeIntervalSince1970, forKey: "stick.goals.changedAt")
    }
    WidgetCenter.shared.reloadAllTimelines()
    return .result()
  }
}

/// Opens Stick straight into a call. Used by the Control Center control and the alarm button.
struct StartCallIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Call Stick"
  static let description = IntentDescription("Starts a call with your own voice.")
  static let openAppWhenRun = true

  @Parameter(title: "Call kind")
  var callKind: String

  init() {
    callKind = "intercept"
  }

  init(callKind: String) {
    self.callKind = callKind
  }

  func perform() async throws -> some IntentResult {
    AppGroup.defaults.set(callKind, forKey: "stick.pendingCall")
    AppGroup.defaults.set(Date.now.timeIntervalSince1970, forKey: "stick.pendingCall.at")
    return .result()
  }
}

/// Dismisses an alarm without opening the app.
struct DismissAlarmIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Dismiss"
  static let description = IntentDescription("Stops the ringing call.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    AppGroup.defaults.set(Date.now.timeIntervalSince1970, forKey: "stick.alarm.dismissedAt")
    return .result()
  }
}

/// Hangs up the current call from the Dynamic Island or Lock Screen.
struct EndCallIntent: LiveActivityIntent {
  static let title: LocalizedStringResource = "Hang up"
  static let description = IntentDescription("Ends the current call with Stick.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    AppGroup.defaults.set(Date.now.timeIntervalSince1970, forKey: "stick.call.endRequested")
    return .result()
  }
}
