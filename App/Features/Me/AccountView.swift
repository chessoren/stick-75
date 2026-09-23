import SwiftUI

struct AccountView: View {
  @Environment(StickStore.self) private var store
  @State private var busy = false
  @State private var showingDelete = false

  private var auth: AuthService { .shared }

  var body: some View {
    ZStack {
      StickCreamBackground()
      VStack(alignment: .leading, spacing: 14) {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Image(systemName: auth.isSignedIn ? "checkmark.seal.fill" : "person.crop.circle.badge.questionmark")
              .foregroundStyle(auth.isSignedIn ? Color.stickSuccess : Color.brandOrange)
            Text(auth.isSignedIn ? "Signed in with Apple" : "No account yet")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
          }
          if let email = auth.email, auth.isSignedIn {
            Text(email)
              .font(StickFont.footnote)
              .foregroundStyle(Color.inkSecondary)
          }
          Text(auth.isSignedIn
               ? "Your progress, league rank and purchases follow you to a new iPhone."
               : "Sign in to join the league, give friends 5 free days, and keep your 75 days if you change phones.")
            .font(StickFont.callout)
            .foregroundStyle(Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
          if let error = auth.lastError {
            Text(error)
              .font(StickFont.footnote)
              .foregroundStyle(Color.stickDanger)
          }
        }
        .stickCard()

        if !auth.isConfigured {
          Text("Accounts are not connected yet on this build.")
            .font(StickFont.footnote)
            .foregroundStyle(Color.inkSecondary)
        } else if auth.isSignedIn {
          Button {
            busy = true
            Task {
              await auth.signOut()
              busy = false
            }
          } label: {
            Text("Sign out")
          }
          .buttonStyle(SecondaryPillButtonStyle())
          .disabled(busy)
        } else {
          AppleSignInPill(busy: $busy) {
            Task { await store.syncRemote() }
          }
        }

        Button(role: .destructive) {
          showingDelete = true
        } label: {
          Text("Delete my account and data")
            .font(StickFont.footnoteMedium)
            .foregroundStyle(Color.stickDanger)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        Spacer()
      }
      .padding(StickMetrics.screenMargin)
    }
    .navigationTitle("Account")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog("Delete my account and data?", isPresented: $showingDelete, titleVisibility: .visible) {
      Button("Delete everything", role: .destructive) { store.resetEverything() }
    } message: {
      Text("Deletes your account, league score, progress, goals, calls and voice clone. This cannot be undone.")
    }
    .task { await auth.refresh() }
  }
}
