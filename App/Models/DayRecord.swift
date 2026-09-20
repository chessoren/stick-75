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
  var minutesOnBlockedApps = 0
  var goalsCompleted = 0
  var goalsTotal = 0

  var isHeld: Bool {
    goalsSet && debriefDone && (!lapsed || jokerUsed)
  }

  var completion: Double {
    var score = 0.0
    if goalsSet { score += 0.3 }
    if debriefDone { score += 0.3 }
    if goalsTotal > 0 { score += 0.4 * Double(goalsCompleted) / Double(goalsTotal) }
    return min(1, score)
  }
}
