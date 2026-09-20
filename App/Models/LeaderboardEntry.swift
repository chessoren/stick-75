import Foundation

struct LeaderboardEntry: Identifiable, Codable, Hashable {
  var id = UUID()
  var name: String
  var initials: String
  var hoursRecovered: Double
  var daysHeld: Int
  var isMe = false
  var hue: Double
}
