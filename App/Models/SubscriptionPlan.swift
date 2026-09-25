import Foundation

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable {
  case pass75, weekly

  var id: String { rawValue }

  var productID: String {
    switch self {
    case .pass75: "stick_pass_75"
    case .weekly: "stick_weekly"
    }
  }

  var title: LocalizedStringResource {
    switch self {
    case .pass75: "75-Day Pass"
    case .weekly: "Weekly"
    }
  }

  var subtitle: LocalizedStringResource {
    switch self {
    case .pass75: "One payment. The whole program. Nothing renews."
    case .weekly: "Auto-renewing weekly subscription. Cancel anytime."
    }
  }

  /// Shown until the App Store prices load (store unreachable or not configured yet).
  var fallbackPrice: String {
    switch self {
    case .pass75: "€79.99"
    case .weekly: String(localized: "€9.99 / week")
    }
  }

  var fallbackAmount: Decimal {
    switch self {
    case .pass75: Decimal(string: "79.99")!
    case .weekly: Decimal(string: "9.99")!
    }
  }

  var isHero: Bool { self == .pass75 }
}

enum Entitlement: String, Codable {
  case none, pass75, weekly

  var isActive: Bool { self != .none }

  /// Older builds stored referral free days ("trialDays") and Stick Life: both decode to no plan.
  init(from decoder: Decoder) throws {
    let raw = try decoder.singleValueContainer().decode(String.self)
    self = Entitlement(rawValue: raw) ?? .none
  }
}
