import Foundation
import Observation
import RevenueCat

/// Purchases through RevenueCat. Without a key, Debug builds complete purchases instantly (mock) so the
/// hard paywall can be crossed in the simulator; Release builds show "store unavailable".
@Observable
@MainActor
final class PurchaseService {
  static let shared = PurchaseService()

  /// Display prices. Subscriptions always carry their billing period (App Review 3.1.2).
  private(set) var prices: [SubscriptionPlan: String] = [:]
  /// Localized price of the 75-day pass divided by 75.
  private(set) var passPricePerDay: String
  private(set) var isBusy = false
  private(set) var lastError: String?
  private var packages: [SubscriptionPlan: Package] = [:]

  var isConfigured: Bool { !Secrets.revenueCatKey.isEmpty }

  private init() {
    for plan in SubscriptionPlan.allCases { prices[plan] = plan.fallbackPrice }
    passPricePerDay = Self.perDay(SubscriptionPlan.pass75.fallbackAmount, locale: Locale(identifier: "fr_FR"))
    if isConfigured {
      Purchases.logLevel = .warn
      // Signed in with Apple: purchases are tied to the Apple identity from the first launch.
      Purchases.configure(withAPIKey: Secrets.revenueCatKey, appUserID: AuthService.shared.userID)
    }
  }

  func refreshPrices() async {
    guard isConfigured else { return }
    do {
      let offerings = try await Purchases.shared.offerings()
      for package in offerings.current?.availablePackages ?? [] {
        guard let plan = SubscriptionPlan.allCases.first(where: { $0.productID == package.storeProduct.productIdentifier }) else { continue }
        packages[plan] = package
        let price = package.storeProduct.localizedPriceString
        switch plan {
        case .pass75:
          prices[plan] = price
          let locale = package.storeProduct.priceFormatter?.locale ?? .current
          passPricePerDay = Self.perDay(package.storeProduct.price, locale: locale)
        case .weekly:
          prices[plan] = String(localized: "\(price) / week")
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
      #if DEBUG
      try? await Task.sleep(for: .milliseconds(900))
      return plan.entitlement
      #else
      lastError = String(localized: "The store isn't available right now. Try again in a moment.")
      return nil
      #endif
    }
    do {
      if packages[plan] == nil { await refreshPrices() }
      guard let package = packages[plan] else {
        lastError = String(localized: "The store isn't available right now. Try again in a moment.")
        return nil
      }
      let result = try await Purchases.shared.purchase(package: package)
      if result.userCancelled { return nil }
      return Self.entitlement(from: result.customerInfo)
    } catch {
      if (error as NSError).code == ErrorCode.purchaseCancelledError.rawValue { return nil }
      lastError = error.localizedDescription
      return nil
    }
  }

  func restore() async -> Entitlement? {
    isBusy = true
    defer { isBusy = false }
    lastError = nil
    guard isConfigured else {
      lastError = String(localized: "The store isn't available right now. Try again in a moment.")
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

  /// Ties purchases to the Apple identity so entitlements follow the user across devices.
  func identify(userID: String) async {
    guard isConfigured else { return }
    _ = try? await Purchases.shared.logIn(userID)
  }

  func logOut() async {
    guard isConfigured, !Purchases.shared.isAnonymous else { return }
    _ = try? await Purchases.shared.logOut()
  }

  /// Re-checks the current customer on launch so an expired weekly plan locks the app again.
  /// nil when the store can't be reached (keep the local state).
  func currentEntitlement() async -> Entitlement? {
    guard isConfigured else { return nil }
    guard let info = try? await Purchases.shared.customerInfo() else { return nil }
    return Self.entitlement(from: info) ?? Entitlement.none
  }

  /// Reads the RevenueCat entitlements, and falls back to raw product ids so a missing entitlement
  /// mapping in the dashboard never locks out a paying user.
  private static func entitlement(from info: CustomerInfo) -> Entitlement? {
    let active = Set(info.entitlements.active.values.map(\.productIdentifier))
    if active.contains(SubscriptionPlan.pass75.productID)
      || info.allPurchasedProductIdentifiers.contains(SubscriptionPlan.pass75.productID) {
      return .pass75
    }
    if active.contains(SubscriptionPlan.weekly.productID)
      || info.activeSubscriptions.contains(SubscriptionPlan.weekly.productID) {
      return .weekly
    }
    return nil
  }

  private static func perDay(_ price: Decimal, locale: Locale) -> String {
    (price / Decimal(Act.totalDays)).formatted(.currency(code: locale.currency?.identifier ?? "EUR").locale(locale))
  }
}

extension SubscriptionPlan {
  var entitlement: Entitlement {
    switch self {
    case .pass75: .pass75
    case .weekly: .weekly
    }
  }
}
