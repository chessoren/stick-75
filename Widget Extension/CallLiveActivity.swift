import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// Lock Screen banner and Dynamic Island while Stick rings or is on the line.
struct CallLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CallActivityAttributes.self) { context in
      CallLockScreenView(context: context)
        .activityBackgroundTint(WidgetTheme.orangeDeep)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(URL(string: "stick://call/\(context.attributes.callKind)"))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          InitialAvatar(name: context.attributes.userName, size: 44, inverted: true)
            .padding(.leading, 4)
            .padding(.top, 2)
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            if context.state.phase == .ringing {
              Text("Ringing")
                .font(WidgetFont.caption)
                .foregroundStyle(WidgetTheme.peach)
            } else {
              Text(context.state.startedAt, style: .timer)
                .font(WidgetFont.inter(17, "SemiBold"))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.white)
                .frame(width: 58, alignment: .trailing)
            }
            Text(kindTitle(context.attributes.callKind))
              .font(WidgetFont.caption2)
              .foregroundStyle(.white.opacity(0.7))
              .lineLimit(1)
          }
          .padding(.trailing, 4)
          .padding(.top, 4)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 1) {
            Text(context.attributes.userName.isEmpty ? String(localized: "You") : context.attributes.userName)
              .font(WidgetFont.inter(16, "SemiBold"))
              .foregroundStyle(.white)
            Text("Your own voice · Stick")
              .font(WidgetFont.caption2)
              .foregroundStyle(.white.opacity(0.7))
          }
          .padding(.top, 4)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
              StaticWaveform(color: WidgetTheme.orange, bars: 14, height: 18, energetic: context.state.phase == .talking)
              Text(context.state.phase == .ringing ? String(localized: "Pick up. It's you.") : (context.state.lastLine.isEmpty ? String(localized: "On the line") : context.state.lastLine))
                .font(WidgetFont.body)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
              Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
              if context.state.phase == .ringing {
                Button(intent: StartCallIntent(callKind: context.attributes.callKind)) {
                  Label("Answer", systemImage: "phone.fill")
                    .font(WidgetFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(WidgetTheme.success, in: Capsule())
                }
                .buttonStyle(.plain)
              }
              Button(intent: EndCallIntent()) {
                Label(context.state.phase == .ringing ? "Decline" : "Hang up", systemImage: "phone.down.fill")
                  .font(WidgetFont.headline)
                  .foregroundStyle(.white)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 10)
                  .background(WidgetTheme.danger, in: Capsule())
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.top, 6)
        }
      } compactLeading: {
        InitialAvatar(name: context.attributes.userName, size: 22, inverted: true)
          .padding(.leading, 2)
      } compactTrailing: {
        if context.state.phase == .ringing {
          Image(systemName: "phone.fill")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(WidgetTheme.orange)
            .symbolEffect(.pulse)
        } else {
          Text(context.state.startedAt, style: .timer)
            .font(WidgetFont.inter(13, "SemiBold"))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .foregroundStyle(WidgetTheme.orange)
            .frame(width: 44, alignment: .trailing)
        }
      } minimal: {
        InitialAvatar(name: context.attributes.userName, size: 22, inverted: true)
      }
      .keylineTint(WidgetTheme.orange)
    }
    .supplementalActivityFamilies([.small, .medium])
  }

  private func kindTitle(_ raw: String) -> LocalizedStringKey {
    switch raw {
    case "wake": "Wake-up call"
    case "debrief": "Evening debrief"
    case "intercept": "Interception"
    case "recovery": "Recovery call"
    case "push": "Push"
    default: "First call"
    }
  }
}

struct CallLockScreenView: View {
  var context: ActivityViewContext<CallActivityAttributes>
  @Environment(\.activityFamily) private var family

  private var name: String {
    context.attributes.userName.isEmpty ? String(localized: "You") : context.attributes.userName
  }

  var body: some View {
    ZStack {
      WidgetTheme.heroBackground
      if family == .small {
        compactBody
      } else {
        fullBody
      }
    }
  }

  private var fullBody: some View {
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        InitialAvatar(name: context.attributes.userName, size: 48)
        VStack(alignment: .leading, spacing: 2) {
          Text(name)
            .font(WidgetFont.inter(18, "SemiBold"))
            .foregroundStyle(.white)
          Text(context.state.phase == .ringing ? "Your own voice is calling." : (context.state.lastLine.isEmpty ? "On the line" : context.state.lastLine))
            .font(WidgetFont.body)
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(2)
        }
        Spacer(minLength: 8)
        if context.state.phase == .ringing {
          Image(systemName: "phone.fill")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(WidgetTheme.orange)
            .frame(width: 38, height: 38)
            .background(Color.white, in: Circle())
        } else {
          Text(context.state.startedAt, style: .timer)
            .font(WidgetFont.inter(17, "SemiBold"))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .foregroundStyle(.white)
            .frame(width: 62, alignment: .trailing)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .glassPill(radius: 999)
        }
      }
      HStack(spacing: 10) {
        StaticWaveform(color: .white, bars: 22, height: 20, energetic: context.state.phase == .talking)
        Spacer()
        if context.state.phase == .ringing {
          Button(intent: StartCallIntent(callKind: context.attributes.callKind)) {
            Label("Answer", systemImage: "phone.fill")
              .font(WidgetFont.caption)
              .foregroundStyle(.white)
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(WidgetTheme.success, in: Capsule())
          }
          .buttonStyle(.plain)
        }
        Button(intent: EndCallIntent()) {
          Label(context.state.phase == .ringing ? "Decline" : "Hang up", systemImage: "phone.down.fill")
            .font(WidgetFont.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(WidgetTheme.danger, in: Capsule())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(16)
  }

  private var compactBody: some View {
    HStack(spacing: 10) {
      InitialAvatar(name: context.attributes.userName, size: 32)
      VStack(alignment: .leading, spacing: 1) {
        Text(name)
          .font(WidgetFont.headline)
          .foregroundStyle(.white)
        Text(context.state.phase == .ringing ? "Calling…" : "On the line")
          .font(WidgetFont.caption2)
          .foregroundStyle(.white.opacity(0.85))
      }
      Spacer()
      if context.state.phase != .ringing {
        Text(context.state.startedAt, style: .timer)
          .font(WidgetFont.caption)
          .monospacedDigit()
          .foregroundStyle(.white)
          .frame(width: 48, alignment: .trailing)
      }
    }
    .padding(12)
  }
}
