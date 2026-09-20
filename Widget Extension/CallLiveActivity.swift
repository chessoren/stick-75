import ActivityKit
import SwiftUI
import WidgetKit

/// Lock Screen and Dynamic Island while Stick is ringing or on the line.
struct CallLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CallActivityAttributes.self) { context in
      CallLockScreenView(context: context)
        .activityBackgroundTint(WidgetTheme.orange)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(URL(string: "stick://call/\(context.attributes.callKind)"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: context.state.phase == .ringing ? "phone.arrow.down.left.fill" : "waveform")
            .font(.title2)
            .foregroundStyle(WidgetTheme.orange)
            .padding(.leading, 6)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.startedAt, style: .timer)
            .font(.headline.monospacedDigit())
            .foregroundStyle(.white)
            .frame(maxWidth: 60)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(context.attributes.userName.isEmpty ? "You" : context.attributes.userName)
            .font(.headline)
            .foregroundStyle(.white)
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text(context.state.phase == .ringing ? "Your own voice is calling." : context.state.lastLine)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.85))
            .lineLimit(2)
        }
      } compactLeading: {
        Image(systemName: "phone.fill")
          .foregroundStyle(WidgetTheme.orange)
      } compactTrailing: {
        Text(context.state.startedAt, style: .timer)
          .font(.caption2.monospacedDigit())
          .foregroundStyle(.white)
          .frame(maxWidth: 44)
      } minimal: {
        Image(systemName: "phone.fill")
          .foregroundStyle(WidgetTheme.orange)
      }
      .keylineTint(WidgetTheme.orange)
    }
    .supplementalActivityFamilies([.small, .medium])
  }
}

struct CallLockScreenView: View {
  var context: ActivityViewContext<CallActivityAttributes>
  @Environment(\.activityFamily) private var family

  var body: some View {
    HStack(spacing: 14) {
      Circle()
        .fill(.white)
        .frame(width: family == .small ? 36 : 48, height: family == .small ? 36 : 48)
        .overlay {
          Text(context.attributes.userName.isEmpty ? "S" : String(context.attributes.userName.prefix(1)).uppercased())
            .font(.headline)
            .foregroundStyle(WidgetTheme.orange)
        }
      VStack(alignment: .leading, spacing: 2) {
        Text(context.attributes.userName.isEmpty ? "You" : context.attributes.userName)
          .font(.headline)
        Text(context.state.phase == .ringing ? "Your own voice is calling." : (context.state.lastLine.isEmpty ? "On the line" : context.state.lastLine))
          .font(.caption)
          .opacity(0.9)
          .lineLimit(family == .small ? 1 : 2)
      }
      Spacer()
      if context.state.phase != .ringing {
        Text(context.state.startedAt, style: .timer)
          .font(.headline.monospacedDigit())
          .frame(maxWidth: 64)
      } else {
        Image(systemName: "phone.fill")
          .font(.title3)
      }
    }
    .foregroundStyle(.white)
    .padding(16)
  }
}
