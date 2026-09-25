import Foundation

/// Pre-generated clips in the user's voice (ringtone, vault playback).
enum VoiceClipCache {
  static var directory: URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "VoiceClips")
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    return base
  }

  /// Drops every clip rendered with the current voice (voice re-recorded or deleted).
  static func clear() {
    try? FileManager.default.removeItem(at: directory)
  }

  static func url(_ name: String) -> URL {
    directory.appending(path: "\(name).mp3")
  }

  static func exists(_ name: String) -> Bool {
    FileManager.default.fileExists(atPath: url(name).path)
  }

  static func store(_ data: Data, as name: String) {
    try? data.write(to: url(name), options: .atomic)
  }

  static func data(_ name: String) -> Data? {
    try? Data(contentsOf: url(name))
  }

  /// Generates and caches the act's ringtone in the cloned voice if it does not exist yet.
  static func ensureRingtone(voiceID: String, language: AppLanguage, act: Act = .silence) async {
    let name = "ringtone-\(language.rawValue)-\(act.rawValue)"
    guard !exists(name) else { return }
    let fish = FishAudioService()
    if let data = try? await fish.synthesize(act.ringtoneLine(language: language), referenceID: voiceID) {
      store(data, as: name)
    }
  }

  /// The act's ringtone, falling back to any earlier act's clip.
  static func ringtone(language: AppLanguage, act: Act = .silence) -> Data? {
    for index in stride(from: act.rawValue, through: 0, by: -1) {
      if let clip = data("ringtone-\(language.rawValue)-\(index)") { return clip }
    }
    return data("ringtone-\(language.rawValue)")
  }

  static func voiceBadgeName(_ act: Act) -> String { "badge-\(act.rawValue)" }

  static func ensureVoiceBadge(voiceID: String, act: Act, identity: String, language: AppLanguage) async {
    guard let line = act.voiceBadgeLine(identity: identity.isEmpty ? (language == .french ? "finit ce qu'il commence" : "finishes what they start") : identity, language: language) else { return }
    let name = voiceBadgeName(act)
    guard !exists(name) else { return }
    if let data = try? await FishAudioService().synthesize(line, referenceID: voiceID) {
      store(data, as: name)
    }
  }

  static func revealName(_ act: Act) -> String { "reveal-\(act.rawValue)" }

  static func ensureReveal(voiceID: String, act: Act, name userName: String, identity: String, language: AppLanguage) async -> Data? {
    let name = revealName(act)
    if let cached = data(name) { return cached }
    let line = act.revealLine(name: userName, identity: identity.isEmpty ? (language == .french ? "finit ce qu'il commence" : "finishes what they start") : identity, language: language)
    if let data = try? await FishAudioService().synthesize(line, referenceID: voiceID) {
      store(data, as: name)
      return data
    }
    return nil
  }
}
