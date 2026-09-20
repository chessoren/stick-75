import Foundation
import Observation
import RevenueCat

/// Subscriptions through RevenueCat. When no key is configured (simulator, first setup),
/// a mock completes purchases instantly so the hard paywall can be crossed.
@Observable
@MainActor
final class PurchaseService {
  static let shared = PurchaseService()

  private(set) var prices: [SubscriptionPlan: String] = [:]
  private(set) var isBusy = false
  private(set) var lastError: String?
  private var packages: [SubscriptionPlan: Package] = [:]

  var isConfigured: Bool { !Secrets.revenueCatKey.isEmpty }

  private init() {
    for plan in SubscriptionPlan.allCases { prices[plan] = plan.fallbackPrice }
    if isConfigured {
      Purchases.logLevel = .warn
      Purchases.configure(withAPIKey: Secrets.revenueCatKey)
    }
  }

  func refreshPrices() async {
    guard isConfigured else { return }
    do {
      let offerings = try await Purchases.shared.offerings()
      for package in offerings.current?.availablePackages ?? [] {
        if let plan = SubscriptionPlan.allCases.first(where: { $0.productID == package.storeProduct.productIdentifier }) {
          packages[plan] = package
          prices[plan] = package.storeProduct.localizedPriceString
        }
      }
    } catch {
      lastError = error.localizedDescription
    }
  }

  func purchase(_ plan: SubscriptionPlan) async -> Entitlement? {
    isBusy = true
    defer { isBusy = false }
    lastError = nil
    guard isConfigured else {
      try? await Task.sleep(for: .milliseconds(900))
      return plan.entitlement
    }
    do {
      if packages.isEmpty { await refreshPrices() }
      guard let package = packages[plan] else {
        lastError = "Product not available yet."
        return nil
      }
      let result = try await Purchases.shared.purchase(package: package)
      if result.userCancelled { return nil }
      return Self.entitlement(from: result.customerInfo)
    } catch {
      lastError = error.localizedDescription
      return nil
    }
  }

  func restore() async -> Entitlement? {
    isBusy = true
    defer { isBusy = false }
    guard isConfigured else {
      try? await Task.sleep(for: .milliseconds(700))
      return nil
    }
    do {
      let info = try await Purchases.shared.restorePurchases()
      return Self.entitlement(from: info)
    } catch {
      lastError = error.localizedDescription
      return nil
    }
  }

  /// Re-checks the current customer on launch so an expired weekly plan locks the app again.
  func currentEntitlement() async -> Entitlement? {
    guard isConfigured else { return nil }
    guard let info = try? await Purchases.shared.customerInfo() else { return nil }
    return Self.entitlement(from: info) ?? Entitlement.none
  }

  private static func entitlement(from info: CustomerInfo) -> Entitlement? {
    let products = Set(info.entitlements.active.values.map(\.productIdentifier))
    if products.contains(SubscriptionPlan.life.productID) { return .life }
    if products.contains(SubscriptionPlan.pass75.productID) { return .pass75 }
    if products.contains(SubscriptionPlan.weekly.productID) { return .weekly }
    return nil
  }
}

extension SubscriptionPlan {
  var entitlement: Entitlement {
    switch self {
    case .pass75: .pass75
    case .weekly: .weekly
    case .life: .life
    }
  }
}
