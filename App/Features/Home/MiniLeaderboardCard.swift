import SwiftUI

/// Your rank and the two people around you.
struct MiniLeaderboardCard: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls

  var body: some View {
    if store.leagueIsLive { card }
  }

  private var card: some View {
    Button {
      calls.selectedTab = .league
    } label: {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text("League")
            .font(StickFont.headline)
            .foregroundStyle(Color.ink)
          Spacer()
          Text("#\(store.myRank)")
            .font(StickFont.headline)
            .monospacedDigit()
            .foregroundStyle(Color.brandOrange)
            .contentTransition(.numericText())
        }
        ForEach(neighbours) { entry in
          LeaderboardRow(entry: entry, rank: (store.leaderboard.firstIndex(of: entry) ?? 0) + 1, compact: true)
        }
      }
      .stickCard(interactive: true)
    }
    .buttonStyle(PressableButtonStyle())
    .accessibilityLabel(Text("League, rank \(store.myRank)"))
  }

  private var neighbours: [LeaderboardEntry] {
    let board = store.leaderboard
    guard let me = board.firstIndex(where: \.isMe) else { return Array(board.prefix(3)) }
    let start = max(0, me - 1)
    let end = min(board.count, start + 3)
    return Array(board[start..<end])
  }
}

struct LeaderboardRow: View {
  var entry: LeaderboardEntry
  var rank: Int
  var compact = false

  var body: some View {
    HStack(spacing: 12) {
      Text("\(rank)")
        .font(StickFont.footnoteMedium)
        .monospacedDigit()
        .foregroundStyle(Color.inkSecondary)
        .frame(width: 24, alignment: .leading)
      Circle()
        .fill(entry.isMe ? Color.brandOrange : Color(hue: entry.hue, saturation: 0.45, brightness: 0.85))
        .frame(width: compact ? 30 : 38, height: compact ? 30 : 38)
        .overlay {
          Text(entry.initials)
            .font(compact ? StickFont.caption : StickFont.footnoteMedium)
            .foregroundStyle(.white)
        }
      VStack(alignment: .leading, spacing: 1) {
        Text(entry.isMe ? String(localized: "You") : entry.name)
          .font(compact ? StickFont.calloutMedium : StickFont.bodyMedium)
          .foregroundStyle(Color.ink)
        if !compact {
          Text("\(entry.daysHeld) days held")
            .font(StickFont.caption)
            .foregroundStyle(Color.inkSecondary)
        }
      }
      Spacer()
      HStack(spacing: 3) {
        Text(entry.hoursRecovered, format: .number.precision(.fractionLength(0)))
          .monospacedDigit()
        Text("h")
      }
      .font(compact ? StickFont.calloutMedium : StickFont.headline)
      .foregroundStyle(entry.isMe ? Color.brandOrange : Color.ink)
    }
    .padding(.vertical, compact ? 0 : 4)
  }
}
