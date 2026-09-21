import SwiftUI

/// Full-screen moment for a held day, a finished act, or the 75th day. Skippable, under 1.8 s of motion.
struct CelebrationView: View {
  var celebration: StickStore.Celebration
  var dismiss: () -> Void

  @State private var shown = false
  @State private var burst = false

  var body: some View {
    ZStack {
      StickBackground(intensity: 1)
        .overlay(Color.black.opacity(0.08))

      ConfettiView(active: burst)
        .allowsHitTesting(false)

      VStack(spacing: 22) {
        Spacer()
        Image(systemName: symbol)
          .font(.system(size: 76, weight: .bold))
          .foregroundStyle(.white)
          .symbolEffect(.bounce, value: shown)
          .padding(36)
          .background(Color.white.opacity(0.22), in: Circle())
          .glassEffect(.regular.tint(.brandOrange), in: .circle)
          .scaleEffect(shown ? 1 : 0.6)
          .opacity(shown ? 1 : 0)

        VStack(spacing: 10) {
          Text(title)
            .font(StickFont.largeTitle)
            .stickTitleTracking()
            .multilineTextAlignment(.center)
          Text(subtitle)
            .font(StickFont.body)
            .multilineTextAlignment(.center)
            .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 32)
        .opacity(shown ? 1 : 0)
        .offset(y: shown ? 0 : 16)

        Spacer()

        Button(action: dismiss) {
          Text("Continue")
        }
        .buttonStyle(PrimaryPillButtonStyle())
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 24)
        .opacity(shown ? 1 : 0)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture(perform: dismiss)
    .onAppear {
      withAnimation(.bouncy(duration: 0.7)) { shown = true }
      burst = true
      switch celebration {
      case .dayHeld: StickHaptics.shared.dayValidated()
      case .actCompleted, .finisher: StickHaptics.shared.actCompleted()
      }
    }
    .accessibilityAddTraits(.isModal)
  }

  private var symbol: String {
    switch celebration {
    case .dayHeld: "checkmark"
    case .actCompleted(let act): act.symbol
    case .finisher: "crown.fill"
    }
  }

  private var title: LocalizedStringKey {
    switch celebration {
    case .dayHeld(let day): "Day \(day) held."
    case .actCompleted(let act): "Act \(act.numeral) done."
    case .finisher: "75 days."
    }
  }

  private var subtitle: LocalizedStringKey {
    switch celebration {
    case .dayHeld: "Goals set. Debrief done. Nothing slipped. One more vote for who you're becoming."
    case .actCompleted(let act):
      switch act {
      case .silence: "The hardest 15 days are behind you. Tomorrow you start replacing, not just blocking."
      case .comeback: "You have new habits now. Next: who you are when nobody's watching."
      case .identity: "You know who you are. Next act reopens the door, 15 minutes a day. Hold it."
      case .trial: "You held the window. Last act: the scaffolding comes off."
      case .flight: "You're out."
      }
    case .finisher: "You didn't quit TikTok. You became someone who doesn't need it. The vault is open."
    }
  }
}

/// Lightweight confetti with Canvas; stops after 1.8 s.
struct ConfettiView: View {
  var active: Bool
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var started = Date.now.timeIntervalSinceReferenceDate

  private let particles: [(x: Double, delay: Double, hue: Double, size: Double, drift: Double)] = (0..<60).map { i in
    var g = SeededGenerator(seed: UInt64(i + 11))
    return (Double.random(in: 0...1, using: &g), Double.random(in: 0...0.4, using: &g), Double.random(in: 0...1, using: &g), Double.random(in: 5...10, using: &g), Double.random(in: -60...60, using: &g))
  }

  var body: some View {
    if active, !reduceMotion {
      TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { context in
        Canvas { ctx, size in
          let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1000)
          let start = startTime
          let elapsed = t - start
          guard elapsed < 1.8 else { return }
          for p in particles {
            let local = elapsed - p.delay
            guard local > 0 else { continue }
            let progress = local / 1.4
            guard progress < 1 else { continue }
            let x = p.x * size.width + p.drift * progress
            let y = -20 + progress * progress * size.height * 1.1
            let rect = CGRect(x: x, y: y, width: p.size, height: p.size * 1.6)
            let color = [Color.white, Color.brandCream, Color.brandPeach, Color.ink].randomElementSeeded(p.hue)
            ctx.opacity = 1 - progress * 0.6
            ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))
          }
        }
      }
      .ignoresSafeArea()
    }
  }

  private var startTime: Double {
    started.truncatingRemainder(dividingBy: 1000)
  }
}

private extension Array where Element == Color {
  func randomElementSeeded(_ seed: Double) -> Color {
    self[Int(seed * Double(count)) % count]
  }
}
