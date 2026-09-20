import SwiftUI

/// Animated ring that fills with a smooth spring and celebrates at 100 %.
struct ProgressRing: View {
  var progress: Double
  var lineWidth: CGFloat = 6
  var tint: Color = .brandOrange
  var track: Color = Color.white.opacity(0.45)

  @State private var animated: Double = 0

  var body: some View {
    ZStack {
      Circle()
        .stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
      Circle()
        .trim(from: 0, to: max(0, min(1, animated)))
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
    .onAppear {
      withAnimation(.smooth(duration: 0.9)) { animated = progress }
    }
    .onChange(of: progress) { _, new in
      withAnimation(.smooth(duration: 0.9)) { animated = new }
    }
    .sensoryFeedback(.success, trigger: progress >= 1)
    .accessibilityLabel(Text("Progress"))
    .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
  }
}

/// Open arc ("C" shape) used by the weekly goal row in the reference design.
struct ArcDayRing: View {
  var progress: Double
  var isToday: Bool
  var lineWidth: CGFloat = 5

  @State private var animated: Double = 0

  var body: some View {
    ZStack {
      Circle()
        .trim(from: 0.08, to: 0.92)
        .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(90))
      Circle()
        .trim(from: 0.08, to: 0.08 + 0.84 * max(0, min(1, animated)))
        .stroke(Color.brandOrange, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(90))
    }
    .onAppear {
      withAnimation(.smooth(duration: 0.9).delay(0.1)) { animated = progress }
    }
    .onChange(of: progress) { _, new in
      withAnimation(.smooth(duration: 0.9)) { animated = new }
    }
  }
}
