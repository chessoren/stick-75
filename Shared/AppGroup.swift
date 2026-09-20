import Foundation

enum AppGroup {
  static let id = "group.app.bitrig.new.7a862d7d-9f78-4980-b2bb-e1507322242f"
  static let snapshotKey = "stick.snapshot.v1"

  static var defaults: UserDefaults {
    UserDefaults(suiteName: id) ?? .standard
  }
}
