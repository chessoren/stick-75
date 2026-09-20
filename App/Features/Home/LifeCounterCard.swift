import SwiftUI

/// Hours won back, converted into real things.
struct LifeCounterCard: View {
  @Environment(StickStore.self) private var store

  private var hours: Int { Int(store.hoursRecovered.rounded()) }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Life recovered")
        .font(StickFont.footnoteMedium)
        .foregroundStyle(.white.opacity(0.8))
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        CountingText(value: hours, font: StickFont.hero, color: .white)
        Text("hours")
          .font(StickFont.title3)
          .foregroundStyle(.white.opacity(0.85))
      }
      HStack(spacing: 10) {
        LifeChip(symbol: "book.fill", value: max(0, hours / 6), unit: "books")
        LifeChip(symbol: "figure.run", value: Int(Double(hours) / 0.75), unit: "runs")
        LifeChip(symbol: "bed.double.fill", value: hours / 8, unit: "nights")
      }
      Text("At \(store.profile.hoursPerDay, format: .number.precision(.fractionLength(1))) h a day, day 75 gives you back \(Int(store.profile.hoursPerDay * 75)) hours.")
        .font(StickFont.footnote)
        .foregroundStyle(.white.opacity(0.8))
        .fixedSize(horizontal: false, vertical: true)
    }
    .stickInkCard()
  }
}

struct LifeChip: View {
  var symbol: String
  var value: Int
  var unit: LocalizedStringKey

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: symbol)
        .font(.system(size: 12, weight: .semibold))
      Text(value, format: .number)
        .monospacedDigit()
        .contentTransition(.numericText())
      Text(unit)
    }
    .font(StickFont.caption)
    .foregroundStyle(.white)
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(Color.white.opacity(0.14), in: Capsule())
  }
}
