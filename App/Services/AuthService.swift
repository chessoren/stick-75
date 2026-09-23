import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Supabase

/// Sign in with Apple → Supabase session. An anonymous session (league fallback) is upgraded in place.
@Observable
@MainActor
final class AuthService {
  static let shared = AuthService()

  private(set) var userID: String?
  private(set) var email: String?
  private(set) var isAnonymous = true
  private(set) var lastError: String?
  private var currentNonce: String?

  var isSignedIn: Bool { userID != nil && !isAnonymous }
  var isConfigured: Bool { !Secrets.supabaseURL.isEmpty && !Secrets.supabaseAnonKey.isEmpty }

  private init() {
    Task { await refresh() }
  }

  func refresh() async {
    guard let client = await SupabaseService.shared.client() else { return }
    if let session = try? await client.auth.session {
      userID = session.user.id.uuidString
      email = session.user.email
      isAnonymous = session.user.isAnonymous
    } else {
      userID = nil
      email = nil
      isAnonymous = true
    }
  }

  /// Nonce for the Apple request; the SHA-256 goes to Apple, the raw value to Supabase.
  func prepareNonce() -> String {
    let raw = Self.randomNonce()
    currentNonce = raw
    return SHA256.hash(data: Data(raw.utf8)).map { String(format: "%02x", $0) }.joined()
  }

  /// Handles the result of `SignInWithAppleButton`. Returns true on success.
  func handle(_ result: Result<ASAuthorization, Error>, fullName: PersonNameComponents? = nil) async -> Bool {
    lastError = nil
    switch result {
    case .failure(let error):
      if (error as? ASAuthorizationError)?.code != .canceled { lastError = error.localizedDescription }
      return false
    case .success(let authorization):
      guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let token = String(data: tokenData, encoding: .utf8) else {
        lastError = String(localized: "Apple didn't return a valid token.")
        return false
      }
      guard let client = await SupabaseService.shared.client() else {
        lastError = String(localized: "Accounts aren't available yet.")
        return false
      }
      let credentials = OpenIDConnectCredentials(provider: .apple, idToken: token, nonce: currentNonce)
      do {
        let existing = try? await client.auth.session
        let session: Session
        if let existing, existing.user.isAnonymous {
          // Keep the anonymous rows (league score, referral) by linking Apple to the same user.
          if let linked = try? await client.auth.linkIdentityWithIdToken(credentials: credentials) {
            session = linked
          } else {
            session = try await client.auth.signInWithIdToken(credentials: credentials)
          }
        } else {
          session = try await client.auth.signInWithIdToken(credentials: credentials)
        }
        userID = session.user.id.uuidString
        email = session.user.email ?? credential.email
        isAnonymous = false
        if let name = credential.fullName?.givenName, !name.isEmpty {
          _ = try? await client.auth.update(user: UserAttributes(data: ["first_name": .string(name)]))
        }
        await PurchaseService.shared.identify(userID: session.user.id.uuidString)
        return true
      } catch {
        lastError = error.localizedDescription
        return false
      }
    }
  }

  func signOut() async {
    guard let client = await SupabaseService.shared.client() else { return }
    try? await client.auth.signOut()
    await PurchaseService.shared.logOut()
    await refresh()
  }

  private static func randomNonce(length: Int = 32) -> String {
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var bytes = [UInt8](repeating: 0, count: length)
    _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
    for byte in bytes { result.append(charset[Int(byte) % charset.count]) }
    return result
  }
}
