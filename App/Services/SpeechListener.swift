import AVFoundation
import Foundation
import Speech

/// Listens with the microphone and returns what was said once the user goes quiet.
@MainActor
final class SpeechListener {
  enum ListenError: Error { case unavailable, denied }

  private let engine = AVAudioEngine()
  private var recognizer: SFSpeechRecognizer?
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  var onLevel: ((Double) -> Void)?

  static func requestPermissions() async -> Bool {
    let mic = await AVAudioApplication.requestRecordPermission()
    let speech = await withCheckedContinuation { (c: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
      SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0) }
    }
    return mic && speech == .authorized
  }

  /// Returns the transcript. Empty string if nothing was heard before `maxSilence` after speech, or `noSpeechTimeout` with no speech.
  func listen(locale: Locale, maxSilence: TimeInterval = 1.6, noSpeechTimeout: TimeInterval = 9, maxDuration: TimeInterval = 30) async throws -> String {
    stop()
    guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else { throw ListenError.unavailable }
    self.recognizer = recognizer
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.taskHint = .dictation
    self.request = request

    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    input.removeTap(onBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
      request.append(buffer)
      guard let channel = buffer.floatChannelData?[0] else { return }
      let frames = Int(buffer.frameLength)
      var sum: Float = 0
      for i in 0..<frames { sum += channel[i] * channel[i] }
      let rms = sqrt(sum / Float(max(1, frames)))
      let level = max(0, min(1, Double(rms) * 12))
      Task { @MainActor in self?.onLevel?(level) }
    }
    engine.prepare()
    try engine.start()

    var latest = ""
    var lastChange = Date.now
    let start = Date.now
    var finished = false

    task = recognizer.recognitionTask(with: request) { result, error in
      if let result {
        let text = result.bestTranscription.formattedString
        if text != latest {
          latest = text
          lastChange = .now
        }
        if result.isFinal { finished = true }
      }
      if error != nil { finished = true }
    }

    while !finished {
      try await Task.sleep(for: .milliseconds(120))
      let now = Date.now
      let elapsed = now.timeIntervalSince(start)
      if !latest.isEmpty, now.timeIntervalSince(lastChange) > maxSilence { break }
      if latest.isEmpty, elapsed > noSpeechTimeout { break }
      if elapsed > maxDuration { break }
      if Task.isCancelled { break }
    }
    stop()
    return latest.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func stop() {
    engine.inputNode.removeTap(onBus: 0)
    if engine.isRunning { engine.stop() }
    request?.endAudio()
    task?.cancel()
    task = nil
    request = nil
    onLevel?(0)
  }
}
