import AlarmKit
import Foundation

/// Metadata attached to AlarmKit alarms so the widget extension can render the call-style alert.
struct StickAlarmMetadata: AlarmMetadata {
  var callKind: String
  var userName: String
}
