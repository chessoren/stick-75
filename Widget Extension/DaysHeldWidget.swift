import SwiftUI
import WidgetKit

/// Big number: days held out of 75, ring and hours recovered. Cream card like the secondary screens.
struct DaysHeldWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.stick.daysHeld", provider: SnapshotProvider()) { entry in
      DaysHeldWidgetView(snapshot: entry.snapshot)
        .widgetURL(URL(string: "stick://tab/me"))
    }
    .configurationDisplayName("Days held")
    .description("How many of the 75 days you've held, and the hours you got back.")
    .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    .contentMarginsDisabled()
  }
}

struct DaysHeldWidgetView: View {
  var snapshot: SharedSnapshot
  @Environment(\.widgetFamily) private var family

  private var progress: Double { Double(snapshot.daysHeld) / 75 }

  var body: some View {
    switch family {
    case .accessoryCircular:
      Gauge(value: Double(snapshot.daysHeld), in: 0...75) {
        Image(systemName: "flame.fill")
      } currentValueLabel: {
        Text("\(snapshot.daysHeld)")
          .font(.system(.title3, design: .rounded, weight: .bold))
      }
      .gaugeStyle(.accessoryCircular)
      .containerBackground(.clear, for: .widget)
    case .accessoryInline:
      Label("\(snapshot.daysHeld)/75 held · \(Int(snapshot.hoursRecovered)) h back", systemImage: "flame.fill")
        .containerBackground(.clear, for: .widget)
    default:
      ZStack {
        VStack(alignment: .leading, spacing: 0) {
          HStack {
            Text("Held")
              .font(WidgetFont.caption)
              .foregroundStyle(WidgetTheme.inkSecondary)
            Spacer()
            Image(systemName: "flame.fill")
              .font(.system(size: 11, weight: .bold))
              .foregroundStyle(WidgetTheme.orange)
          }
          Spacer(minLength: 0)
          ZStack {
            MiniRing(progress: progress, lineWidth: 8, tint: WidgetTheme.orange, track: WidgetTheme.orange.opacity(0.15))
            VStack(spacing: -2) {
              Text("\(snapshot.daysHeld)")
                .font(WidgetFont.hero(34))
                .foregroundStyle(WidgetTheme.ink)
                .contentTransition(.numericText())
              Text("/ 75")
                .font(WidgetFont.caption2)
                .foregroundStyle(WidgetTheme.inkSecondary)
            }
          }
          .frame(width: 92, height: 92)
          .frame(maxWidth: .infinity)
          Spacer(minLength: 0)
          HStack(spacing: 5) {
            Image(systemName: "clock.arrow.circlepath")
              .font(.system(size: 10, weight: .bold))
            Text("\(Int(snapshot.hoursRecovered)) h back")
              .font(WidgetFont.caption)
              .monospacedDigit()
          }
          .foregroundStyle(.white)
          .padding(.horizontal, 9)
          .padding(.vertical, 6)
          .background(WidgetTheme.orange, in: Capsule())
          .frame(maxWidth: .infinity)
        }
        .padding(14)
      }
      .containerBackground(for: .widget) { WidgetTheme.creamBackground }
    }
  }
}
