import Foundation

enum CallKind: String, Codable, CaseIterable, Identifiable {
  case wake, intercept, debrief, recovery, aha, push

  var id: String { rawValue }

  var title: LocalizedStringResource {
    switch self {
    case .wake: "Wake-up call"
    case .intercept: "Interception"
    case .debrief: "Evening debrief"
    case .recovery: "Recovery call"
    case .aha: "First call"
    case .push: "Push"
    }
  }

  var symbol: String {
    switch self {
    case .wake: "sunrise.fill"
    case .intercept: "hand.raised.fill"
    case .debrief: "moon.stars.fill"
    case .recovery: "heart.fill"
    case .aha: "waveform"
    case .push: "bolt.fill"
    }
  }

  var targetSeconds: Int {
    switch self {
    case .wake: 90
    case .intercept: 45
    case .debrief: 120
    case .recovery: 60
    case .aha: 20
    case .push: 45
    }
  }
}

struct CallTurn: Identifiable, Codable, Hashable {
  enum Speaker: String, Codable { case stick, user }
  var id = UUID()
  var speaker: Speaker
  var text: String
  var at: Date = .now
}

struct CallRecord: Identifiable, Codable, Hashable {
  var id = UUID()
  var kind: CallKind
  var dayNumber: Int
  var startedAt: Date
  var durationSeconds: Int
  var turns: [CallTurn]
  var summary: String
  var answered: Bool
}
