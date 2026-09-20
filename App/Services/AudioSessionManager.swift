import AVFoundation

enum AudioSessionManager {
  /// Play-and-record session that keeps haptics alive while the mic is open.
  static func activateForCall() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers])
    try? session.setAllowHapticsAndSystemSoundsDuringRecording(true)
    try? session.setActive(true, options: [])
  }

  static func activateForPlayback() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
    try? session.setActive(true, options: [])
  }

  static func activateForRecording() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
    try? session.setAllowHapticsAndSystemSoundsDuringRecording(true)
    try? session.setActive(true, options: [])
  }

  static func deactivate() {
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
  }
}
