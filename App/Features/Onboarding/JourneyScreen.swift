import SwiftUI

/// "Your 75 days": the five acts drawn as a path, personalized with the quiz answers, each with what it unlocks.
struct JourneyScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var revealed = 0

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          VStack(alignment: .leading, spacing: 8) {
            Text("Your 75 days.")
              .font(StickFont.largeTitle)
              .stickTitleTracking()
              .foregroundStyle(.white)
            Text("Five acts. Stick changes at every one. So do you.")
              .font(StickFont.body)
              .foregroundStyle(.white.opacity(0.9))
          }
          .padding(.top, 12)
          .appear(index: 0)

          JourneyPath(revealed: revealed, apps: model.draft.timeSinks, dream: model.draft.dreams.first, identity: model.draft.identityStatement)
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 24)
      }
      .scrollIndicators(.hidden)

      Button { model.next() } label: { Text("I want this") }
        .buttonStyle(PrimaryPillButtonStyle())
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 12)
        .opacity(revealed >= Act.allCases.count ? 1 : 0.4)
    }
    .task {
      for i in 1...Act.allCases.count {
        try? await Task.sleep(for: .milliseconds(i == 1 ? 350 : 420))
        withAnimation(.bouncy(duration: 0.6)) { revealed = i }
        StickHaptics.shared.rankUp()
      }
    }
    .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: revealed)
  }
}

/// Vertical path with five act cards, drawn one by one. Reused by the program screen with a live position.
struct JourneyPath: View {
  var revealed: Int
  var apps: [TimeSink] = []
  var dream: String? = nil
  var identity: String = ""
  var currentAct: Act? = nil
  var dayNumber: Int = 0
  var startDate: Date? = nil
  var light = false

  var body: some View {
    VStack(spacing: 0) {
      ForEach(Act.allCases) { act in
        let index = act.rawValue
        let shown = index < revealed
        HStack(alignment: .top, spacing: 14) {
          VStack(spacing: 0) {
            ZStack {
              Circle()
                .fill(nodeFill(act))
                .frame(width: 34, height: 34)
              Image(systemName: act.symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(nodeForeground(act))
            }
            .scaleEffect(shown ? 1 : 0.4)
            if index < Act.allCases.count - 1 {
              Rectangle()
                .fill(light ? Color.ink.opacity(0.15) : Color.white.opacity(0.4))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .scaleEffect(y: shown ? 1 : 0, anchor: .top)
            }
          }
          .frame(width: 34)

          ActJourneyCard(act: act, apps: apps, dream: dream, identity: identity, isCurrent: act == currentAct, dayNumber: dayNumber, startDate: startDate, light: light)
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .padding(.bottom, 14)
        }
        .animation(.bouncy(duration: 0.6), value: shown)
      }
    }
  }

  private func nodeFill(_ act: Act) -> Color {
    if let currentAct {
      if act.rawValue < currentAct.rawValue { return .stickSuccess }
      if act == currentAct { return .brandOrange }
      return light ? Color.ink.opacity(0.08) : Color.white.opacity(0.3)
    }
    return .white
  }

  private func nodeForeground(_ act: Act) -> Color {
    if let currentAct {
      if act.rawValue <= currentAct.rawValue { return .white }
      return light ? Color.ink.opacity(0.4) : .white
    }
    return .brandOrange
  }
}

struct ActJourneyCard: View {
  var act: Act
  var apps: [TimeSink]
  var dream: String?
  var identity: String
  var isCurrent = false
  var dayNumber = 0
  var startDate: Date? = nil
  var light = false

  private var appNames: String {
    apps.isEmpty ? "TikTok" : apps.prefix(2).map(\.title).joined(separator: ", ")
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline) {
        Text("Act \(act.numeral) · \(Text(act.name))")
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Spacer()
        Text(daysLabel)
          .font(StickFont.caption)
          .foregroundStyle(isCurrent ? Color.brandOrange : Color.inkSecondary)
      }
      Text(personalized)
        .font(StickFont.callout)
        .foregroundStyle(Color.inkSecondary)
        .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 6) {
        Image(systemName: "waveform")
          .font(.system(size: 10, weight: .bold))
        Text(act.toneTitle)
          .font(StickFont.caption)
      }
      .foregroundStyle(Color.brandOrange)
      if !act.unlocks.isEmpty {
        FlowChips(features: act.unlocks, locked: !isCurrent && (dayNumber > 0 ? act.rawValue > Act.act(forDay: dayNumber).rawValue : true), unlocked: dayNumber > 0 && act.rawValue < Act.act(forDay: dayNumber).rawValue)
      }
    }
    .stickCard(padding: 16)
    .overlay {
      if isCurrent {
        RoundedRectangle(cornerRadius: StickMetrics.cardRadius, style: .continuous)
          .strokeBorder(Color.brandOrange, lineWidth: 2)
      }
    }
  }

  private var daysLabel: LocalizedStringKey {
    if let startDate {
      let date = Calendar.current.date(byAdding: .day, value: act.dayRange.lowerBound - 1, to: startDate) ?? startDate
      return "Day \(act.dayRange.lowerBound) · \(date, format: .dateTime.day().month(.abbreviated))"
    }
    return "Days \(act.dayRange.lowerBound)–\(act.dayRange.upperBound)"
  }

  private var personalized: LocalizedStringKey {
    switch act {
    case .silence: return "\(appNames) off limits. Stick calls three times a day and takes your goals every morning."
    case .comeback: return "Every morning Stick makes you choose what replaces the scroll: \(dreamLabel). Every night it counts the hours you took back."
    case .identity: return "Fewer orders, harder questions. Stick asks who you are when nobody's watching. Your voice badges begin."
    case .trial: return "The shield comes off 15 minutes a day. Stick checks every night whether you held it. Weekly trials begin."
    case .flight: return "One call a day. Stick makes you write what stays after day 75. On the last night, it plays your day-1 message."
    }
  }

  private var dreamLabel: String {
    switch dream {
    case "project": "your project"
    case "sport": "training"
    case "study": "studying"
    case "read": "reading"
    case "sleep": "sleep"
    case "people": "people you love"
    case "money": "earning"
    default: "what matters"
    }
  }
}

/// Wrapping row of feature chips, locked or not.
struct FlowChips: View {
  var features: [Feature]
  var locked: Bool
  var unlocked = false

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(features) { feature in
        HStack(spacing: 6) {
          Image(systemName: unlocked ? "checkmark.circle.fill" : (locked ? "lock.fill" : feature.symbol))
            .font(.system(size: 10, weight: .bold))
          Text(feature.title)
            .font(StickFont.caption)
        }
        .foregroundStyle(unlocked ? Color.stickSuccess : (locked ? Color.inkSecondary : Color.ink))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((unlocked ? Color.stickSuccess : (locked ? Color.ink : Color.brandOrange)).opacity(0.1), in: Capsule())
      }
    }
  }
}
