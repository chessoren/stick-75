import SwiftUI

/// Orange audio waveform. `level` in 0…1 drives amplitude; bars idle-breathe when silent.
struct WaveformView: View {
  var level: Double
  var isActive: Bool
  var barCount = 28
  var color: Color = .brandOrange

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isActive)) { context in
      let t = context.date.timeIntervalSinceReferenceDate
      HStack(alignment: .center, spacing: 4) {
        ForEach(0..<barCount, id: \.self) { i in
          let phase = t * 6 + Double(i) * 0.55
          let envelope = 0.35 + 0.65 * sin(Double(i) / Double(barCount) * .pi)
          let wobble = (sin(phase) + 1) / 2
          let amp = isActive ? (0.12 + level * envelope * (0.55 + 0.45 * wobble)) : 0.08
          Capsule()
            .fill(color)
            .frame(width: 4, height: max(6, 64 * amp))
        }
      }
      .frame(height: 72)
      .animation(.smooth(duration: 0.15), value: level)
    }
    .accessibilityHidden(true)
  }
}
