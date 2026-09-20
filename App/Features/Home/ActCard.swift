import SwiftUI

/// Current act of the 75 days with a 15-day progress track.
struct ActCard: View {
  @Environment(StickStore.self) private var store

  var body: some View {
    NavigationLink {
      ProgramView()
    } label: {
      VStack(alignment: .leading, spacing: 14) {
        HStack {
          Image(systemName: store.currentAct.symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.brandOrange)
            .frame(width: 40, height: 40)
            .background(Color.brandOrange.opacity(0.12), in: Circle())
          VStack(alignment: .leading, spacing: 2) {
            Text("Act \(store.currentAct.numeral) · \(Text(store.currentAct.name))")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
            Text("Day \(store.dayInAct) of 15")
              .font(StickFont.footnote)
              .foregroundStyle(Color.inkSecondary)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.ink.opacity(0.4))
        }

        HStack(spacing: 4) {
          ForEach(1...Act.length, id: \.self) { day in
            let absolute = store.currentAct.dayRange.lowerBound + day - 1
            let record = store.record(forDay: absolute)
            Capsule()
              .fill(fill(for: absolute, record: record))
              .frame(height: 6)
          }
        }
        .accessibilityHidden(true)

        Text(store.currentAct.focus)
          .font(StickFont.callout)
          .foregroundStyle(Color.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .stickCard(interactive: true)
    }
    .buttonStyle(PressableButtonStyle())
  }

  private func fill(for day: Int, record: DayRecord) -> Color {
    if day < store.dayNumber {
      return record.isHeld ? .stickSuccess : (record.lapsed ? .stickDanger.opacity(0.7) : Color.ink.opacity(0.18))
    }
    if day == store.dayNumber { return .brandOrange }
    return Color.ink.opacity(0.1)
  }
}

/// The five acts, rules, and jokers.
struct ProgramView: View {
  @Environment(StickStore.self) private var store

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          Text("75 days. Five acts.")
            .font(StickFont.largeTitle)
            .stickTitleTracking()
            .foregroundStyle(Color.ink)
            .padding(.bottom, 4)

          ForEach(Array(Act.allCases.enumerated()), id: \.element.id) { index, act in
            HStack(alignment: .top, spacing: 14) {
              Image(systemName: act.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(act == store.currentAct ? .white : Color.brandOrange)
                .frame(width: 38, height: 38)
                .background(act == store.currentAct ? Color.brandOrange : Color.brandOrange.opacity(0.12), in: Circle())
              VStack(alignment: .leading, spacing: 4) {
                Text("Act \(act.numeral) · \(Text(act.name))")
                  .font(StickFont.headline)
                  .foregroundStyle(Color.ink)
                Text("Days \(act.dayRange.lowerBound)–\(act.dayRange.upperBound)")
                  .font(StickFont.caption)
                  .foregroundStyle(Color.inkSecondary)
                Text(act.focus)
                  .font(StickFont.callout)
                  .foregroundStyle(Color.inkSecondary)
                  .fixedSize(horizontal: false, vertical: true)
              }
              Spacer()
            }
            .stickCard()
            .appear(index: index)
          }

          VStack(alignment: .leading, spacing: 10) {
            Text("The rules")
              .font(StickFont.title3)
              .foregroundStyle(Color.ink)
            RuleRow(symbol: "checkmark.circle.fill", text: "A day is held when goals are set, nothing slipped, and the debrief is done.")
            RuleRow(symbol: "heart.fill", text: "3 jokers for the whole program. A slip costs one and triggers a recovery call. Never miss twice.")
            RuleRow(symbol: "arrow.counterclockwise", text: "Two missed days in a row restart the act. Never the program. You never go back to day 1.")
            RuleRow(symbol: "xmark.circle", text: "Jokers can't be bought. Not with money, not with words.")
          }
          .stickCard()
          .appear(index: 6)
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 100)
      }
    }
    .navigationTitle("The program")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct RuleRow: View {
  var symbol: String
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: symbol)
        .foregroundStyle(Color.brandOrange)
        .frame(width: 22)
      Text(text)
        .font(StickFont.callout)
        .foregroundStyle(Color.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
