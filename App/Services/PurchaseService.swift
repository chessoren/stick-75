import Foundation
import Observation

/// Subscription facade. RevenueCat plugs in behind this once the key is set; until then a
/// simulator-friendly mock completes purchases instantly.
@Observable
@MainActor
final class PurchaseService {
  static let shared = PurchaseService()

  private(set) var prices: [SubscriptionPlan: String] = [:]
  private(set) var isBusy = false
  private(set) var lastError: String?

  var isConfigured: Bool { !Secrets.revenueCatKey.isEmpty }

  private init() {
    for plan in SubscriptionPlan.allCases { prices[plan] = plan.fallbackPrice }
  }

  func refreshPrices() async {
    // RevenueCat offerings would be fetched here. Fallback prices are used until then.
  }

  func purchase(_ plan: SubscriptionPlan) async -> Entitlement? {
    isBusy = true
    defer { isBusy = false }
    try? await Task.sleep(for: .milliseconds(900))
    switch plan {
    case .pass75: return .pass75
    case .weekly: return .weekly
    case .life: return .life
    }
  }

  func restore() async -> Entitlement? {
    isBusy = true
    defer { isBusy = false }
    try? await Task.sleep(for: .milliseconds(700))
    return nil
  }
}
