import SwiftUI

/// Weekly league of 30 on hours recovered. No public demotion, ever.
struct LeagueView: View {
  @Environment(StickStore.self) private var store
  @State private var showingReferral = false

  var body: some View {
    NavigationStack {
      ZStack {
        StickBackground(intensity: 0.85)
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 4) {
                Text("League")
                  .font(StickFont.largeTitle)
                  .stickTitleTracking()
                  .foregroundStyle(Color.ink)
                Text("Ranked on hours recovered, not perfection.")
                  .font(StickFont.calloutMedium)
                  .foregroundStyle(Color.ink.opacity(0.7))
              }
              Spacer()
              GlassIconButton(systemImage: "person.badge.plus", label: "Invite a friend", tint: .ink, size: 42) {
                showingReferral = true
              }
            }
            .padding(.top, 6)
            .appear(index: 0)

            rankHero
              .appear(index: 1)

            podium
              .appear(index: 2)

            VStack(spacing: 8) {
              ForEach(Array(store.leaderboard.enumerated()), id: \.element.id) { index, entry in
                LeaderboardRow(entry: entry, rank: index + 1)
                  .padding(.horizontal, 14)
                  .padding(.vertical, 10)
                  .background(entry.isMe ? Color.brandOrange.opacity(0.14) : Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                  .glassEffect(.regular, in: .rect(cornerRadius: 18))
                  .appear(index: min(index, 12))
              }
            }
          }
          .padding(.horizontal, StickMetrics.screenMargin)
          .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
      }
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $showingReferral) {
        ReferralView()
      }
    }
  }

  private var rankHero: some View {
    HStack(alignment: .center, spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        Text("Your rank this week")
          .font(StickFont.footnoteMedium)
          .opacity(0.85)
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("#")
            .font(StickFont.title)
          CountingText(value: store.myRank, font: StickFont.hero, color: .white)
        }
        Text("\(Int(store.hoursRecovered.rounded())) h recovered · \(store.daysHeld) days held")
          .font(StickFont.callout)
          .opacity(0.9)
      }
      Spacer()
      Image(systemName: "trophy.fill")
        .font(.system(size: 44, weight: .semibold))
        .foregroundStyle(.white.opacity(0.9))
    }
    .stickHeroCard()
    .sensoryFeedback(.success, trigger: store.myRank)
  }

  private var podium: some View {
    let top = Array(store.leaderboard.prefix(3))
    return HStack(alignment: .bottom, spacing: 10) {
      ForEach(Array(top.enumerated()), id: \.element.id) { index, entry in
        VStack(spacing: 8) {
          Circle()
            .fill(entry.isMe ? Color.brandOrange : Color(hue: entry.hue, saturation: 0.45, brightness: 0.85))
            .frame(width: index == 0 ? 56 : 46, height: index == 0 ? 56 : 46)
            .overlay {
              Text(entry.initials)
                .font(StickFont.headline)
                .foregroundStyle(.white)
            }
          Text(entry.isMe ? String(localized: "You") : entry.name)
            .font(StickFont.caption)
            .foregroundStyle(Color.ink)
            .lineLimit(1)
          Text("\(Int(entry.hoursRecovered)) h")
            .font(StickFont.footnoteMedium)
            .foregroundStyle(Color.brandOrange)
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.ink.opacity(index == 0 ? 0.9 : 0.15))
            .frame(height: index == 0 ? 54 : (index == 1 ? 40 : 28))
            .overlay {
              Text("\(index + 1)")
                .font(StickFont.headline)
                .foregroundStyle(index == 0 ? .white : Color.ink)
            }
        }
        .frame(maxWidth: .infinity)
      }
    }
    .stickCard()
  }
}
