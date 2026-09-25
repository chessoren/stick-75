import SwiftUI

struct AccountView: View {
  @Environment(StickStore.self) private var store
  @State private var busy = false
  @State private var showingDelete = false
  @State private var voiceDeletionFailed = false

  private var auth: AuthService { .shared }

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: auth.isSignedIn ? "checkmark.seal.fill" : "person.crop.circle.badge.questionmark")
                .foregroundStyle(auth.isSignedIn ? Color.stickSuccess : Color.brandOrange)
              Text(auth.isSignedIn ? "Signed in with Apple" : "No account yet")
                .font(StickFont.headline)
                .foregroundStyle(Color.ink)
            }
            Text(auth.isSignedIn
                 ? "Your purchases are tied to your Apple Account. Your 75 days stay on this iPhone."
                 : "Optional. Sign in with Apple to tie your purchases to your Apple Account. Stick receives no email and no name.")
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

          if auth.isSignedIn {
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
            AppleSignInPill(busy: $busy) {}
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Delete my account and data")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
            Text("Deletes your voice clone at Fish Audio, your recordings, progress, goals and call history on this iPhone, and forgets your Apple sign-in. Purchases stay with your Apple Account.")
              .font(StickFont.callout)
              .foregroundStyle(Color.inkSecondary)
              .fixedSize(horizontal: false, vertical: true)
            Button(role: .destructive) {
              showingDelete = true
            } label: {
              HStack {
                Text("Delete everything")
                if busy { ProgressView() }
              }
              .font(StickFont.headline)
              .foregroundStyle(Color.stickDanger)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 6)
            }
            .disabled(busy)
          }
          .stickCard()
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle("Account")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog("Delete my account and data?", isPresented: $showingDelete, titleVisibility: .visible) {
      Button("Delete everything", role: .destructive) { deleteEverything() }
    } message: {
      Text("Deletes your voice clone, recordings, progress, goals and calls. This cannot be undone.")
    }
    .alert("Your voice clone couldn't be deleted", isPresented: $voiceDeletionFailed) {
      Button("Try again") { deleteEverything() }
      Button("Delete the rest anyway", role: .destructive) {
        Task { await store.deleteAccount() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Stick couldn't reach the voice provider. Check your connection and try again.")
    }
    .task { await auth.refresh() }
  }

  private func deleteEverything() {
    busy = true
    Task {
      do {
        try await store.deleteVoiceClone()
        await store.deleteAccount()
      } catch {
        voiceDeletionFailed = true
      }
      busy = false
    }
  }
}
