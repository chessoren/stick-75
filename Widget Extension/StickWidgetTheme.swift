import SwiftUI
import WidgetKit

enum WidgetTheme {
  static let orange = Color(red: 0.949, green: 0.404, blue: 0.227)
  static let orangeDeep = Color(red: 0.886, green: 0.306, blue: 0.106)
  static let peach = Color(red: 1.0, green: 0.690, blue: 0.478)
  static let cream = Color(red: 1.0, green: 0.957, blue: 0.925)
  static let ink = Color(red: 0.067, green: 0.067, blue: 0.067)

  static var gradient: LinearGradient {
    LinearGradient(colors: [orange, peach], startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

struct SnapshotEntry: TimelineEntry {
  var date: Date
  var snapshot: SharedSnapshot
}

struct SnapshotProvider: TimelineProvider {
  func placeholder(in context: Context) -> SnapshotEntry {
    SnapshotEntry(date: .now, snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
    completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : SharedSnapshot.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
    let entry = SnapshotEntry(date: .now, snapshot: SharedSnapshot.load())
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}
