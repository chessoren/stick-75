import SwiftUI

/// Share a link that gives friends 5 free days.
struct ReferralView: View {
  @Environment(StickStore.self) private var store
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ZStack {
        StickBackground()
        VStack(spacing: 24) {
          Spacer()
          Image(systemName: "gift.fill")
            .font(.system(size: 64, weight: .semibold))
            .foregroundStyle(.white)
            .padding(28)
            .background(Color.white.opacity(0.2), in: Circle())
            .glassEffect(.regular, in: .circle)
          VStack(spacing: 10) {
            Text("5 free days for a friend.")
              .font(StickFont.largeTitle)
              .stickTitleTracking()
              .multilineTextAlignment(.center)
            Text("They install Stick with your link and start with five days on you. The people who quit together, stay quit.")
              .font(StickFont.body)
              .multilineTextAlignment(.center)
              .opacity(0.9)
          }
          .foregroundStyle(.white)
          .padding(.horizontal, 12)

          Text(store.profile.referralCode)
            .font(StickFont.font(28, .semibold))
            .tracking(6)
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.85), in: Capsule())
            .glassEffect(.regular, in: .capsule)
            .accessibilityLabel(Text("Your referral code"))

          Spacer()

          ShareLink(item: store.referralURL, message: Text(shareMessage)) {
            Label("Share my link", systemImage: "square.and.arrow.up")
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
      ? "Je fais 75 jours sans TikTok avec Stick. Mon téléphone m'appelle avec MA voix. Tu as 5 jours gratuits avec mon lien : "
      : "I'm doing 75 days without TikTok with Stick. My phone calls me with MY voice. You get 5 free days with my link: "
  }
}
