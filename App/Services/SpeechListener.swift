import AVFoundation
import Foundation
import Speech

/// Listens with the microphone and returns what was said once the user goes quiet.
@MainActor
final class SpeechListener {
  enum ListenError: Error { case unavailable, denied, noInput }

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

  static func hasPermissions() async -> Bool {
    let mic = AVAudioApplication.shared.recordPermission == .granted
    let speech = SFSpeechRecognizer.authorizationStatus() == .authorized
    return mic && speech
  }

  /// Returns the transcript. Empty string if nothing was said before `noSpeechTimeout`.
  /// Ends `maxSilence` seconds after the last change in the transcript (people pause mid-sentence).
  func listen(locale: Locale, maxSilence: TimeInterval = 2.2, noSpeechTimeout: TimeInterval = 9, maxDuration: TimeInterval = 40) async throws -> String {
    stop()
    guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else { throw ListenError.unavailable }
    self.recognizer = recognizer
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.taskHint = .dictation
    self.request = request

    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else { throw ListenError.noInput }
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
    do {
      try engine.start()
    } catch {
      input.removeTap(onBus: 0)
      throw ListenError.noInput
    }

    final class Box: @unchecked Sendable {
      var latest = ""
      var lastChange = Date.now
      var finished = false
    }
    let box = Box()
    let start = Date.now

    task = recognizer.recognitionTask(with: request) { result, error in
      if let result {
        let text = result.bestTranscription.formattedString
        if text != box.latest {
          box.latest = text
          box.lastChange = .now
        }
        if result.isFinal { box.finished = true }
      }
      if error != nil { box.finished = true }
    }

    while !box.finished {
      try await Task.sleep(for: .milliseconds(120))
      let now = Date.now
      let elapsed = now.timeIntervalSince(start)
      if !box.latest.isEmpty, elapsed > 1.5, now.timeIntervalSince(box.lastChange) > maxSilence { break }
      if box.latest.isEmpty, elapsed > noSpeechTimeout { break }
      if elapsed > maxDuration { break }
      if Task.isCancelled { break }
    }
    stop()
    return box.latest.trimmingCharacters(in: .whitespacesAndNewlines)
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
