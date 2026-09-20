import SwiftUI

enum Badge: String, CaseIterable, Codable, Identifiable {
  case firstCall, silence, comeback, identity, trial, flight, recovery, week, halfway, finisher

  var id: String { rawValue }

  var title: LocalizedStringResource {
    switch self {
    case .firstCall: "First call"
    case .silence: "Act I · The Silence"
    case .comeback: "Act II · The Comeback"
    case .identity: "Act III · The Identity"
    case .trial: "Act IV · The Trial"
    case .flight: "Act V · The Flight"
    case .recovery: "Back on track"
    case .week: "7 days held"
    case .halfway: "Halfway"
    case .finisher: "75 days"
    }
  }

  var symbol: String {
    switch self {
    case .firstCall: "phone.fill"
    case .silence: "moon.fill"
    case .comeback: "arrow.uturn.forward"
    case .identity: "person.fill.checkmark"
    case .trial: "timer"
    case .flight: "bird.fill"
    case .recovery: "heart.fill"
    case .week: "7.circle.fill"
    case .halfway: "flag.fill"
    case .finisher: "crown.fill"
    }
  }
}
