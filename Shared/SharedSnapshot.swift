import Foundation

/// Lightweight state written by the app and read by widgets, controls and the Live Activity.
struct SharedSnapshot: Codable, Equatable {
  struct Goal: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var isDone: Bool
  }

  enum CallKind: String, Codable {
    case wake, intercept, debrief, recovery, aha, push
  }

  var dayNumber: Int
  var daysHeld: Int
  var actIndex: Int
  var actNameKey: String
  var goals: [Goal]
  var nextCallKind: CallKind?
  var nextCallDate: Date?
  var hoursRecovered: Double
  var userName: String
  var focusModeOn: Bool

  static let placeholder = SharedSnapshot(
    dayNumber: 12,
    daysHeld: 11,
    actIndex: 0,
    actNameKey: "The Silence",
    goals: [
      Goal(id: UUID(), title: "Finish the pitch deck", isDone: true),
      Goal(id: UUID(), title: "Run 5 km", isDone: false),
      Goal(id: UUID(), title: "Read 20 pages", isDone: false)
    ],
    nextCallKind: .debrief,
    nextCallDate: Calendar.current.date(bySettingHour: 21, minute: 30, second: 0, of: .now),
    hoursRecovered: 38.5,
    userName: "Alex",
    focusModeOn: true
  )

  static let empty = SharedSnapshot(
    dayNumber: 0, daysHeld: 0, actIndex: 0, actNameKey: "The Silence", goals: [],
    nextCallKind: nil, nextCallDate: nil, hoursRecovered: 0, userName: "", focusModeOn: false
  )

  static func load() -> SharedSnapshot {
    guard let data = AppGroup.defaults.data(forKey: AppGroup.snapshotKey),
          let snapshot = try? JSONDecoder().decode(SharedSnapshot.self, from: data) else {
      return .empty
    }
    return snapshot
  }

  func save() {
    if let data = try? JSONEncoder().encode(self) {
      AppGroup.defaults.set(data, forKey: AppGroup.snapshotKey)
    }
  }
}
