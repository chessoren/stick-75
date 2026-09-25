import SwiftUI

/// Hard paywall. No trial. Pass 75 preselected. Shown after the aha call and the contract.
struct PaywallView: View {
  @Environment(StickStore.self) private var store
  var onUnlocked: () -> Void
  var onDismiss: (() -> Void)?
  /// Onboarding shows only the 75 days; Weekly sits behind a small link.
  var ticketMode = false

  @State private var selected: SubscriptionPlan = .pass75
  private var purchases: PurchaseService { .shared }
  @State private var error: String?
  @State private var legal: LegalDocument?
  @State private var showOtherPlans = false

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
              Text(ticketMode ? "Your ticket for the 75 days." : "Your voice is ready. Now commit.")
                .font(StickFont.largeTitle)
                .stickTitleTracking()
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
              Text(ticketMode
                   ? "Act I starts today. First call tomorrow at \(store.profile.wakeTime.date, format: .dateTime.hour().minute()). Stick only calls members. No free trial: a trial is a way out, and you're done with those."
                   : "Stick only calls paying members. No free trial: a trial is a way out, and you're done with those.")
                .font(StickFont.body)
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            }
            .appear(index: 0)

            if ticketMode {
              TicketCard(price: purchases.prices[.pass75] ?? SubscriptionPlan.pass75.fallbackPrice, perDay: purchases.passPricePerDay, hoursPerDay: store.profile.hoursPerDay)
                .appear(index: 1)
              timeline
                .appear(index: 2)
              if showOtherPlans {
                PlanCard(plan: .weekly, price: purchases.prices[.weekly] ?? SubscriptionPlan.weekly.fallbackPrice, isSelected: selected == .weekly) {
                  withAnimation(.snappy(duration: 0.3)) { selected = .weekly }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                PlanCard(plan: .pass75, price: purchases.prices[.pass75] ?? SubscriptionPlan.pass75.fallbackPrice, isSelected: selected == .pass75) {
                  withAnimation(.snappy(duration: 0.3)) { selected = .pass75 }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
              } else {
                Button {
                  withAnimation(.smooth(duration: 0.35)) { showOtherPlans = true }
                } label: {
                  Text("I'd rather try one week first")
                    .font(StickFont.footnoteMedium)
                    .foregroundStyle(.white.opacity(0.85))
                    .underline()
                    .frame(maxWidth: .infinity)
                }
                .appear(index: 3)
              }
            } else {
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
            Button("Terms of use") { legal = .terms }
            Button("Privacy policy") { legal = .privacy }
          }
          .font(StickFont.footnoteMedium)
          .foregroundStyle(.white.opacity(0.85))
          Text(disclosure)
            .font(StickFont.caption)
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 12)
      }
    }
    .task { await purchases.refreshPrices() }
    .sheet(item: $legal) { document in
      LegalView(document: document)
    }
  }

  private var disclosure: LocalizedStringKey {
    let price = purchases.prices[selected] ?? selected.fallbackPrice
    switch selected {
    case .pass75: return "One-time payment of \(price). Not a subscription, nothing renews."
    case .weekly: return "Auto-renewing subscription, \(price). Charged to your Apple Account at confirmation, then every week until cancelled. Cancel in Settings › Apple Account › Subscriptions at least 24 h before renewal."
    }
  }

  private var timeline: some View {
    VStack(alignment: .leading, spacing: 12) {
      TimelineRow(symbol: "phone.fill", title: "Tomorrow morning", text: "Your voice wakes you and takes your first three goals.")
      TimelineRow(symbol: "hand.raised.fill", title: "The first time you open TikTok", text: "It rings. You answer to yourself.")
      TimelineRow(symbol: "arrow.uturn.forward", title: "Day 16 · Act II", text: "The life counter opens. Stick starts building habits with you.")
      TimelineRow(symbol: "person.fill.checkmark", title: "Day 31 · Act III", text: "Your voice badges open. Stick stops ordering, starts asking.")
      TimelineRow(symbol: "timer", title: "Day 46 · Act IV", text: "The shield comes off. Weekly trials. Stick tests you.")
      TimelineRow(symbol: "crown.fill", title: "Day 75", text: "\(Int(store.profile.hoursPerDay * 75)) hours back. The vault opens.")
    }
    .stickCard()
  }

  private var proof: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Why 75 days")
        .font(StickFont.headline)
        .foregroundStyle(Color.ink)
      ProofRow(symbol: "clock.fill", text: "\(Int(store.profile.hoursPerDay * 365)) hours a year at your pace. That's \(Int(store.profile.hoursPerDay * 365 / 24)) full days.")
      ProofRow(symbol: "brain.head.profile", text: "A new habit takes a median of 66 days to become automatic (Lally et al., 2010). 75 gives you margin.")
      ProofRow(symbol: "waveform", text: "You can ignore a coach. Nobody ignores their own voice.")
    }
    .stickCard()
  }

  private var ctaTitle: LocalizedStringKey {
    switch selected {
    case .pass75: ticketMode ? "Take my ticket · \(purchases.prices[.pass75] ?? SubscriptionPlan.pass75.fallbackPrice)" : "Start my 75 days · \(purchases.prices[.pass75] ?? SubscriptionPlan.pass75.fallbackPrice)"
    case .weekly: "Subscribe · \(purchases.prices[.weekly] ?? SubscriptionPlan.weekly.fallbackPrice)"
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
        error = purchases.lastError ?? String(localized: "Nothing to restore on this Apple Account.")
      }
    }
  }
}

/// The single hero product in onboarding: the 75 days as a ticket, price per day next to the hours they lose.
struct TicketCard: View {
  var price: String
  var perDay: String
  var hoursPerDay: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          Text("The 75 days")
            .font(StickFont.title2)
            .stickTitleTracking()
          Text("One payment. Five acts. Every call, every reveal, the Vault.")
            .font(StickFont.footnote)
            .opacity(0.9)
        }
        Spacer()
        Image(systemName: "ticket.fill")
          .font(.system(size: 22, weight: .semibold))
          .opacity(0.9)
      }
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Text(price)
          .font(StickFont.hero)
          .monospacedDigit()
        Text("≈ \(perDay) a day")
          .font(StickFont.calloutMedium)
          .opacity(0.9)
      }
      Text("Less than the \(hoursPerDay, format: .number.precision(.fractionLength(1))) hours a day you're paying now.")
        .font(StickFont.footnote)
        .opacity(0.9)
      HStack(spacing: 6) {
        ForEach(Act.allCases) { act in
          Capsule()
            .fill(Color.white.opacity(0.9))
            .frame(height: 5)
        }
      }
    }
    .stickHeroCard()
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

struct ProofRow: View {
  var symbol: String
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 26)
      Text(text)
        .font(StickFont.callout)
        .foregroundStyle(Color.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
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
