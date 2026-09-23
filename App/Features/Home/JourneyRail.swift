import SwiftUI

/// The 75 days in one strip: five acts, fifteen dots each, today pulsing, future acts locked.
struct JourneyRail: View {
  @Environment(StickStore.self) private var store
  @State private var pulse = false

  var body: some View {
    NavigationLink {
      ProgramView()
    } label: {
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .firstTextBaseline) {
          Text("Act \(store.currentAct.numeral) · \(Text(store.currentAct.name))")
            .font(StickFont.headline)
            .foregroundStyle(Color.ink)
          Spacer()
          if let days = store.daysUntilNextReveal, let next = store.currentAct.next {
            HStack(spacing: 4) {
              Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .bold))
              Text(days == 0 ? "New today" : "Next reveal in \(days) d")
                .font(StickFont.caption)
            }
            .foregroundStyle(Color.brandOrange)
            .accessibilityLabel(Text("Act \(next.numeral) opens in \(days) days"))
          } else {
            Text("Last act")
              .font(StickFont.caption)
              .foregroundStyle(Color.brandOrange)
          }
        }

        // Five act bars that always fit the width: held days in green, today's position pulsing.
        HStack(spacing: 5) {
          ForEach(Act.allCases) { act in
            actBar(act)
          }
        }
        .frame(height: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Day \(store.dayNumber) of 75"))

        HStack(spacing: 6) {
          ForEach(Act.allCases) { act in
            let state = actState(act)
            HStack(spacing: 3) {
              if state == .locked {
                Image(systemName: "lock.fill")
                  .font(.system(size: 8, weight: .bold))
              }
              Text(act.numeral)
                .font(StickFont.caption2)
            }
            .foregroundStyle(state == .current ? Color.brandOrange : (state == .done ? Color.stickSuccess : Color.ink.opacity(0.4)))
            .frame(maxWidth: .infinity)
          }
        }
      }
      .stickCard(padding: 14, interactive: true)
    }
    .buttonStyle(PressableButtonStyle())
    .onAppear { pulse = true }
  }

  private enum ActState { case done, current, locked }

  private func actState(_ act: Act) -> ActState {
    if act.rawValue < store.currentAct.rawValue { return .done }
    if act == store.currentAct { return .current }
    return .locked
  }

  @ViewBuilder
  private func actBar(_ act: Act) -> some View {
    let state = actState(act)
    GeometryReader { geo in
      let width = geo.size.width
      let daysInto = state == .done ? Act.length : (state == .current ? store.dayInAct : 0)
      let heldInAct = act.dayRange.filter { store.record(forDay: $0).isHeld }.count
      let lapsedInAct = act.dayRange.filter { $0 < store.dayNumber && store.record(forDay: $0).lapsed && !store.record(forDay: $0).isHeld }.count
      ZStack(alignment: .leading) {
        Capsule()
          .fill(state == .locked ? Color.ink.opacity(0.08) : Color.brandOrange.opacity(0.18))
        if daysInto > 0 {
          Capsule()
            .fill(Color.brandOrange.opacity(0.35))
            .frame(width: width * CGFloat(daysInto) / CGFloat(Act.length))
        }
        if heldInAct > 0 {
          Capsule()
            .fill(Color.stickSuccess)
            .frame(width: width * CGFloat(heldInAct) / CGFloat(Act.length))
        }
        if lapsedInAct > 0 {
          Capsule()
            .fill(Color.stickDanger.opacity(0.6))
            .frame(width: width * CGFloat(lapsedInAct) / CGFloat(Act.length))
            .offset(x: width * CGFloat(heldInAct) / CGFloat(Act.length))
        }
        if state == .current {
          Circle()
            .fill(Color.brandOrange)
            .frame(width: 12, height: 12)
            .overlay(Circle().strokeBorder(Color.white, lineWidth: 2))
            .scaleEffect(pulse ? 1.2 : 1)
            .animation(.smooth(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
            .offset(x: min(width - 12, max(0, width * CGFloat(store.dayInAct - 1) / CGFloat(Act.length))))
        }
      }
    }
    .frame(height: 10)
  }
}

/// A feature you can see but not use yet.
struct LockedFeatureCard: View {
  @Environment(StickStore.self) private var store
  var feature: Feature

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "lock.fill")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Color.ink.opacity(0.5))
        .frame(width: 40, height: 40)
        .background(Color.ink.opacity(0.06), in: Circle())
      VStack(alignment: .leading, spacing: 3) {
        Text(feature.title)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink.opacity(0.75))
        Text(feature.detail)
          .font(StickFont.footnote)
          .foregroundStyle(Color.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer()
      VStack(spacing: 2) {
        Text("\(store.daysUntil(feature))")
          .font(StickFont.title3)
          .monospacedDigit()
          .foregroundStyle(Color.brandOrange)
        Text("days")
          .font(StickFont.caption2)
          .foregroundStyle(Color.inkSecondary)
      }
    }
    .stickCard(padding: 14)
    .opacity(0.92)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text("\(Text(feature.title)), unlocks in \(store.daysUntil(feature)) days"))
  }
}

