import Foundation

struct Goal: Identifiable, Codable, Hashable {
  var id = UUID()
  var title: String
  var isDone = false
  var dayNumber: Int
}
