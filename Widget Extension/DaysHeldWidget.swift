import SwiftUI
import WidgetKit

/// Big number: days held out of 75, plus hours recovered.
struct DaysHeldWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.stick.daysHeld", provider: SnapshotProvider()) { entry in
      DaysHeldWidgetView(snapshot: entry.snapshot)
    }
    .configurationDisplayName("Days held")
    .description("How many of the 75 days you've held, and the hours you got back.")
    .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
  }
}

struct DaysHeldWidgetView: View {
  var snapshot: SharedSnapshot
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .accessoryCircular:
      Gauge(value: Double(snapshot.daysHeld), in: 0...75) {
        Text("75")
      } currentValueLabel: {
        Text("\(snapshot.daysHeld)")
      }
      .gaugeStyle(.accessoryCircularCapacity)
      .containerBackground(.clear, for: .widget)
    case .accessoryInline:
      Label("\(snapshot.daysHeld)/75 held · \(Int(snapshot.hoursRecovered)) h back", systemImage: "flame.fill")
        .containerBackground(.clear, for: .widget)
    default:
      VStack(alignment: .leading, spacing: 2) {
        Text("Held")
          .font(.caption.weight(.semibold))
          .foregroundStyle(WidgetTheme.ink.opacity(0.6))
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text("\(snapshot.daysHeld)")
            .font(.system(size: 44, weight: .bold, design: .rounded))
            .foregroundStyle(WidgetTheme.ink)
            .contentTransition(.numericText())
          Text("/75")
            .font(.headline)
            .foregroundStyle(WidgetTheme.ink.opacity(0.5))
        }
        Spacer(minLength: 0)
        HStack(spacing: 4) {
          Image(systemName: "clock.arrow.circlepath")
          Text("\(Int(snapshot.hoursRecovered)) h back")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(WidgetTheme.orangeDeep)
        Text(snapshot.actNameKey)
          .font(.caption2)
          .foregroundStyle(WidgetTheme.ink.opacity(0.6))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .containerBackground(for: .widget) {
        WidgetTheme.cream
      }
    }
  }
}
