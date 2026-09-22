import SwiftUI

/// The 75 days are five acts of 15 days.
enum Act: Int, CaseIterable, Codable, Identifiable {
  case silence = 0, comeback, identity, trial, flight

  var id: Int { rawValue }

  static let length = 15
  static let totalDays = 75

  static func act(forDay day: Int) -> Act {
    let index = max(0, min(Act.allCases.count - 1, (day - 1) / length))
    return Act(rawValue: index) ?? .silence
  }

  var dayRange: ClosedRange<Int> {
    let start = rawValue * Act.length + 1
    return start...(start + Act.length - 1)
  }

  var numeral: String {
    ["I", "II", "III", "IV", "V"][rawValue]
  }

  var name: LocalizedStringResource {
    switch self {
    case .silence: "The Silence"
    case .comeback: "The Comeback"
    case .identity: "The Identity"
    case .trial: "The Trial"
    case .flight: "The Flight"
    }
  }

  var focus: LocalizedStringResource {
    switch self {
    case .silence: "Total lockdown. Maximum friction. Three calls a day."
    case .comeback: "Replace, don't just block. One new habit chosen every morning."
    case .identity: "\"I am someone who…\" Shorter calls, harder questions. League unlocked."
    case .trial: "The shield comes off: 15 minutes a day, on your honor. Stick still calls every time you open."
    case .flight: "Scaffolding comes off. One call a day. You plan life after day 75."
    }
  }

  var symbol: String {
    switch self {
    case .silence: "moon.fill"
    case .comeback: "arrow.uturn.forward"
    case .identity: "person.fill.checkmark"
    case .trial: "timer"
    case .flight: "bird.fill"
    }
  }

  var callsPerDay: Int {
    switch self {
    case .silence, .comeback: 3
    case .identity, .trial: 2
    case .flight: 1
    }
  }

  /// Minutes of intentional use allowed per day on blocked apps.
  var allowedWindowMinutes: Int {
    switch self {
    case .trial: 15
    case .flight: 20
    default: 0
    }
  }
}
