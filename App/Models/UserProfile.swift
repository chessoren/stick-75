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

  /// Name to use in a sentence ("when TikTok opens"). nil for "Other", which isn't an app.
  var appName: String? { self == .other ? nil : title }

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
  /// Explicit permission to send call text to the language model (App Review 5.1.2(i)). Off: scripted calls.
  var aiConsentGiven = false
  var voiceSampleFileName: String?
  var vaultRecordingFileName: String?
  var contractSignedAt: Date?
  var blockedAppsSelected = false
  var shortcutAutomationSet = false

  init() {}

  /// Every field is optional on decode so an app update that adds a field never wipes the user's profile.
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let d = UserProfile()
    firstName = try c.decodeIfPresent(String.self, forKey: .firstName) ?? d.firstName
    identityStatement = try c.decodeIfPresent(String.self, forKey: .identityStatement) ?? d.identityStatement
    language = (try? c.decodeIfPresent(AppLanguage.self, forKey: .language)) ?? d.language
    timeSinks = (try? c.decodeIfPresent([TimeSink].self, forKey: .timeSinks)) ?? d.timeSinks
    hoursPerDay = try c.decodeIfPresent(Double.self, forKey: .hoursPerDay) ?? d.hoursPerDay
    crackMoments = try c.decodeIfPresent([String].self, forKey: .crackMoments) ?? d.crackMoments
    feelings = try c.decodeIfPresent([String].self, forKey: .feelings) ?? d.feelings
    dreams = try c.decodeIfPresent([String].self, forKey: .dreams) ?? d.dreams
    triedBefore = try c.decodeIfPresent([String].self, forKey: .triedBefore) ?? d.triedBefore
    wakeTime = try c.decodeIfPresent(ClockTime.self, forKey: .wakeTime) ?? d.wakeTime
    debriefTime = try c.decodeIfPresent(ClockTime.self, forKey: .debriefTime) ?? d.debriefTime
    voiceModelID = try c.decodeIfPresent(String.self, forKey: .voiceModelID)
    voiceConsentGiven = try c.decodeIfPresent(Bool.self, forKey: .voiceConsentGiven) ?? d.voiceConsentGiven
    aiConsentGiven = try c.decodeIfPresent(Bool.self, forKey: .aiConsentGiven) ?? d.aiConsentGiven
    voiceSampleFileName = try c.decodeIfPresent(String.self, forKey: .voiceSampleFileName)
    vaultRecordingFileName = try c.decodeIfPresent(String.self, forKey: .vaultRecordingFileName)
    contractSignedAt = try c.decodeIfPresent(Date.self, forKey: .contractSignedAt)
    blockedAppsSelected = try c.decodeIfPresent(Bool.self, forKey: .blockedAppsSelected) ?? d.blockedAppsSelected
    shortcutAutomationSet = try c.decodeIfPresent(Bool.self, forKey: .shortcutAutomationSet) ?? d.shortcutAutomationSet
  }
}
