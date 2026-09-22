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

        HStack(spacing: 6) {
          ForEach(Act.allCases) { act in
            HStack(spacing: 2.5) {
              ForEach(act.dayRange, id: \.self) { day in
                dot(day)
              }
            }
          }
        }
        .frame(maxWidth: .infinity)
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
  private func dot(_ day: Int) -> some View {
    let record = store.record(forDay: day)
    let isToday = day == store.dayNumber
    Circle()
      .fill(fill(day: day, record: record))
      .frame(width: isToday ? 8 : 5, height: isToday ? 8 : 5)
      .scaleEffect(isToday && pulse ? 1.25 : 1)
      .animation(isToday ? .smooth(duration: 1.1).repeatForever(autoreverses: true) : .default, value: pulse)
      .frame(maxWidth: .infinity)
  }

  private func fill(day: Int, record: DayRecord) -> Color {
    if day < store.dayNumber { return record.isHeld ? .stickSuccess : (record.lapsed ? .stickDanger.opacity(0.7) : Color.ink.opacity(0.18)) }
    if day == store.dayNumber { return .brandOrange }
    return Act.act(forDay: day) == store.currentAct ? Color.brandOrange.opacity(0.25) : Color.ink.opacity(0.08)
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
