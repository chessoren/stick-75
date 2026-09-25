import SwiftUI

/// Invite a friend: a plain share of the App Store page. No reward, no code (App Review 3.1.1).
struct InviteView: View {
  @Environment(StickStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        StickBackground()
        VStack(spacing: 24) {
          Spacer()
          Image(systemName: "person.2.fill")
            .font(.system(size: 60, weight: .semibold))
            .foregroundStyle(.white)
            .padding(28)
            .background(Color.white.opacity(0.2), in: Circle())
            .glassEffect(.regular, in: .circle)
          VStack(spacing: 10) {
            Text("Don't do it alone.")
              .font(StickFont.largeTitle)
              .stickTitleTracking()
              .multilineTextAlignment(.center)
            Text("Send Stick to a friend who scrolls too much. The people who quit together, stay quit.")
              .font(StickFont.body)
              .multilineTextAlignment(.center)
              .opacity(0.9)
          }
          .foregroundStyle(.white)
          .padding(.horizontal, 12)

          Spacer()

          Group {
            if let url = AppLinks.appStoreURL {
              ShareLink(item: url, message: Text(shareMessage)) {
                Label("Invite a friend", systemImage: "square.and.arrow.up")
              }
            } else {
              ShareLink(item: shareMessage) {
                Label("Invite a friend", systemImage: "square.and.arrow.up")
              }
            }
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .padding(.bottom, 16)
        }
        .padding(.horizontal, StickMetrics.screenMargin)
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private var shareMessage: String {
    store.profile.language == .french
      ? "Je fais 75 jours sans TikTok avec Stick. Mon téléphone m'appelle avec MA voix. Essaie :"
      : "I'm doing 75 days without TikTok with Stick. My phone calls me with MY voice. Try it:"
  }
}
