import Foundation

/// Pre-generated clips in the user's voice (ringtone, vault playback).
enum VoiceClipCache {
  static var directory: URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "VoiceClips")
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    return base
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

  /// Generates and caches the ringtone in the cloned voice if it does not exist yet.
  static func ensureRingtone(voiceID: String, language: AppLanguage) async {
    let name = "ringtone-\(language.rawValue)"
    guard !exists(name) else { return }
    let fish = FishAudioService()
    if let data = try? await fish.synthesize(StickPersona.ringtoneLine(language: language), referenceID: voiceID) {
      store(data, as: name)
    }
  }

  static func ringtone(language: AppLanguage) -> Data? {
    data("ringtone-\(language.rawValue)")
  }
}
