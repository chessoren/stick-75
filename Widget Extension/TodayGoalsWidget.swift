import AppIntents
import SwiftUI
import WidgetKit

/// Today's goals, checkable from the Home Screen. Orange hero card like the app.
struct TodayGoalsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.stick.todayGoals", provider: SnapshotProvider()) { entry in
      TodayGoalsWidgetView(snapshot: entry.snapshot)
        .widgetURL(URL(string: "stick://tab/today"))
    }
    .configurationDisplayName("Today's goals")
    .description("Your goals for the day, checkable from the Home Screen.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    .contentMarginsDisabled()
  }
}

struct TodayGoalsWidgetView: View {
  var snapshot: SharedSnapshot
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryRectangular: lockScreen
    case .systemSmall: small
    case .systemLarge: large
    default: medium
    }
  }

  // MARK: Lock Screen

  private var lockScreen: some View {
    VStack(alignment: .leading, spacing: 3) {
      HStack(spacing: 4) {
        Image(systemName: "flame.fill")
        Text("Day \(snapshot.dayNumber)/75")
          .font(.headline)
        Spacer()
        Text("\(snapshot.goals.filter(\.isDone).count)/\(snapshot.goals.count)")
          .font(.caption.monospacedDigit())
      }
      ForEach(snapshot.goals.prefix(2)) { goal in
        HStack(spacing: 4) {
          Image(systemName: goal.isDone ? "checkmark.circle.fill" : "circle")
          Text(goal.title).lineLimit(1).strikethrough(goal.isDone)
        }
        .font(.caption)
      }
    }
    .containerBackground(.clear, for: .widget)
  }

  // MARK: Small

  private var small: some View {
    VStack(alignment: .leading, spacing: 8) {
      header(showRing: true)
      goalList(max: 3, compact: true)
      Spacer(minLength: 0)
    }
    .padding(14)
    .containerBackground(for: .widget) { WidgetTheme.heroBackground }
  }

  // MARK: Medium

  private var medium: some View {
    HStack(alignment: .top, spacing: 14) {
      VStack(alignment: .leading, spacing: 6) {
        dayHero
        Spacer(minLength: 0)
        nextCall
      }
      .frame(width: 112, alignment: .leading)

      VStack(alignment: .leading, spacing: 6) {
        goalList(max: 4, compact: false)
        Spacer(minLength: 0)
      }
    }
    .padding(14)
    .containerBackground(for: .widget) { WidgetTheme.heroBackground }
  }

  // MARK: Large

  private var large: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top) {
        dayHero
        Spacer()
        ZStack {
          MiniRing(progress: snapshot.goalProgress, lineWidth: 7)
          Text(snapshot.goalProgress, format: .percent.precision(.fractionLength(0)))
            .font(WidgetFont.inter(15, "SemiBold"))
            .foregroundStyle(.white)
        }
        .frame(width: 64, height: 64)
      }
      VStack(alignment: .leading, spacing: 8) {
        Text("Goals")
          .font(WidgetFont.caption)
          .foregroundStyle(.white.opacity(0.75))
        goalList(max: 5, compact: false)
      }
      Spacer(minLength: 0)
      HStack(spacing: 10) {
        statChip(symbol: "clock.arrow.circlepath", value: "\(Int(snapshot.hoursRecovered)) h", label: "back")
        statChip(symbol: "checkmark.seal.fill", value: "\(snapshot.daysHeld)", label: "held")
        Spacer()
        nextCall
      }
    }
    .padding(18)
    .containerBackground(for: .widget) { WidgetTheme.heroBackground }
  }

  // MARK: Pieces

  private func header(showRing: Bool) -> some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Day \(snapshot.dayNumber)")
          .font(WidgetFont.hero(24))
          .foregroundStyle(.white)
        Text("of 75 · \(snapshot.actNameKey)")
          .font(WidgetFont.caption2)
          .foregroundStyle(.white.opacity(0.8))
          .lineLimit(1)
      }
      Spacer(minLength: 0)
      if showRing {
        MiniRing(progress: snapshot.goalProgress, lineWidth: 4)
          .frame(width: 26, height: 26)
      }
    }
  }

  private var dayHero: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .firstTextBaseline, spacing: 3) {
        Text("\(snapshot.dayNumber)")
          .font(WidgetFont.hero(44))
          .foregroundStyle(.white)
          .contentTransition(.numericText())
        Text("/75")
          .font(WidgetFont.inter(14, "SemiBold"))
          .foregroundStyle(.white.opacity(0.8))
      }
      Text(snapshot.actNameKey)
        .font(WidgetFont.caption)
        .foregroundStyle(.white.opacity(0.85))
        .lineLimit(1)
    }
  }

  private var nextCall: some View {
    Group {
      if let date = snapshot.nextCallDate {
        HStack(spacing: 6) {
          Image(systemName: snapshot.callSymbol)
            .font(.system(size: 10, weight: .bold))
          Text(date, style: .time)
            .font(WidgetFont.caption)
            .monospacedDigit()
        }
        .foregroundStyle(WidgetTheme.orangeDeep)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.92), in: Capsule())
      }
    }
  }

  private func statChip(symbol: String, value: String, label: LocalizedStringKey) -> some View {
    HStack(spacing: 5) {
      Image(systemName: symbol).font(.system(size: 10, weight: .bold))
      Text(value).font(WidgetFont.caption).monospacedDigit()
      Text(label).font(WidgetFont.caption2).opacity(0.85)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 9)
    .padding(.vertical, 6)
    .glassPill(radius: 999)
  }

  @ViewBuilder
  private func goalList(max: Int, compact: Bool) -> some View {
    if snapshot.goals.isEmpty {
      VStack(alignment: .leading, spacing: 4) {
        Text("No goals yet.")
          .font(WidgetFont.headline)
          .foregroundStyle(.white)
        Text("Take the wake-up call.")
          .font(WidgetFont.caption)
          .foregroundStyle(.white.opacity(0.85))
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .glassPill()
    } else {
      ForEach(snapshot.goals.prefix(max)) { goal in
        Button(intent: ToggleGoalIntent(goalID: goal.id)) {
          HStack(spacing: 8) {
            ZStack {
              Circle()
                .fill(goal.isDone ? WidgetTheme.ink : Color.white.opacity(0.18))
              Circle()
                .strokeBorder(Color.white.opacity(goal.isDone ? 0 : 0.9), lineWidth: 1.5)
              Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .opacity(goal.isDone ? 1 : 0)
            }
            .frame(width: 18, height: 18)
            Text(goal.title)
              .font(compact ? WidgetFont.caption : WidgetFont.body)
              .foregroundStyle(.white.opacity(goal.isDone ? 0.65 : 1))
              .strikethrough(goal.isDone, color: .white.opacity(0.7))
              .lineLimit(1)
            Spacer(minLength: 0)
          }
          .padding(.horizontal, compact ? 8 : 10)
          .padding(.vertical, compact ? 6 : 8)
          .glassPill(radius: compact ? 10 : 12, opacity: goal.isDone ? 0.12 : 0.22)
        }
        .buttonStyle(.plain)
      }
    }
  }
}
