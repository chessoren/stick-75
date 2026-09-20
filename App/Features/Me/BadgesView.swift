import SwiftUI

struct BadgesView: View {
  @Environment(StickStore.self) private var store

  private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(Array(Badge.allCases.enumerated()), id: \.element.id) { index, badge in
            let earned = store.state.badges.contains(badge)
            VStack(spacing: 10) {
              Image(systemName: badge.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(earned ? .white : Color.ink.opacity(0.3))
                .frame(width: 60, height: 60)
                .background(earned ? Color.brandOrange : Color.ink.opacity(0.08), in: Circle())
              Text(badge.title)
                .font(StickFont.footnoteMedium)
                .foregroundStyle(earned ? Color.ink : Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .stickCard(padding: 12)
            .opacity(earned ? 1 : 0.75)
            .appear(index: index)
          }
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle("Badges")
    .navigationBarTitleDisplayMode(.inline)
  }
}
