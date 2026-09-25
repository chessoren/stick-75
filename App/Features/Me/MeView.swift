import SwiftUI

/// Profile, voice, stats, badges, invite, subscription, settings.
struct MeView: View {
  @Environment(StickStore.self) private var store
  @State private var showingInvite = false
  @State private var legal: LegalDocument?

  var body: some View {
    NavigationStack {
      ZStack {
        StickBackground(intensity: 0.85)
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            profileHeader
              .appear(index: 0)

            statsRow
              .appear(index: 1)

            NavigationLink {
              AccountView()
            } label: {
              MeRow(symbol: "person.crop.circle.badge.checkmark", title: "Account", subtitle: AuthService.shared.isSignedIn ? "Signed in with Apple" : "Not signed in")
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 2)

            NavigationLink {
              VoiceSettingsView()
            } label: {
              MeRow(symbol: "waveform", title: "My voice", subtitle: store.profile.voiceModelID == nil ? "Not cloned yet" : "Cloned · used on every call")
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 2)

            NavigationLink {
              if ScreenTimeService.isAvailable {
                BlockedAppsView()
              } else {
                ShortcutAutomationGuide()
              }
            } label: {
              MeRow(symbol: "hand.raised.fill", title: "Interception", subtitle: store.profile.shortcutAutomationSet || ScreenTimeService.shared.isAuthorized ? "Interception armed" : "Interception off · set it up")
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 2)

            NavigationLink {
              BadgesView()
            } label: {
              MeRow(symbol: "rosette", title: "Badges", subtitle: "\(store.state.badges.count) of \(Badge.allCases.count) earned")
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 3)

            Button {
              showingInvite = true
            } label: {
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Image(systemName: "person.2.fill")
                    .font(.system(size: 18, weight: .semibold))
                  Text("Invite a friend")
                    .font(StickFont.headline)
                  Spacer()
                  Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                }
                Text("Send Stick to someone who scrolls too much.")
                  .font(StickFont.callout)
                  .opacity(0.9)
                  .fixedSize(horizontal: false, vertical: true)
              }
              .stickHeroCard()
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 4)

            NavigationLink {
              SubscriptionView()
            } label: {
              MeRow(symbol: "creditcard.fill", title: "Subscription", subtitle: entitlementText)
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 5)

            NavigationLink {
              VaultView()
            } label: {
              MeRow(symbol: "lock.fill", title: "The Vault", subtitle: store.isFinished ? "Open. Listen to day 1." : "Sealed until day 75")
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 6)

            NavigationLink {
              ProgramView()
            } label: {
              MeRow(symbol: "map.fill", title: "The program", subtitle: "Five acts, the rules, the jokers")
            }
            .buttonStyle(PressableButtonStyle())
            .appear(index: 7)

            HStack(spacing: 18) {
              Button("Privacy policy") { legal = .privacy }
              Button("Terms of use") { legal = .terms }
            }
            .font(StickFont.footnoteMedium)
            .foregroundStyle(Color.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
            .appear(index: 8)

            NavigationLink {
              AccountView()
            } label: {
              Text("Delete my account and data")
                .font(StickFont.footnoteMedium)
                .foregroundStyle(Color.stickDanger)
                .frame(maxWidth: .infinity)
            }
            .padding(.top, 4)
            .appear(index: 9)
          }
          .padding(.horizontal, StickMetrics.screenMargin)
          .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
      }
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $showingInvite) {
        InviteView()
      }
      .sheet(item: $legal) { document in
        LegalView(document: document)
      }
    }
  }

  private var profileHeader: some View {
    HStack(spacing: 16) {
      Circle()
        .fill(Color.white.opacity(0.9))
        .frame(width: 64, height: 64)
        .glassEffect(.regular, in: .circle)
        .overlay {
          Text(store.profile.firstName.isEmpty ? "S" : String(store.profile.firstName.prefix(1)).uppercased())
            .font(StickFont.title)
            .foregroundStyle(Color.brandOrange)
        }
      VStack(alignment: .leading, spacing: 4) {
        Text(store.profile.firstName.isEmpty ? String(localized: "You") : store.profile.firstName)
          .font(StickFont.largeTitle)
          .stickTitleTracking()
          .foregroundStyle(Color.ink)
        if !store.profile.identityStatement.isEmpty {
          Text("“\(store.profile.identityStatement)”")
            .font(StickFont.callout)
            .foregroundStyle(Color.ink.opacity(0.7))
            .lineLimit(2)
        }
      }
      Spacer()
    }
    .padding(.top, 6)
  }

  private var statsRow: some View {
    HStack(spacing: 10) {
      StatTile(value: store.daysHeld, label: "days held")
      StatTile(value: Int(store.hoursRecovered.rounded()), label: "hours back")
      StatTile(value: store.jokersLeft, label: "jokers")
    }
  }

  private var entitlementText: LocalizedStringKey {
    switch store.state.entitlement {
    case .pass75: "75-Day Pass"
    case .weekly: "Weekly"
    case .none: "Inactive"
    }
  }
}

struct StatTile: View {
  var value: Int
  var label: LocalizedStringKey

  var body: some View {
    VStack(spacing: 4) {
      CountingText(value: value, font: StickFont.title, color: .ink)
      Text(label)
        .font(StickFont.caption)
        .foregroundStyle(Color.inkSecondary)
    }
    .frame(maxWidth: .infinity)
    .stickCard(padding: 14)
  }
}

struct MeRow: View {
  var symbol: String
  var title: LocalizedStringKey
  var subtitle: LocalizedStringKey

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 40, height: 40)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Text(subtitle)
          .font(StickFont.footnote)
          .foregroundStyle(Color.inkSecondary)
      }
      Spacer()
      Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.ink.opacity(0.4))
    }
    .stickCard(padding: 14, interactive: true)
  }
}
