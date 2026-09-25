import Foundation

/// Public addresses shown in the app and in the legal texts. Fill them in before submitting.
enum AppLinks {
  /// Numeric Apple ID of the app (App Store Connect › App Information › Apple ID). Empty until the record exists.
  static let appStoreID = ""
  /// Contact address printed in the privacy policy, the terms and the support page.
  static let contactEmail = "contact@example.com"
  /// Where the privacy policy, terms and support pages are hosted (see docs/site).
  static let website = "https://example.com"

  static var appStoreURL: URL? {
    appStoreID.isEmpty ? nil : URL(string: "https://apps.apple.com/app/id\(appStoreID)")
  }

  static let appleEULA = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}
