import Foundation

/// One of the 75 days. A day is held when goals were set, no lapse happened and the debrief was done.
struct DayRecord: Identifiable, Codable, Hashable {
  var id: Int { dayNumber }
  var dayNumber: Int
  var date: Date
  var goalsSet = false
  var debriefDone = false
  var lapsed = false
  var jokerUsed = false
  var recoveryDone = false
  var habit: String?
  var windowHeld: Bool?
  var identityAnswer: String?
  var minutesOnBlockedApps = 0
  var goalsCompleted = 0
  var goalsTotal = 0

  var isHeld: Bool {
    goalsSet && debriefDone && (!lapsed || jokerUsed)
  }

  var completion: Double {
    if isHeld { return 1 }
    var score = 0.0
    if goalsTotal > 0 {
      if goalsSet { score += 0.3 }
      if debriefDone { score += 0.3 }
      score += 0.4 * Double(goalsCompleted) / Double(goalsTotal)
    } else {
      if goalsSet { score += 0.5 }
      if debriefDone { score += 0.5 }
    }
    return min(0.99, score)
  }
}
