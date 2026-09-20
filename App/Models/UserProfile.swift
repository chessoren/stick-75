import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
  case english = "en"
  case french = "fr"

  var id: String { rawValue }

  static var device: AppLanguage {
    let code = Locale.current.language.languageCode?.identifier ?? "en"
    return code.hasPrefix("fr") ? .french : .english
  }

  var speechLocale: Locale {
    switch self {
    case .english: Locale(identifier: "en-US")
    case .french: Locale(identifier: "fr-FR")
    }
  }
}

enum TimeSink: String, Codable, CaseIterable, Identifiable {
  case tiktok, instagram, youtube, snapchat, x, reddit, twitch, other

  var id: String { rawValue }

  var title: String {
    switch self {
    case .tiktok: "TikTok"
    case .instagram: "Instagram"
    case .youtube: "YouTube Shorts"
    case .snapchat: "Snapchat"
    case .x: "X"
    case .reddit: "Reddit"
    case .twitch: "Twitch"
    case .other: "Other"
    }
  }

  var symbol: String {
    switch self {
    case .tiktok: "music.note"
    case .instagram: "camera.fill"
    case .youtube: "play.rectangle.fill"
    case .snapchat: "bolt.fill"
    case .x: "xmark"
    case .reddit: "bubble.left.and.bubble.right.fill"
    case .twitch: "gamecontroller.fill"
    case .other: "ellipsis"
    }
  }
}

struct ClockTime: Codable, Hashable {
  var hour: Int
  var minute: Int

  static let defaultWake = ClockTime(hour: 7, minute: 0)
  static let defaultDebrief = ClockTime(hour: 21, minute: 30)

  var date: Date {
    Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
  }

  init(hour: Int, minute: Int) {
    self.hour = hour
    self.minute = minute
  }

  init(date: Date) {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    hour = comps.hour ?? 7
    minute = comps.minute ?? 0
  }

  func next(after reference: Date = .now) -> Date {
    let calendar = Calendar.current
    let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: reference) ?? reference
    if today > reference { return today }
    return calendar.date(byAdding: .day, value: 1, to: today) ?? today
  }
}

struct UserProfile: Codable, Hashable {
  var firstName = ""
  var identityStatement = ""
  var language: AppLanguage = .device
  var timeSinks: [TimeSink] = []
  var hoursPerDay: Double = 3.0
  var crackMoments: [String] = []
  var feelings: [String] = []
  var dreams: [String] = []
  var triedBefore: [String] = []
  var wakeTime: ClockTime = .defaultWake
  var debriefTime: ClockTime = .defaultDebrief
  var voiceModelID: String?
  var voiceConsentGiven = false
  var voiceSampleFileName: String?
  var vaultRecordingFileName: String?
  var contractSignedAt: Date?
  var referralCode = UserProfile.makeReferralCode()
  var referredBy: String?
  var blockedAppsSelected = false
  var shortcutAutomationSet = false

  static func makeReferralCode() -> String {
    let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    return String((0..<6).map { _ in letters.randomElement()! })
  }
}
