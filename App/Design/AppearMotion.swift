import SwiftUI

/// Everything that appears is born: scale 0.92 → 1 + opacity, bouncy spring, staggered 40 ms per index.
struct AppearModifier: ViewModifier {
  var index: Int
  var trigger: Bool

  @State private var shown = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  func body(content: Content) -> some View {
    content
      .opacity(shown ? 1 : 0)
      .scaleEffect(shown ? 1 : (reduceMotion ? 1 : 0.92))
      .offset(y: shown || reduceMotion ? 0 : 10)
      .onAppear {
        guard trigger else { return }
        reveal()
      }
      .onChange(of: trigger) { _, new in
        if new { reveal() } else { shown = false }
      }
  }

  private func reveal() {
    let delay = reduceMotion ? 0 : Double(index) * 0.04
    withAnimation(.bouncy(duration: 0.55).delay(delay)) {
      shown = true
    }
  }
}

extension View {
  func appear(index: Int = 0, when trigger: Bool = true) -> some View {
    modifier(AppearModifier(index: index, trigger: trigger))
  }
}

/// Numbers count: numeric text transitions everywhere.
struct CountingText: View {
  var value: Int
  var font: Font = StickFont.hero
  var color: Color = .ink

  var body: some View {
    Text(value, format: .number)
      .font(font)
      .monospacedDigit()
      .foregroundStyle(color)
      .contentTransition(.numericText(value: Double(value)))
      .animation(.smooth(duration: 0.6), value: value)
  }
}
