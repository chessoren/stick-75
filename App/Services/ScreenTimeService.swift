import FamilyControls
import Foundation
import ManagedSettings
import Observation

/// Screen Time integration: pick the apps to block and shield them.
/// Needs the Family Controls entitlement from Apple; without it, authorization fails and the app
/// falls back to the Shortcuts automation ("when TikTok opens → open Stick").
@Observable
@MainActor
final class ScreenTimeService {
  static let shared = ScreenTimeService()

  private(set) var isAuthorized = false
  private(set) var lastError: String?
  var selection = FamilyActivitySelection() {
    didSet { persistSelection() }
  }

  private let store = ManagedSettingsStore(named: .init("stick.shield"))
  private let selectionKey = "stick.familySelection"

  private init() {
    isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    if let data = AppGroup.defaults.data(forKey: selectionKey),
       let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
      selection = saved
    }
  }

  var hasSelection: Bool {
    !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty
  }

  func requestAuthorization() async -> Bool {
    do {
      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
      isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
      lastError = nil
    } catch {
      isAuthorized = false
      lastError = error.localizedDescription
    }
    return isAuthorized
  }

  private func persistSelection() {
    if let data = try? JSONEncoder().encode(selection) {
      AppGroup.defaults.set(data, forKey: selectionKey)
    }
  }

  /// Applies the shield to the selected apps (Act I–III: full block; IV–V: handled by the window logic).
  func applyShield(enabled: Bool) {
    guard isAuthorized else { return }
    if enabled, hasSelection {
      store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
      store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
      store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    } else {
      store.shield.applications = nil
      store.shield.applicationCategories = nil
      store.shield.webDomains = nil
    }
  }
}
