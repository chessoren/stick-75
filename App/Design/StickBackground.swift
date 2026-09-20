import SwiftUI

/// Full-screen warm gradient that breathes slowly (20 s cycle). Respects Reduce Motion.
struct StickBackground: View {
  var intensity: Double = 1

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: reduceMotion)) { context in
      let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
      let phase = (t.truncatingRemainder(dividingBy: 20)) / 20 * .pi * 2
      let dx = Float(sin(phase) * 0.08)
      let dy = Float(cos(phase * 0.7) * 0.06)

      MeshGradient(
        width: 3,
        height: 4,
        points: [
          [0, 0], [0.5, 0], [1, 0],
          [0, 0.33], [0.5 + dx, 0.30 + dy], [1, 0.33],
          [0, 0.66], [0.5 - dx, 0.68 - dy], [1, 0.66],
          [0, 1], [0.5, 1], [1, 1]
        ],
        colors: [
          .brandOrangeDeep, Color(red: 0.93, green: 0.36, blue: 0.16), .brandOrangeDeep,
          .brandOrange, Color(red: 0.98, green: 0.52, blue: 0.30), .brandOrange,
          Color(red: 1.0, green: 0.62, blue: 0.40), .brandPeach, Color(red: 1.0, green: 0.64, blue: 0.42),
          Color(red: 1.0, green: 0.86, blue: 0.75), .brandCream, Color(red: 1.0, green: 0.86, blue: 0.75)
        ]
      )
      .opacity(intensity)
    }
    .background(Color.brandOrange)
    .ignoresSafeArea()
  }
}

/// Lighter cream background for secondary screens.
struct StickCreamBackground: View {
  var body: some View {
    LinearGradient(
      colors: [Color.brandSand, Color.brandCream, Color.brandCream],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
}
