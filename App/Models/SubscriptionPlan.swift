import Foundation

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
  case pass75, weekly, life

  var id: String { rawValue }

  var productID: String {
    switch self {
    case .pass75: "stick_pass_75"
    case .weekly: "stick_weekly"
    case .life: "stick_life_annual"
    }
  }

  var title: LocalizedStringResource {
    switch self {
    case .pass75: "75-Day Pass"
    case .weekly: "Weekly"
    case .life: "Stick Life"
    }
  }

  var subtitle: LocalizedStringResource {
    switch self {
    case .pass75: "One payment. The whole program. About €1 a day."
    case .weekly: "Cancel anytime. 75 days this way costs €110."
    case .life: "After the 75 days: maintenance mode, new seasons, leagues."
    }
  }

  var fallbackPrice: String {
    switch self {
    case .pass75: "€79.99"
    case .weekly: "€9.99 / week"
    case .life: "€129.99 / year"
    }
  }

  var isHero: Bool { self == .pass75 }
}

enum Entitlement: String, Codable {
  case none, trialDays, pass75, weekly, life

  var isActive: Bool { self != .none }
}
