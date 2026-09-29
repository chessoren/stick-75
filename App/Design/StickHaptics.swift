import CoreHaptics
import Foundation

/// Custom haptic patterns for the strong moments: day validated, call end, act change, rank up, ringing.
@MainActor
final class StickHaptics {
  static let shared = StickHaptics()

  private var engine: CHHapticEngine?
  private var ringPlayer: CHHapticAdvancedPatternPlayer?

  private init() {
    prepare()
  }

  private func prepare() {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
    do {
      engine = try CHHapticEngine()
      engine?.playsHapticsOnly = true
      engine?.resetHandler = { [weak self] in
        try? self?.engine?.start()
      }
      try engine?.start()
    } catch {
      engine = nil
    }
  }

  private func play(_ events: [CHHapticEvent], curves: [CHHapticParameterCurve] = []) {
    guard let engine else { return }
    do {
      try engine.start()
      let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: CHHapticTimeImmediate)
    } catch {
      // Haptics are decorative; ignore failures.
    }
  }

  /// Three rising taps then a warm buzz. Day validated.
  func dayValidated() {
    var events: [CHHapticEvent] = []
    for i in 0..<3 {
      events.append(CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [
          CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5 + Float(i) * 0.2),
          CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3 + Float(i) * 0.2)
        ],
        relativeTime: Double(i) * 0.09
      ))
    }
    events.append(CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15)
      ],
      relativeTime: 0.32,
      duration: 0.35
    ))
    play(events)
  }

  /// Long soft buzz fading out. Call ended.
  func callEnded() {
    let event = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
      ],
      relativeTime: 0,
      duration: 0.5
    )
    let curve = CHHapticParameterCurve(
      parameterID: .hapticIntensityControl,
      controlPoints: [
        .init(relativeTime: 0, value: 1),
        .init(relativeTime: 0.5, value: 0)
      ],
      relativeTime: 0
    )
    play([event], curves: [curve])
  }

  /// Drum roll then a heavy hit. Act completed.
  func actCompleted() {
    var events: [CHHapticEvent] = []
    for i in 0..<8 {
      events.append(CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [
          CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3 + Float(i) * 0.08),
          CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        ],
        relativeTime: Double(i) * 0.06
      ))
    }
    events.append(CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
      ],
      relativeTime: 0.6
    ))
    play(events)
  }

  /// Two quick ticks then a pop. Unlocking something: the ticket, a new stage.
  func unlock() {
    let events = [
      CHHapticEvent(eventType: .hapticTransient, parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
      ], relativeTime: 0),
      CHHapticEvent(eventType: .hapticTransient, parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
      ], relativeTime: 0.08),
      CHHapticEvent(eventType: .hapticTransient, parameters: [
        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
      ], relativeTime: 0.24)
    ]
    play(events)
  }

  /// Phone-like ringing pattern that loops until stopped.
  func startRinging() {
    guard let engine else { return }
    stopRinging()
    var events: [CHHapticEvent] = []
    for burst in 0..<2 {
      let start = Double(burst) * 0.45
      events.append(CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [
          CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
          CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
        ],
        relativeTime: start,
        duration: 0.3
      ))
    }
    do {
      try engine.start()
      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makeAdvancedPlayer(with: pattern)
      player.loopEnabled = true
      player.loopEnd = 2.0
      try player.start(atTime: CHHapticTimeImmediate)
      ringPlayer = player
    } catch {
      ringPlayer = nil
    }
  }

  func stopRinging() {
    try? ringPlayer?.stop(atTime: CHHapticTimeImmediate)
    ringPlayer = nil
  }
}
