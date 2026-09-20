import AVFoundation
import Foundation
import Observation

/// Records the 60-second voice sample (and the day-1 vault message) as WAV.
@Observable
@MainActor
final class VoiceRecorder: NSObject, AVAudioRecorderDelegate {
  private(set) var isRecording = false
  private(set) var level: Double = 0
  private(set) var elapsed: TimeInterval = 0
  private var recorder: AVAudioRecorder?
  private var meterTask: Task<Void, Never>?

  static var voiceDirectory: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appending(path: "Voice")
    try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    return base
  }

  static func url(for fileName: String) -> URL {
    voiceDirectory.appending(path: fileName)
  }

  func start(fileName: String) throws {
    AudioSessionManager.activateForRecording()
    let url = Self.url(for: fileName)
    try? FileManager.default.removeItem(at: url)
    let settings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: 24_000,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false
    ]
    let recorder = try AVAudioRecorder(url: url, settings: settings)
    recorder.delegate = self
    recorder.isMeteringEnabled = true
    recorder.prepareToRecord()
    recorder.record()
    self.recorder = recorder
    isRecording = true
    elapsed = 0
    meterTask?.cancel()
    meterTask = Task { [weak self] in
      while !Task.isCancelled {
        guard let self, let recorder = self.recorder, recorder.isRecording else { break }
        recorder.updateMeters()
        let db = recorder.averagePower(forChannel: 0)
        self.level = max(0, min(1, (Double(db) + 50) / 50))
        self.elapsed = recorder.currentTime
        try? await Task.sleep(for: .milliseconds(60))
      }
    }
  }

  @discardableResult
  func stop() -> URL? {
    meterTask?.cancel()
    let url = recorder?.url
    recorder?.stop()
    recorder = nil
    isRecording = false
    level = 0
    return url
  }
}
