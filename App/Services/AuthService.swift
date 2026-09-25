import AuthenticationServices
import Foundation
import Observation
import Security

/// Sign in with Apple, on device only (no backend). The stable Apple user identifier becomes the RevenueCat
/// app user id, so purchases follow the person across reinstalls and devices.
/// Stick never exchanges the authorization code with Apple's servers, so no refresh token exists to revoke:
/// deleting the account forgets the identifier and logs RevenueCat out.
@Observable
@MainActor
final class AuthService {
  static let shared = AuthService()

  private(set) var userID: String?
  private(set) var lastError: String?

  var isSignedIn: Bool { userID != nil }

  private init() {
    userID = Keychain.read(Self.keychainAccount)
  }

  /// The link can be cut from Settings › Apple Account › Sign in with Apple. Checked on launch.
  func refresh() async {
    guard let userID else { return }
    guard let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID) else { return }
    if state == .revoked || state == .notFound {
      await signOut()
    }
  }

  /// Handles the result of `SignInWithAppleButton`. Returns true on success.
  func handle(_ result: Result<ASAuthorization, Error>) async -> Bool {
    lastError = nil
    switch result {
    case .failure(let error):
      if (error as? ASAuthorizationError)?.code != .canceled { lastError = error.localizedDescription }
      return false
    case .success(let authorization):
      guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
        lastError = String(localized: "Apple didn't return a valid account.")
        return false
      }
      Keychain.save(credential.user, for: Self.keychainAccount)
      userID = credential.user
      await PurchaseService.shared.identify(userID: credential.user)
      return true
    }
  }

  func signOut() async {
    Keychain.delete(Self.keychainAccount)
    userID = nil
    await PurchaseService.shared.logOut()
  }

  private static let keychainAccount = "stick.appleUserID"
}

/// Minimal generic-password keychain storage. Survives app reinstalls, unlike the app container.
enum Keychain {
  private static let service = "app.stick.account"

  static func read(_ account: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data else { return nil }
    return String(data: data, encoding: .utf8)
  }

  static func save(_ value: String, for account: String) {
    delete(account)
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
      kSecValueData as String: Data(value.utf8)
    ]
    SecItemAdd(query as CFDictionary, nil)
  }

  static func delete(_ account: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    SecItemDelete(query as CFDictionary)
  }
}
