import SwiftUI

struct SubscriptionView: View {
  @Environment(StickStore.self) private var store
  @State private var showingPaywall = false
  @State private var restoring = false
  @State private var message: String?

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

        if store.state.entitlement != .pass75 {
          Button {
            showingPaywall = true
          } label: {
            Text(store.isEntitled ? "See plans" : "Unlock Stick")
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }

        Button {
          restoring = true
          Task {
            if let entitlement = await PurchaseService.shared.restore() {
              store.grant(entitlement)
              message = String(localized: "Purchases restored.")
            } else {
              message = PurchaseService.shared.lastError ?? String(localized: "Nothing to restore on this Apple Account.")
            }
            restoring = false
          }
        } label: {
          Text("Restore purchases")
        }
        .buttonStyle(SecondaryPillButtonStyle())
        .disabled(restoring)

        if let message {
          Text(message)
            .font(StickFont.footnote)
            .foregroundStyle(Color.inkSecondary)
        }

        if store.state.entitlement == .weekly, let url = URL(string: "https://apps.apple.com/account/subscriptions") {
          Link(destination: url) {
            Text("Manage subscription")
              .font(StickFont.headline)
              .foregroundStyle(Color.brandOrange)
          }
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
    case .none: "No active plan"
    }
  }

  private var planDetail: LocalizedStringKey {
    switch store.state.entitlement {
    case .pass75: "The whole program is yours. One payment, nothing renews."
    case .weekly: "Renews every week until you cancel. The 75-Day Pass covers the whole program in one payment."
    case .none: "Stick calls only paying members. Pick a plan."
    }
  }
}
