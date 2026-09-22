import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

/// The AlarmKit alert for the wake-up call and the evening debrief: looks like an incoming call from yourself.
struct StickAlarmLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: AlarmAttributes<StickAlarmMetadata>.self) { context in
      AlarmLockScreenView(context: context)
        .activityBackgroundTint(WidgetTheme.orangeDeep)
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          InitialAvatar(name: context.attributes.metadata?.userName ?? "", size: 44, inverted: true)
            .padding(.leading, 4)
            .padding(.top, 2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            Text("Ringing")
              .font(WidgetFont.caption)
              .foregroundStyle(WidgetTheme.peach)
            Text(kindTitle(context))
              .font(WidgetFont.caption2)
              .foregroundStyle(.white.opacity(0.7))
          }
          .padding(.trailing, 4)
          .padding(.top, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 1) {
            Text(context.attributes.presentation.alert.title)
              .font(WidgetFont.inter(16, "SemiBold"))
              .foregroundStyle(.white)
              .lineLimit(1)
            Text("Your own voice · Stick")
              .font(WidgetFont.caption2)
              .foregroundStyle(.white.opacity(0.7))
          }
          .padding(.top, 4)
        }
        DynamicIslandExpandedRegion(.bottom) {
          HStack(spacing: 10) {
            StaticWaveform(color: WidgetTheme.orange, bars: 12, height: 18, energetic: true)
            Spacer()
            Button(intent: StartCallIntent(callKind: context.attributes.metadata?.callKind ?? "wake")) {
              Label("Answer", systemImage: "phone.fill")
                .font(WidgetFont.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(WidgetTheme.success, in: Capsule())
            }
            .buttonStyle(.plain)
          }
          .padding(.top, 6)
        }
      } compactLeading: {
        InitialAvatar(name: context.attributes.metadata?.userName ?? "", size: 22, inverted: true)
          .padding(.leading, 2)
      } compactTrailing: {
        Image(systemName: "phone.fill")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(WidgetTheme.orange)
          .symbolEffect(.pulse)
      } minimal: {
        Image(systemName: "phone.fill")
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(WidgetTheme.orange)
      }
      .keylineTint(WidgetTheme.orange)
    }
  }

  private func kindTitle(_ context: ActivityViewContext<AlarmAttributes<StickAlarmMetadata>>) -> LocalizedStringKey {
    (context.attributes.metadata?.callKind ?? "wake") == "debrief" ? "Evening debrief" : "Wake-up call"
  }
}

struct AlarmLockScreenView: View {
  var context: ActivityViewContext<AlarmAttributes<StickAlarmMetadata>>

  private var kind: String { context.attributes.metadata?.callKind ?? "wake" }
  private var subtitle: LocalizedStringKey {
    kind == "debrief" ? "Evening debrief. Pick up." : "Wake-up call. Pick up."
  }

  var body: some View {
    ZStack {
      WidgetTheme.heroBackground
      VStack(spacing: 14) {
        HStack(spacing: 12) {
          InitialAvatar(name: context.attributes.metadata?.userName ?? "", size: 52)
          VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.presentation.alert.title)
              .font(WidgetFont.inter(18, "SemiBold"))
              .foregroundStyle(.white)
              .lineLimit(1)
            Text(subtitle)
              .font(WidgetFont.body)
              .foregroundStyle(.white.opacity(0.9))
          }
          Spacer()
          Image(systemName: kind == "debrief" ? "moon.stars.fill" : "sunrise.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(WidgetTheme.orange)
            .frame(width: 38, height: 38)
            .background(Color.white, in: Circle())
        }
        HStack(spacing: 10) {
          StaticWaveform(color: .white, bars: 20, height: 20, energetic: true)
          Spacer()
          Button(intent: StartCallIntent(callKind: kind)) {
            Label("Answer", systemImage: "phone.fill")
              .font(WidgetFont.caption)
              .foregroundStyle(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(WidgetTheme.success, in: Capsule())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(16)
    }
  }
}
