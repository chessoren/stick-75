import SwiftUI

/// Orange glass card: "Complete today's goals to reach 100 %" with progress bar and a bolt button.
struct HeroGoalCard: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls

  private var progress: Double { store.todayProgress }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .top) {
        Text(headline)
          .font(StickFont.title3)
          .stickTitleTracking()
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 12)
        GlassIconButton(systemImage: "bolt.fill", label: "Call Stick now", tint: .brandOrange, size: 44) {
          calls.start(store.today.goalsSet ? .intercept : .wake, store: store)
        }
      }

      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.white.opacity(0.28))
          .frame(height: 30)
        GeometryReader { geo in
          Capsule()
            .fill(Color.white.opacity(0.92))
            .frame(width: max(30, geo.size.width * progress), height: 30)
            .animation(.smooth(duration: 0.9), value: progress)
        }
        .frame(height: 30)
        HStack {
          Spacer()
          Text(progress, format: .percent.precision(.fractionLength(0)))
            .font(StickFont.footnoteMedium)
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(.white)
            .padding(.trailing, 12)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(Text("Today's progress"))
      .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
    }
    .stickHeroCard()
  }

  private var headline: LocalizedStringKey {
    if progress >= 1 { return "Day held. See you tonight." }
    if !store.today.goalsSet { return "Take the wake-up call to set today's goals" }
    if !store.today.debriefDone, store.todayGoals.allSatisfy(\.isDone) { return "Goals done. Tonight's debrief closes the day." }
    return "Complete today's goals to reach 100%"
  }
}
