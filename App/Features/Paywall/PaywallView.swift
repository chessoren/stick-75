import SwiftUI

/// Hard paywall. No trial. Pass 75 preselected. Shown after the aha call and the contract.
struct PaywallView: View {
  @Environment(StickStore.self) private var store
  var onUnlocked: () -> Void
  var onDismiss: (() -> Void)?

  @State private var selected: SubscriptionPlan = .pass75
  @State private var purchases = PurchaseService.shared
  @State private var error: String?

  var body: some View {
    ZStack {
      StickBackground()
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            HStack {
              Spacer()
              if let onDismiss {
                Button(action: onDismiss) {
                  Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.7), in: Circle())
                    .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(Text("Close"))
              }
            }
            .frame(height: 34)

            VStack(alignment: .leading, spacing: 8) {
              Text("Your voice is ready. Now commit.")
                .font(StickFont.largeTitle)
                .stickTitleTracking()
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
              Text("Stick only calls paying members. No free trial: a trial is a way out, and you're done with those.")
                .font(StickFont.body)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            }
            .appear(index: 0)

            timeline
              .appear(index: 1)

            VStack(spacing: 10) {
              ForEach(Array(SubscriptionPlan.allCases.enumerated()), id: \.element.id) { index, plan in
                PlanCard(plan: plan, price: purchases.prices[plan] ?? plan.fallbackPrice, isSelected: selected == plan) {
                  withAnimation(.snappy(duration: 0.3)) { selected = plan }
                }
                .appear(index: index + 2)
              }
            }

            proof
              .appear(index: 5)

            if let error {
              Text(error)
                .font(StickFont.footnote)
                .foregroundStyle(.white)
                .padding(12)
                .background(Color.stickDanger.opacity(0.8), in: RoundedRectangle(cornerRadius: 14))
            }
          }
          .padding(.horizontal, StickMetrics.screenMargin)
          .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)

        VStack(spacing: 10) {
          Button {
            buy()
          } label: {
            HStack {
              Text(ctaTitle)
              if purchases.isBusy { ProgressView().tint(.white) }
            }
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(purchases.isBusy)

          HStack(spacing: 18) {
            Button("Restore") { restore() }
            Link("Terms", destination: URL(string: "https://stick.app/terms")!)
            Link("Privacy", destination: URL(string: "https://stick.app/privacy")!)
          }
          .font(StickFont.footnoteMedium)
          .foregroundStyle(.white.opacity(0.85))
          Text(selected == .pass75 ? "One-time payment. No renewal." : "Auto-renews. Cancel any time in Settings.")
            .font(StickFont.caption)
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 12)
      }
    }
    .task { await purchases.refreshPrices() }
  }

  private var timeline: some View {
    VStack(alignment: .leading, spacing: 12) {
      TimelineRow(symbol: "phone.fill", title: "Tomorrow morning", text: "Your voice wakes you and takes your first three goals.")
      TimelineRow(symbol: "hand.raised.fill", title: "The first time you open TikTok", text: "It rings. You answer to yourself.")
      TimelineRow(symbol: "flag.fill", title: "Day 15", text: "Act I done. The hardest part is behind you.")
      TimelineRow(symbol: "crown.fill", title: "Day 75", text: "\(Int(store.profile.hoursPerDay * 75)) hours back. The vault opens.")
    }
    .stickCard()
  }

  private var proof: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 4) {
        ForEach(0..<5, id: \.self) { _ in
          Image(systemName: "star.fill")
            .font(.system(size: 12))
            .foregroundStyle(Color.brandOrange)
        }
      }
      Text("“I've deleted TikTok four times. Hearing my own voice tell me to close it is the only thing that has ever worked.”")
        .font(StickFont.callout)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
      Text("Léa, day 41")
        .font(StickFont.caption)
        .foregroundStyle(Color.inkSecondary)
    }
    .stickCard()
  }

  private var ctaTitle: LocalizedStringKey {
    switch selected {
    case .pass75: "Start my 75 days · \(purchases.prices[.pass75] ?? SubscriptionPlan.pass75.fallbackPrice)"
    case .weekly: "Start weekly · \(purchases.prices[.weekly] ?? SubscriptionPlan.weekly.fallbackPrice)"
    case .life: "Join Stick Life · \(purchases.prices[.life] ?? SubscriptionPlan.life.fallbackPrice)"
    }
  }

  private func buy() {
    error = nil
    Task {
      if let entitlement = await purchases.purchase(selected) {
        store.grant(entitlement)
        StickHaptics.shared.rankUp()
        onUnlocked()
      } else {
        error = purchases.lastError ?? String(localized: "Purchase didn't go through. Try again.")
      }
    }
  }

  private func restore() {
    Task {
      if let entitlement = await purchases.restore() {
        store.grant(entitlement)
        onUnlocked()
      } else {
        error = String(localized: "Nothing to restore on this Apple Account.")
      }
    }
  }
}

struct PlanCard: View {
  var plan: SubscriptionPlan
  var price: String
  var isSelected: Bool
  var select: () -> Void

  var body: some View {
    Button(action: select) {
      HStack(spacing: 14) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(plan.title)
              .font(StickFont.headline)
              .foregroundStyle(isSelected ? .white : Color.ink)
            if plan.isHero {
              Text("Best value")
                .font(StickFont.caption2)
                .foregroundStyle(isSelected ? Color.ink : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.white : Color.brandOrange, in: Capsule())
            }
          }
          Text(plan.subtitle)
            .font(StickFont.footnote)
            .foregroundStyle(isSelected ? .white.opacity(0.85) : Color.inkSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        Spacer()
        Text(price)
          .font(StickFont.headline)
          .monospacedDigit()
          .foregroundStyle(isSelected ? .white : Color.ink)
          .multilineTextAlignment(.trailing)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isSelected ? Color.ink : Color.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
      .glassEffect(isSelected ? .regular.tint(.ink) : .regular.interactive(), in: .rect(cornerRadius: 22))
      .overlay {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .strokeBorder(Color.white.opacity(isSelected ? 0.15 : 0.5), lineWidth: 0.5)
      }
    }
    .buttonStyle(PressableButtonStyle())
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityLabel(Text(plan.title))
    .accessibilityValue(Text(price))
  }
}

struct TimelineRow: View {
  var symbol: String
  var title: LocalizedStringKey
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.white)
        .frame(width: 30, height: 30)
        .background(Color.brandOrange, in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Text(text)
          .font(StickFont.footnote)
          .foregroundStyle(Color.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
