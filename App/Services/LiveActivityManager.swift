import ActivityKit
import Foundation

/// Runs the call Live Activity (Lock Screen + Dynamic Island) while Stick rings or talks.
@MainActor
final class LiveActivityManager {
  static let shared = LiveActivityManager()
  private var activity: Activity<CallActivityAttributes>?

  func start(kind: CallKind, userName: String) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    end()
    let attributes = CallActivityAttributes(callKind: kind.rawValue, userName: userName)
    let state = CallActivityAttributes.ContentState(phase: .ringing, startedAt: .now, lastLine: "")
    activity = try? Activity.request(
      attributes: attributes,
      content: .init(state: state, staleDate: Date.now.addingTimeInterval(600))
    )
  }

  func update(phase: CallActivityAttributes.Phase, lastLine: String) {
    guard let activity else { return }
    let state = CallActivityAttributes.ContentState(
      phase: phase,
      startedAt: activity.content.state.startedAt,
      lastLine: String(lastLine.prefix(90))
    )
    Task { await activity.update(.init(state: state, staleDate: Date.now.addingTimeInterval(600))) }
  }

  func end() {
    guard let activity else { return }
    let state = CallActivityAttributes.ContentState(phase: .ended, startedAt: activity.content.state.startedAt, lastLine: "")
    Task { await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate) }
    self.activity = nil
  }
}
