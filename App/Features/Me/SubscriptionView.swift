import SwiftUI

struct SubscriptionView: View {
  @Environment(StickStore.self) private var store
  @State private var showingPaywall = false

  var body: some View {
    ZStack {
      StickCreamBackground()
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text(planTitle)
            .font(StickFont.title2)
            .foregroundStyle(Color.ink)
          Text(planDetail)
            .font(StickFont.callout)
            .foregroundStyle(Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .stickCard()

        if store.state.entitlement != .life {
          Button {
            showingPaywall = true
          } label: {
            Text(store.isEntitled ? "See plans" : "Unlock Stick")
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }

        Text("Manage or cancel in Settings › Apple Account › Subscriptions.")
          .font(StickFont.footnote)
          .foregroundStyle(Color.inkSecondary)
        Spacer()
      }
      .padding(StickMetrics.screenMargin)
    }
    .navigationTitle("Subscription")
    .navigationBarTitleDisplayMode(.inline)
    .fullScreenCover(isPresented: $showingPaywall) {
      PaywallView(onUnlocked: { showingPaywall = false }, onDismiss: { showingPaywall = false })
    }
  }

  private var planTitle: LocalizedStringKey {
    switch store.state.entitlement {
    case .pass75: "75-Day Pass"
    case .weekly: "Weekly"
    case .life: "Stick Life"
    case .trialDays: "Free days from a friend"
    case .none: "No active plan"
    }
  }

  private var planDetail: LocalizedStringKey {
    switch store.state.entitlement {
    case .pass75: "The whole program is yours. Stick Life is offered at day 60 for what comes after."
    case .weekly: "Renews weekly. Switch to the 75-Day Pass to save about €30 over the program."
    case .life: "Maintenance mode, new seasons and leagues, forever."
    case .trialDays: "\(store.freeDaysLeft) days left. Pick a plan to keep going."
    case .none: "Stick calls only paying members. Pick a plan."
    }
  }
}
