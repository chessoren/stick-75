import ActivityKit
import Foundation

/// Live Activity shown while Stick is calling or talking with the user.
struct CallActivityAttributes: ActivityAttributes {
  enum Phase: String, Codable, Hashable {
    case ringing, talking, ended
  }

  struct ContentState: Codable, Hashable {
    var phase: Phase
    var startedAt: Date
    var lastLine: String
  }

  var callKind: String
  var userName: String
}
