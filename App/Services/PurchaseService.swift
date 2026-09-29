import Foundation
import Observation
import RevenueCat

/// Purchases through RevenueCat.
///
/// - Access is one entitlement, `member`, attached to both products in the dashboard. Which product unlocked it
///   only decides the plan shown in Me › Subscription.
/// - Every paywall asks for the offering of its placement, so prices, products and experiments can change per
///   placement from the dashboard without an app update.
/// - Entitlement changes stream in from `customerInfoStream` (renewal, expiry, refund, Ask to Buy approval,
///   a restore on another device), so the app locks and unlocks without a relaunch.
///
/// Debug builds use the RevenueCat Test Store, so purchases work in the simulator with no Apple account;
/// Release builds (TestFlight, App Store) use the App Store app.
@Observable
@MainActor
final class PurchaseService {
  static let shared = PurchaseService()

  static let entitlementID = "member"

  /// Public SDK keys, safe to ship in the app. A Test Store key must never reach a release build.
  #if DEBUG
  private static let apiKey = "test_euCPFOBGsZiwgaRTfNwMutMdUUM"
  #else
  private static let apiKey = "appl_LKXokBhpFBKwMSTxAHqyKRQTxMK"
  #endif

  /// Display prices, nil until the store answers. Subscriptions always carry their billing period (App Review 3.1.2).
  private(set) var prices: [SubscriptionPlan: String] = [:]
  /// Localized price of the 75-day pass divided by 75.
  private(set) var passPricePerDay: String?
  private(set) var isBusy = false
  private(set) var lastError: String?
  private var packages: [SubscriptionPlan: Package] = [:]

  private init() {}

  /// Called from `application(_:didFinishLaunchingWithOptions:)` so transactions left unfinished by the last
  /// session are processed before any UI asks for them.
  func configure() {
    guard !Purchases.isConfigured else { return }
    #if DEBUG
    Purchases.logLevel = .debug
    #else
    Purchases.logLevel = .warn
    #endif
    // Signed in with Apple: purchases are tied to the Apple identity from the first launch.
    Purchases.configure(withAPIKey: Self.apiKey, appUserID: AuthService.shared.userID)
  }

  // MARK: - Offerings

  func refreshPrices(for placement: PaywallPlacement) async {
    do {
      let offerings = try await Purchases.shared.offerings()
      let offering = offerings.currentOffering(forPlacement: placement.rawValue) ?? offerings.current
      packages = [:]
      for package in offering?.availablePackages ?? [] {
        guard let plan = SubscriptionPlan(productID: package.storeProduct.productIdentifier) else { continue }
        packages[plan] = package
        let product = package.storeProduct
        switch plan {
        case .pass75:
          prices[plan] = product.localizedPriceString
          passPricePerDay = Self.perDay(
            product.price,
            currencyCode: product.currencyCode ?? "USD",
            locale: product.priceFormatter?.locale ?? .current
          )
        case .weekly:
          prices[plan] = String(localized: "\(product.localizedPriceString) / week")
        }
      }
    } catch {
      lastError = error.localizedDescription
    }
  }

  // MARK: - Purchases

  func purchase(_ plan: SubscriptionPlan, placement: PaywallPlacement) async -> Entitlement? {
    guard !isBusy else { return nil }
    isBusy = true
    defer { isBusy = false }
    lastError = nil
    if packages[plan] == nil { await refreshPrices(for: placement) }
    guard let package = packages[plan] else {
      lastError = String(localized: "The store isn't available right now. Try again in a moment.")
      return nil
    }
    do {
      let result = try await Purchases.shared.purchase(package: package)
      if result.userCancelled { return nil }
      let entitlement = Self.entitlement(from: result.customerInfo)
      return entitlement.isActive ? entitlement : nil
    } catch {
      lastError = Self.message(for: error)
      return nil
    }
  }

  func restore() async -> Entitlement? {
    guard !isBusy else { return nil }
    isBusy = true
    defer { isBusy = false }
    lastError = nil
    do {
      let entitlement = Self.entitlement(from: try await Purchases.shared.restorePurchases())
      return entitlement.isActive ? entitlement : nil
    } catch {
      lastError = Self.message(for: error)
      return nil
    }
  }

  // MARK: - Customer

  /// Ties purchases to the Apple identity so entitlements follow the user across devices. The merged customer
  /// reaches the app through `entitlementUpdates()`.
  func identify(userID: String) async {
    _ = try? await Purchases.shared.logIn(userID)
  }

  func logOut() async {
    guard !Purchases.shared.isAnonymous else { return }
    _ = try? await Purchases.shared.logOut()
  }

  /// Fresh check on launch. nil when the store can't be reached (keep the local state).
  func currentEntitlement() async -> Entitlement? {
    guard let info = try? await Purchases.shared.customerInfo() else { return nil }
    return Self.entitlement(from: info)
  }

  /// Every change to the customer: purchase, renewal, expiry, refund, Ask to Buy approval, restore elsewhere.
  func entitlementUpdates() -> AsyncStream<Entitlement> {
    AsyncStream { continuation in
      let task = Task {
        for await info in Purchases.shared.customerInfoStream {
          continuation.yield(Self.entitlement(from: info))
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }

  /// Program progress only (never names, goals or quiz answers), so dashboard targeting and Charts can tell
  /// a day-3 user from a day-60 one.
  func updateAttributes(dayNumber: Int, act: Act, usesClonedVoice: Bool) {
    Purchases.shared.attribution.setAttributes([
      "program_day": String(dayNumber),
      "program_act": String(act.rawValue),
      "voice_mode": usesClonedVoice ? "clone" : "system"
    ])
  }

  // MARK: - Mapping

  /// Reads the `member` entitlement. If the dashboard has no such entitlement yet, falls back to the raw product
  /// ids so a configuration mistake never locks out a paying user.
  private static func entitlement(from info: CustomerInfo) -> Entitlement {
    if let member = info.entitlements[entitlementID] {
      guard member.isActive else { return .none }
      return SubscriptionPlan(productID: member.productIdentifier)?.entitlement ?? .pass75
    }
    if info.allPurchasedProductIdentifiers.contains(SubscriptionPlan.pass75.productID) { return .pass75 }
    if info.activeSubscriptions.contains(SubscriptionPlan.weekly.productID) { return .weekly }
    return .none
  }

  private static func message(for error: Error) -> String? {
    switch error as? ErrorCode {
    case .purchaseCancelledError:
      nil
    case .paymentPendingError:
      String(localized: "Waiting for approval. Stick unlocks as soon as the purchase is approved.")
    case .networkError, .offlineConnectionError:
      String(localized: "No connection. Check your network and try again.")
    default:
      error.localizedDescription
    }
  }

  private static func perDay(_ price: Decimal, currencyCode: String, locale: Locale) -> String {
    (price / Decimal(Act.totalDays)).formatted(.currency(code: currencyCode).locale(locale))
  }
}

/// Where a paywall is shown. Each maps to a RevenueCat placement, so the offering (products, prices, experiments)
/// can differ per moment from the dashboard.
enum PaywallPlacement: String {
  /// Step 17 of onboarding, right after the first call and the signed contract.
  case onboarding
  /// Full-screen lock when access ends (weekly plan expired, refund).
  case lockedOut = "locked_out"
  /// Me › Subscription.
  case settings
}

extension SubscriptionPlan {
  init?(productID: String) {
    guard let plan = Self.allCases.first(where: { $0.productID == productID }) else { return nil }
    self = plan
  }

  var entitlement: Entitlement {
    switch self {
    case .pass75: .pass75
    case .weekly: .weekly
    }
  }
}
