import AVFoundation
import Foundation

/// Plays synthesized audio and reports a 0…1 level for the waveform.
@MainActor
final class AudioPlayerService: NSObject, AVAudioPlayerDelegate {
  private var player: AVAudioPlayer?
  private var continuation: CheckedContinuation<Void, Never>?
  private var meterTask: Task<Void, Never>?
  var onLevel: ((Double) -> Void)?

  func play(_ data: Data, loop: Bool = false) async {
    stop()
    guard let player = try? AVAudioPlayer(data: data) else { return }
    player.delegate = self
    player.isMeteringEnabled = true
    player.numberOfLoops = loop ? -1 : 0
    player.prepareToPlay()
    self.player = player
    player.play()
    startMetering()
    if loop { return }
    await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
      continuation = c
    }
  }

  func play(url: URL, loop: Bool = false) async {
    guard let data = try? Data(contentsOf: url) else { return }
    await play(data, loop: loop)
  }

  func stop() {
    meterTask?.cancel()
    meterTask = nil
    player?.stop()
    player = nil
    onLevel?(0)
    continuation?.resume()
    continuation = nil
  }

  private func startMetering() {
    meterTask?.cancel()
    meterTask = Task { [weak self] in
      while !Task.isCancelled {
        guard let self, let player = self.player, player.isPlaying else { break }
        player.updateMeters()
        let db = player.averagePower(forChannel: 0)
        let level = max(0, min(1, (Double(db) + 50) / 50))
        self.onLevel?(level)
        try? await Task.sleep(for: .milliseconds(50))
      }
    }
  }

  nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    Task { @MainActor in
      self.meterTask?.cancel()
      self.onLevel?(0)
      self.continuation?.resume()
      self.continuation = nil
    }
  }
}

/// System voice fallback when the clone is not available yet.
@MainActor
final class SystemSpeechService: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  private var continuation: CheckedContinuation<Void, Never>?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  func speak(_ text: String, language: AppLanguage) async {
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language == .french ? "fr-FR" : "en-US")
    utterance.rate = 0.5
    utterance.pitchMultiplier = 0.95
    await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
      continuation = c
      synthesizer.speak(utterance)
    }
  }

  func stop() {
    synthesizer.stopSpeaking(at: .immediate)
    continuation?.resume()
    continuation = nil
  }

  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    Task { @MainActor in
      self.continuation?.resume()
      self.continuation = nil
    }
  }

  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    Task { @MainActor in
      self.continuation?.resume()
      self.continuation = nil
    }
  }
}
