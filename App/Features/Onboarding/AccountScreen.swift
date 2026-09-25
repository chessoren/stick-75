import AuthenticationServices
import SwiftUI

/// Onboarding step after the paywall: optional Sign in with Apple, which ties purchases to the Apple identity.
struct AccountScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var busy = false

  private var auth: AuthService { .shared }

  var body: some View {
    OnboardingPage("One account. Yours.", subtitle: "Optional. Sign in with Apple ties your purchases to your Apple Account. You can skip it.") {
      VStack(alignment: .leading, spacing: 12) {
        ConsentRow(symbol: "creditcard.fill", text: "Your pass or subscription follows your Apple Account to a new iPhone.")
        ConsentRow(symbol: "eye.slash.fill", text: "Stick asks Apple for no email and no name. Only an anonymous identifier stays on your phone.")
        ConsentRow(symbol: "iphone", text: "Your 75 days, goals and recordings stay on this iPhone.")
        if let error = auth.lastError {
          Text(error)
            .font(StickFont.footnote)
            .foregroundStyle(Color.stickDanger)
        }
      }
      .padding(.top, 8)
    } footer: {
      if auth.isSignedIn {
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

/// Styled Sign in with Apple button. No scopes: Stick only keeps the anonymous Apple user identifier.
struct AppleSignInPill: View {
  @Binding var busy: Bool
  var onSuccess: () -> Void

  private var auth: AuthService { .shared }

  var body: some View {
    SignInWithAppleButton(.continue) { request in
      request.requestedScopes = []
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