/// Act II+: the replacement habit chosen on the morning call.
struct HabitCard: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: "leaf.fill")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.stickSuccess)
        .frame(width: 40, height: 40)
        .background(Color.stickSuccess.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 3) {
        Text("Habit of the day")
          .font(StickFont.caption)
          .foregroundStyle(Color.inkSecondary)
        Text(store.today.habit ?? String(localized: "Stick asks for it on the wake-up call."))
          .font(StickFont.headline)
          .foregroundStyle(store.today.habit == nil ? Color.inkSecondary : Color.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer()
    }
    .stickCard(padding: 14)
  }
}

/// Act IV+: weekly trials on the honor system.
struct TrialsSection: View {
  @Environment(StickStore.self) private var store

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      StickSectionHeader("This week's trials") {
        Text("\(store.state.trialsDone.count)/\(Trial.allCases.count)")
          .font(StickFont.footnoteMedium)
          .monospacedDigit()
          .foregroundStyle(Color.brandOrange)
      }
      ForEach(Array(Trial.allCases.enumerated()), id: \.element.id) { index, trial in
        let done = store.state.trialsDone.contains(trial)
        Button {
          store.toggleTrial(trial)
        } label: {
          HStack(spacing: 14) {
            Image(systemName: trial.symbol)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(done ? .white : Color.brandOrange)
              .frame(width: 40, height: 40)
              .background(done ? Color.stickSuccess : Color.brandOrange.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
              Text(trial.title)
                .font(StickFont.headline)
                .foregroundStyle(Color.ink)
                .strikethrough(done, color: Color.inkSecondary)
              Text(trial.detail)
                .font(StickFont.footnote)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(done ? Color.stickSuccess : Color.ink.opacity(0.25))
          }
          .stickCard(padding: 14, interactive: true)
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.success, trigger: done) { _, new in new }
        .appear(index: index)
        .accessibilityAddTraits(done ? .isSelected : [])
      }
    }
  }
}

/// Act V: what stays after day 75, collected by the morning calls.
struct PostPlanCard: View {
  @Environment(StickStore.self) private var store

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Image(systemName: "map.fill")
          .foregroundStyle(Color.brandOrange)
        Text("After day 75")
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Spacer()
        Text("\(store.state.postPlanNotes.count)")
          .font(StickFont.footnoteMedium)
          .monospacedDigit()
          .foregroundStyle(Color.brandOrange)
      }
      if store.state.postPlanNotes.isEmpty {
        Text("Every morning Stick asks for one rule you keep. They land here.")
          .font(StickFont.callout)
          .foregroundStyle(Color.inkSecondary)
      } else {
        ForEach(Array(store.state.postPlanNotes.suffix(5).enumerated()), id: \.offset) { _, note in
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark")
              .font(.system(size: 11, weight: .bold))
              .foregroundStyle(Color.brandOrange)
              .padding(.top, 3)
            Text(note)
              .font(StickFont.callout)
              .foregroundStyle(Color.ink)
          }
        }
      }
    }
    .stickCard()
  }
}
