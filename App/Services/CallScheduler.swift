import AlarmKit
import Foundation
import SwiftUI
import UserNotifications

/// Schedules the wake-up call and the evening debrief with AlarmKit (rings on the Lock Screen,
/// Dynamic Island and Apple Watch, breaks through Silent). Falls back to time-sensitive notifications.
@MainActor
enum CallScheduler {
  static let wakeAlarmID = UUID(uuidString: "5A1C0000-0000-4000-8000-00000000A0A1")!
  static let debriefAlarmID = UUID(uuidString: "5A1C0000-0000-4000-8000-00000000A0A2")!

  enum Status: String {
    case notDetermined, authorized, denied, unavailable
  }

  static var alarmStatus: Status {
    switch AlarmManager.shared.authorizationState {
    case .authorized: .authorized
    case .denied: .denied
    case .notDetermined: .notDetermined
    @unknown default: .unavailable
    }
  }

  @discardableResult
  static func requestAlarmAuthorization() async -> Bool {
    do {
      let state = try await AlarmManager.shared.requestAuthorization()
      return state == .authorized
    } catch {
      return false
    }
  }

  static func requestNotificationAuthorization() async -> Bool {
    (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
  }

  /// AlarmKit when allowed, otherwise time-sensitive notifications. Never both: that would ring twice.
  static func scheduleDailyCalls(profile: UserProfile, act: Act = .silence) async {
    if AlarmManager.shared.authorizationState == .authorized {
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["stick.wake", "stick.debrief"])
      await scheduleAlarms(profile: profile, act: act)
    } else {
      await scheduleNotifications(profile: profile, act: act)
    }
  }

  private static func scheduleAlarms(profile: UserProfile, act: Act) async {
    guard AlarmManager.shared.authorizationState == .authorized else { return }
    try? AlarmManager.shared.cancel(id: wakeAlarmID)
    try? AlarmManager.shared.cancel(id: debriefAlarmID)
    let everyDay: [Locale.Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    let french = profile.language == .french
    let plans: [(UUID, CallKind, ClockTime, LocalizedStringResource)] = [
      (wakeAlarmID, .wake, profile.wakeTime, french ? "Toi (Stick) t'appelle" : "You (Stick) is calling"),
      (debriefAlarmID, .debrief, profile.debriefTime, french ? "Toi (Stick) · bilan du soir" : "You (Stick) · evening debrief")
    ]
    for (id, kind, time, title) in plans where kind != .debrief || act.hasDebriefCall {
      let answer = AlarmButton(
        text: french ? "Décrocher" : "Answer",
        textColor: .white,
        systemImageName: "phone.fill"
      )
      let dismissButton = AlarmButton(
        text: french ? "Ignorer" : "Dismiss",
        textColor: .white,
        systemImageName: "xmark"
      )
      let alert = AlarmPresentation.Alert(
        title: title,
        stopButton: dismissButton,
        secondaryButton: answer,
        secondaryButtonBehavior: .custom
      )
      let attributes = AlarmAttributes(
        presentation: AlarmPresentation(alert: alert),
        metadata: StickAlarmMetadata(callKind: kind.rawValue, userName: profile.firstName),
        tintColor: Color.brandOrange
      )
      let schedule = Alarm.Schedule.relative(.init(
        time: .init(hour: time.hour, minute: time.minute),
        repeats: .weekly(everyDay)
      ))
      let configuration = AlarmManager.AlarmConfiguration.alarm(
        schedule: schedule,
        attributes: attributes,
        stopIntent: DismissAlarmIntent(),
        secondaryIntent: StartCallIntent(callKind: kind.rawValue),
        sound: .default
      )
      _ = try? await AlarmManager.shared.schedule(id: id, configuration: configuration)
    }
  }

  private static func scheduleNotifications(profile: UserProfile, act: Act) async {
    let center = UNUserNotificationCenter.current()
    center.removePendingNotificationRequests(withIdentifiers: ["stick.wake", "stick.debrief"])
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
    let french = profile.language == .french
    let plans: [(String, CallKind, ClockTime, String, String)] = [
      ("stick.wake", .wake, profile.wakeTime,
       french ? "Toi (Stick)" : "You (Stick)",
       french ? "Décroche. On fixe tes objectifs du jour." : "Pick up. We set today's goals."),
      ("stick.debrief", .debrief, profile.debriefTime,
       french ? "Toi (Stick)" : "You (Stick)",
       french ? "Bilan du soir. Qu'est-ce que tu as vraiment fait ?" : "Evening debrief. What did you actually do?")
    ]
    for (id, kind, time, title, body) in plans where kind != .debrief || act.hasDebriefCall {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .defaultRingtone
      content.interruptionLevel = .timeSensitive
      content.userInfo = ["callKind": kind.rawValue]
      var components = DateComponents()
      components.hour = time.hour
      components.minute = time.minute
      let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
      try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
  }

  static func cancelAll() {
    try? AlarmManager.shared.cancel(id: wakeAlarmID)
    try? AlarmManager.shared.cancel(id: debriefAlarmID)
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["stick.wake", "stick.debrief"])
  }
}
