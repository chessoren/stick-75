import AppIntents
import SwiftUI
import WidgetKit

/// Today's goals with tap-to-check, day counter and next call.
struct TodayGoalsWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.stick.todayGoals", provider: SnapshotProvider()) { entry in
      TodayGoalsWidgetView(snapshot: entry.snapshot)
    }
    .configurationDisplayName("Today's goals")
    .description("Your goals for the day, checkable from the Home Screen.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}

struct TodayGoalsWidgetView: View {
  var snapshot: SharedSnapshot
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryRectangular:
      VStack(alignment: .leading, spacing: 2) {
        Text("Day \(snapshot.dayNumber)/75")
          .font(.headline)
        ForEach(snapshot.goals.prefix(2)) { goal in
          HStack(spacing: 4) {
            Image(systemName: goal.isDone ? "checkmark.circle.fill" : "circle")
            Text(goal.title).lineLimit(1)
          }
          .font(.caption)
        }
      }
      .containerBackground(.clear, for: .widget)
    default:
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Day \(snapshot.dayNumber)")
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(.white)
          Text("/ 75")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
          Spacer()
          if family == .systemMedium, let date = snapshot.nextCallDate {
            HStack(spacing: 4) {
              Image(systemName: "phone.fill")
              Text(date, style: .time)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
          }
        }
        if snapshot.goals.isEmpty {
          Text("No goals yet. Take the wake-up call.")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.9))
          Spacer(minLength: 0)
        } else {
          ForEach(snapshot.goals.prefix(family == .systemSmall ? 3 : 4)) { goal in
            Button(intent: ToggleGoalIntent(goalID: goal.id)) {
              HStack(spacing: 8) {
                Image(systemName: goal.isDone ? "checkmark.circle.fill" : "circle")
                  .foregroundStyle(goal.isDone ? WidgetTheme.ink : .white)
                Text(goal.title)
                  .font(.footnote.weight(.medium))
                  .foregroundStyle(.white)
                  .strikethrough(goal.isDone)
                  .lineLimit(1)
                Spacer(minLength: 0)
              }
            }
            .buttonStyle(.plain)
          }
          Spacer(minLength: 0)
        }
      }
      .containerBackground(for: .widget) {
        WidgetTheme.gradient
      }
    }
  }
}
