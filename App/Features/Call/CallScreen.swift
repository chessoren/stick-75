import SwiftUI

/// Full-screen call: incoming state (ringing) then the live conversation with the orange waveform.
struct CallScreen: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls

  private var engine: CallEngine { calls.engine }

  var body: some View {
    ZStack {
      StickBackground()
      if engine.phase == .ringing {
        IncomingCallView(kind: engine.kind, name: store.profile.firstName) {
          engine.answer()
        } decline: {
          engine.decline()
          calls.complete(store: store)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
      } else {
        ActiveCallView()
          .transition(.opacity)
      }
    }
    .animation(.smooth(duration: 0.4), value: engine.phase == .ringing)
    .onChange(of: engine.phase) { _, phase in
      if phase == .ended {
        Task {
          try? await Task.sleep(for: .milliseconds(900))
          guard engine.phase == .ended, calls.isPresented else { return }
          calls.complete(store: store)
        }
      }
    }
    .interactiveDismissDisabled()
  }
}

struct IncomingCallView: View {
  var kind: CallKind
  var name: String
  var answer: () -> Void
  var decline: () -> Void

  @State private var pulse = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 40)

      ZStack {
        ForEach(0..<3, id: \.self) { i in
          Circle()
            .stroke(Color.white.opacity(0.35 - Double(i) * 0.1), lineWidth: 1.5)
            .frame(width: 150 + CGFloat(i) * 60, height: 150 + CGFloat(i) * 60)
            .scaleEffect(pulse ? 1.12 : 0.92)
            .animation(.smooth(duration: 1.4).repeatForever(autoreverses: true).delay(Double(i) * 0.2), value: pulse)
        }
        Circle()
          .fill(Color.white.opacity(0.9))
          .frame(width: 136, height: 136)
          .glassEffect(.regular, in: .circle)
          .overlay {
            Text(name.isEmpty ? "S" : String(name.prefix(1)).uppercased())
              .font(StickFont.font(56, .semibold))
              .foregroundStyle(Color.brandOrange)
          }
          .stickShadow(0.35)
      }
      .padding(.bottom, 32)

      VStack(spacing: 8) {
        Text(name.isEmpty ? String(localized: "You") : name)
          .font(StickFont.largeTitle)
          .stickTitleTracking()
        Text(kind.title)
          .font(StickFont.bodyMedium)
          .opacity(0.85)
        Text("Your own voice · Stick")
          .font(StickFont.footnote)
          .opacity(0.7)
      }
      .foregroundStyle(.white)

      Spacer()

      HStack(spacing: 56) {
        VStack(spacing: 10) {
          Button(action: decline) {
            Image(systemName: "xmark")
              .font(.system(size: 26, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 76, height: 76)
              .background(Color.ink.opacity(0.85), in: Circle())
              .glassEffect(.regular.tint(.ink).interactive(), in: .circle)
          }
          .buttonStyle(PressableButtonStyle(scale: 0.92))
          .accessibilityLabel(Text("Decline"))
          Text("Decline")
            .font(StickFont.footnoteMedium)
            .foregroundStyle(.white.opacity(0.85))
        }

        VStack(spacing: 10) {
          Button(action: answer) {
            Image(systemName: "phone.fill")
              .font(.system(size: 28, weight: .bold))
              .foregroundStyle(.white)
              .frame(width: 84, height: 84)
              .background(Color.stickSuccess, in: Circle())
              .glassEffect(.regular.tint(.stickSuccess).interactive(), in: .circle)
              .scaleEffect(pulse ? 1.06 : 1)
              .animation(.smooth(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
          }
          .buttonStyle(PressableButtonStyle(scale: 0.92))
          .accessibilityLabel(Text("Answer"))
          Text("Answer")
            .font(StickFont.footnoteMedium)
            .foregroundStyle(.white.opacity(0.85))
        }
      }
      .padding(.bottom, 56)
    }
    .padding(.horizontal, StickMetrics.screenMargin)
    .onAppear { pulse = true }
  }
}

struct ActiveCallView: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls

  private var engine: CallEngine { calls.engine }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(store.profile.firstName.isEmpty ? String(localized: "You") : store.profile.firstName)
            .font(StickFont.title2)
            .stickTitleTracking()
          Text(engine.kind.title)
            .font(StickFont.footnote)
            .opacity(0.8)
        }
        Spacer()
        Text(timeString)
          .font(StickFont.headline)
          .monospacedDigit()
          .contentTransition(.numericText())
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(Color.white.opacity(0.25), in: Capsule())
          .glassEffect(.regular, in: .capsule)
      }
      .foregroundStyle(.white)
      .padding(.top, 12)

      Spacer()

      VStack(spacing: 28) {
        WaveformView(level: engine.level, isActive: engine.phase == .speaking || engine.phase == .listening, color: .white)
          .frame(maxWidth: .infinity)

        Text(statusText)
          .font(StickFont.calloutMedium)
          .foregroundStyle(.white.opacity(0.85))
          .contentTransition(.opacity)
          .animation(.smooth(duration: 0.3), value: engine.phase)
      }

      Spacer()

      transcript
        .frame(maxHeight: 260)

      Spacer(minLength: 24)

      Button {
        engine.hangUp()
      } label: {
        Label("Hang up", systemImage: "phone.down.fill")
          .labelStyle(.iconOnly)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 80, height: 80)
          .background(Color.stickDanger, in: Circle())
          .glassEffect(.regular.tint(.stickDanger).interactive(), in: .circle)
      }
      .buttonStyle(PressableButtonStyle(scale: 0.92))
      .disabled(engine.phase == .ended)
      .padding(.bottom, 44)
    }
    .padding(.horizontal, StickMetrics.screenMargin)
  }

  private var transcript: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(engine.turns) { turn in
            Text(turn.text)
              .font(turn.speaker == .stick ? StickFont.title3 : StickFont.callout)
              .foregroundStyle(turn.speaker == .stick ? Color.ink : Color.inkSecondary)
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity, alignment: turn.speaker == .stick ? .leading : .trailing)
              .background(Color.white.opacity(turn.speaker == .stick ? 0.7 : 0.4), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
              .glassEffect(.regular, in: .rect(cornerRadius: 18))
              .id(turn.id)
              .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
        .padding(.vertical, 4)
      }
      .scrollIndicators(.hidden)
      .onChange(of: engine.turns.count) { _, _ in
        if let last = engine.turns.last {
          withAnimation(.smooth(duration: 0.4)) { proxy.scrollTo(last.id, anchor: .bottom) }
        }
      }
      .animation(.bouncy(duration: 0.5), value: engine.turns.count)
    }
  }

  private var timeString: String {
    let m = engine.elapsedSeconds / 60
    let s = engine.elapsedSeconds % 60
    return String(format: "%02d:%02d", m, s)
  }

  private var statusText: LocalizedStringKey {
    switch engine.phase {
    case .connecting: "Connecting…"
    case .speaking: "Stick is talking"
    case .listening: "Your turn. Speak."
    case .thinking: "…"
    case .ended: "Call ended"
    default: ""
    }
  }
}
