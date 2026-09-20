import Foundation

/// Third-party keys are read from `Secrets.local.plist`, a git-ignored file in `App/Resources/`.
/// Keep them out of source control. Before the App Store, move the calls behind a Supabase Edge Function:
/// anything shipped in the binary can be extracted.
enum Secrets {
  private static let values: [String: String] = {
    guard let url = Bundle.main.url(forResource: "Secrets.local", withExtension: "plist"),
          let data = try? Data(contentsOf: url),
          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
      return [:]
    }
    return plist
  }()

  private static func value(_ key: String, default fallback: String = "") -> String {
    let v = values[key] ?? ""
    return v.isEmpty ? fallback : v
  }

  static var fishAudioKey: String { value("FISH_AUDIO_KEY") }
  static var fishAudioModel: String { value("FISH_AUDIO_MODEL", default: "s2.1-pro-free") }
  static var openRouterKey: String { value("OPENROUTER_KEY") }
  static var openRouterModel: String { value("OPENROUTER_MODEL", default: "nex-agi/nex-n2.5-mini:free") }
  static var openRouterFallbackModel: String { value("OPENROUTER_FALLBACK_MODEL", default: "nex-agi/nex-n2.5-pro:free") }
  static var revenueCatKey: String { value("REVENUECAT_KEY") }
  static var supabaseURL: String { value("SUPABASE_URL") }
  static var supabaseAnonKey: String { value("SUPABASE_ANON_KEY") }

  static var hasVoiceKeys: Bool { !fishAudioKey.isEmpty }
  static var hasLLMKeys: Bool { !openRouterKey.isEmpty }
}
