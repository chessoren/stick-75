import SwiftUI
import WidgetKit

/// The next time your own voice rings. Small orange hero with avatar.
struct NextCallWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "app.stick.nextCall", provider: SnapshotProvider()) { entry in
      NextCallWidgetView(snapshot: entry.snapshot)
        .widgetURL(URL(string: "stick://tab/calls"))
    }
    .configurationDisplayName("Next call")
    .description("When your own voice calls next.")
    .supportedFamilies([.systemSmall, .accessoryRectangular])
    .contentMarginsDisabled()
  }
}

struct NextCallWidgetView: View {
  var snapshot: SharedSnapshot
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if family == .accessoryRectangular {
      HStack(spacing: 8) {
        Image(systemName: snapshot.callSymbol)
        VStack(alignment: .leading, spacing: 1) {
          Text(snapshot.callTitle).font(.headline)
          if let date = snapshot.nextCallDate {
            Text(date, style: .time).font(.caption.monospacedDigit())
          } else {
            Text("Not scheduled").font(.caption)
          }
        }
      }
      .containerBackground(.clear, for: .widget)
    } else {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          InitialAvatar(name: snapshot.userName, size: 34)
          Spacer()
          Image(systemName: "phone.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(WidgetTheme.orange)
            .frame(width: 28, height: 28)
            .background(Color.white, in: Circle())
        }
        Spacer(minLength: 0)
        if let date = snapshot.nextCallDate {
          Text(date, style: .time)
            .font(WidgetFont.hero(30))
            .foregroundStyle(.white)
            .monospacedDigit()
          Text(snapshot.callTitle)
            .font(WidgetFont.caption)
            .foregroundStyle(.white.opacity(0.85))
            .lineLimit(1)
          Text(date, style: .relative)
            .font(WidgetFont.caption2)
            .foregroundStyle(.white.opacity(0.7))
            .lineLimit(1)
        } else {
          Text("Your voice calls once the program starts.")
            .font(WidgetFont.body)
            .foregroundStyle(.white)
        }
      }
      .padding(14)
      .containerBackground(for: .widget) { WidgetTheme.heroBackground }
    }
  }
}
