import AuthenticationServices
import SwiftUI

/// Onboarding step after the paywall: create the account with Apple. Optional, but it powers league, referral and cross-device restore.
struct AccountScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var busy = false

  private var auth: AuthService { .shared }

  var body: some View {
    OnboardingPage("One account. Yours.", subtitle: "Sign in with Apple keeps your 75 days, your league rank and your purchases if you change phones. Apple hides your email if you want.") {
      VStack(alignment: .leading, spacing: 12) {
        ConsentRow(symbol: "trophy.fill", text: "Needed for the league and to give friends their 5 free days.")
        ConsentRow(symbol: "iphone.and.arrow.forward", text: "Your progress and purchases follow you to a new iPhone.")
        ConsentRow(symbol: "eye.slash.fill", text: "Stick stores your first name, score and days held. Nothing else.")
        if let error = auth.lastError {
          Text(error)
            .font(StickFont.footnote)
            .foregroundStyle(Color.stickDanger)
        }
      }
      .padding(.top, 8)
    } footer: {
      if !auth.isConfigured {
        Button { model.next() } label: { Text("Continue") }
          .buttonStyle(PrimaryPillButtonStyle())
      } else if auth.isSignedIn {
        Button { model.next() } label: { Label("Signed in · Continue", systemImage: "checkmark") }
          .buttonStyle(PrimaryPillButtonStyle())
      } else {
        AppleSignInPill(busy: $busy) { model.next() }
        Button { model.next() } label: { Text("Later") }
          .buttonStyle(SecondaryPillButtonStyle())
          .disabled(busy)
      }
    }
  }
}

/// Styled Sign in with Apple button that completes the Supabase session.
struct AppleSignInPill: View {
  @Binding var busy: Bool
  var onSuccess: () -> Void

  private var auth: AuthService { .shared }

  var body: some View {
    SignInWithAppleButton(.continue) { request in
      request.requestedScopes = [.fullName, .email]
      request.nonce = auth.prepareNonce()
    } onCompletion: { result in
      busy = true
      Task {
        let ok = await auth.handle(result)
        busy = false
        if ok { onSuccess() }
      }
    }
    .signInWithAppleButtonStyle(.black)
    .frame(height: 54)
    .clipShape(Capsule())
    .opacity(busy ? 0.6 : 1)
    .disabled(busy)
    .accessibilityLabel(Text("Continue with Apple"))
  }
}
