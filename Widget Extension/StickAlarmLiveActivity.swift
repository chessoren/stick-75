import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

/// Renders the AlarmKit alert for the wake-up call and evening debrief.
struct StickAlarmLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<StickAlarmMetadata>.self) { context in
      HStack(spacing: 14) {
        Circle()
          .fill(.white)
          .frame(width: 48, height: 48)
          .overlay {
            Text(initial(context))
              .font(.headline)
              .foregroundStyle(WidgetTheme.orange)
          }
        VStack(alignment: .leading, spacing: 2) {
          Text(context.attributes.presentation.alert.title)
            .font(.headline)
          Text(subtitle(context))
            .font(.caption)
            .opacity(0.9)
        }
        Spacer()
        Button(intent: StartCallIntent(callKind: context.attributes.metadata?.callKind ?? "wake")) {
          Image(systemName: "phone.fill")
            .font(.title3)
            .foregroundStyle(WidgetTheme.orange)
            .frame(width: 44, height: 44)
            .background(.white, in: Circle())
        }
        .buttonStyle(.plain)
      }
      .foregroundStyle(.white)
      .padding(16)
      .activityBackgroundTint(WidgetTheme.orange)
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "phone.arrow.down.left.fill")
            .font(.title2)
            .foregroundStyle(WidgetTheme.orange)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Button(intent: StartCallIntent(callKind: context.attributes.metadata?.callKind ?? "wake")) {
            Image(systemName: "phone.fill")
              .foregroundStyle(WidgetTheme.orange)
          }
          .buttonStyle(.plain)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.presentation.alert.title)
            .font(.headline)
            .foregroundStyle(.white)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(subtitle(context))
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))
        }
      } compactLeading: {
        Image(systemName: "phone.fill")
          .foregroundStyle(WidgetTheme.orange)
      } compactTrailing: {
        Image(systemName: "waveform")
          .foregroundStyle(.white)
      } minimal: {
        Image(systemName: "phone.fill")
          .foregroundStyle(WidgetTheme.orange)
      }
      .keylineTint(WidgetTheme.orange)
    }
  }

  private func initial(_ context: ActivityViewContext<AlarmAttributes<StickAlarmMetadata>>) -> String {
    let name = context.attributes.metadata?.userName ?? ""
    return name.isEmpty ? "S" : String(name.prefix(1)).uppercased()
  }

  private func subtitle(_ context: ActivityViewContext<AlarmAttributes<StickAlarmMetadata>>) -> LocalizedStringKey {
    (context.attributes.metadata?.callKind ?? "wake") == "debrief" ? "Evening debrief. Pick up." : "Wake-up call. Pick up."
  }
}
