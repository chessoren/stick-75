import SwiftUI

// MARK: - 10. Identity

struct IdentityScreen: View {
  @Environment(OnboardingModel.self) private var model
  @FocusState private var focused: Bool

  var body: some View {
    @Bindable var model = model
    OnboardingPage("Who do you want to be on day 75?", subtitle: "One sentence. Your own voice will say it back to you every time you drift.") {
      VStack(alignment: .leading, spacing: 12) {
        TextField("Someone who finishes what he starts.", text: $model.draft.identityStatement, axis: .vertical)
          .font(StickFont.title3)
          .foregroundStyle(Color.ink)
          .lineLimit(2...4)
          .focused($focused)
          .padding(18)
          .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
          .glassEffect(.regular, in: .rect(cornerRadius: 22))
          .appear(index: 2)
        HStack(spacing: 8) {
          ForEach(examples, id: \.self) { example in
            Button {
              model.draft.identityStatement = example
            } label: {
              Text(example)
                .font(StickFont.caption)
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.6), in: Capsule())
                .glassEffect(.regular.interactive(), in: .capsule)
            }
            .buttonStyle(PressableButtonStyle())
          }
        }
        .appear(index: 3)
      }
      .padding(.top, 8)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(model.draft.identityStatement.trimmingCharacters(in: .whitespaces).count < 4)
    }
    .onAppear { focused = true }
  }

  private var examples: [String] {
    model.language == .french
      ? ["Quelqu'un qui finit.", "Un athlète.", "Un fondateur."]
      : ["Someone who finishes.", "An athlete.", "A founder."]
  }
}

// MARK: - 11. Name

struct NameScreen: View {
  @Environment(OnboardingModel.self) private var model
  @FocusState private var focused: Bool

  var body: some View {
    @Bindable var model = model
    OnboardingPage("What should Stick call you?", subtitle: "Your first name. It's the first word you'll hear every morning.") {
      TextField("First name", text: $model.draft.firstName)
        .font(StickFont.title2)
        .foregroundStyle(Color.ink)
        .textContentType(.givenName)
        .autocorrectionDisabled()
        .focused($focused)
        .submitLabel(.continue)
        .onSubmit { if canContinue { model.next() } }
        .padding(18)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .appear(index: 2)
        .padding(.top, 8)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(!canContinue)
    }
    .onAppear { focused = true }
  }

  private var canContinue: Bool {
    model.draft.firstName.trimmingCharacters(in: .whitespaces).count >= 2
  }
}

// MARK: - 12. Voice consent

struct VoiceConsentScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("Why your voice?", subtitle: "You can hang up on a coach. You can't hang up on yourself. Stick clones your voice so every call is you, talking to you.") {
      VStack(alignment: .leading, spacing: 12) {
        ConsentRow(symbol: "mic.fill", text: "You read a 60-second script. That's the only recording we use.")
        ConsentRow(symbol: "cloud.fill", text: "The sample is sent to Fish Audio, our voice-cloning provider, to build a private synthetic voice. It is never shared or made public.")
        ConsentRow(symbol: "person.fill.checkmark", text: "Only your own voice. Never someone else's. Stick refuses any other recording.")
        ConsentRow(symbol: "trash.fill", text: "Delete the clone any time from Me › My voice.")

        Toggle(isOn: $model.draft.voiceConsentGiven) {
          Text("I consent to cloning my own voice and to sending my recording to Fish Audio for that purpose.")
            .font(StickFont.calloutMedium)
            .foregroundStyle(Color.ink)
        }
        .tint(.brandOrange)
        .padding(16)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .appear(index: 6)
      }
      .padding(.top, 8)
    } footer: {
      Button { model.next() } label: { Text("Record my voice") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(!model.draft.voiceConsentGiven)
    }
  }
}

struct ConsentRow: View {
  var symbol: String
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 32, height: 32)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      Text(text)
        .font(StickFont.callout)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - 13. Record

struct VoiceRecordScreen: View {
  @Environment(OnboardingModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var embedded = false

  @State private var recorder = VoiceRecorder()
  @State private var permissionDenied = false
  @State private var finished = false

  private let minSeconds: TimeInterval = 25
  private let maxSeconds: TimeInterval = 75

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(recorder.isRecording ? "Read this. Naturally." : "Read this out loud.")
            .font(StickFont.largeTitle)
            .stickTitleTracking()
            .foregroundStyle(Color.ink)
            .padding(.top, 12)
          Text("About 60 seconds. Speak like you'd talk to a friend. Quiet room, phone at normal distance.")
            .font(StickFont.callout)
            .foregroundStyle(Color.inkSecondary)

          Text(model.recordingScript)
            .font(StickFont.font(20, .medium, relativeTo: .title3))
            .lineSpacing(6)
            .foregroundStyle(Color.ink)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .glassEffect(.regular, in: .rect(cornerRadius: 24))
            .appear(index: 2)
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 20)
      }
      .scrollIndicators(.hidden)

      VStack(spacing: 14) {
        WaveformView(level: recorder.level, isActive: recorder.isRecording)
          .frame(height: 56)

        HStack {
          Text(timeString)
            .font(StickFont.headline)
            .monospacedDigit()
            .foregroundStyle(Color.ink)
          Spacer()
          if recorder.isRecording, recorder.elapsed < minSeconds {
            Text("Keep going · \(Int(minSeconds - recorder.elapsed)) s more")
              .font(StickFont.footnote)
              .foregroundStyle(Color.inkSecondary)
              .contentTransition(.numericText())
          }
        }

        if permissionDenied {
          Text("Microphone access is off. Enable it in Settings › Stick to record.")
            .font(StickFont.footnote)
            .foregroundStyle(Color.stickDanger)
        }

        if recorder.isRecording {
          Button {
            stop()
          } label: {
            Label("Stop", systemImage: "stop.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle(fill: .stickDanger))
          .disabled(recorder.elapsed < minSeconds)
        } else if finished {
          Button {
            if embedded {
              Task {
                await model.cloneVoice(advance: false)
                dismiss()
              }
            } else {
              model.next()
            }
          } label: {
            Label("Use this recording", systemImage: "checkmark")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          Button {
            start()
          } label: {
            Text("Record again")
          }
          .buttonStyle(SecondaryPillButtonStyle())
        } else {
          Button {
            start()
          } label: {
            Label("Start recording", systemImage: "mic.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }
      }
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
      .animation(.smooth(duration: 0.3), value: recorder.isRecording)
      .animation(.smooth(duration: 0.3), value: finished)
    }
    .onChange(of: recorder.elapsed) { _, elapsed in
      if recorder.isRecording, elapsed >= maxSeconds { stop() }
    }
    .onDisappear { _ = recorder.stop() }
    .navigationTitle(embedded ? Text("Record again") : Text(""))
    .toolbar {
      if embedded {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) { dismiss() }
        }
      }
    }
  }

  private var timeString: String {
    let s = Int(recorder.elapsed)
    return String(format: "%d:%02d", s / 60, s % 60)
  }

  private func start() {
    finished = false
    Task {
      let ok = await SpeechListener.requestPermissions()
      guard ok else { permissionDenied = true; return }
      permissionDenied = false
      try? recorder.start(fileName: "voice-sample.wav")
    }
  }

  private func stop() {
    if let url = recorder.stop() {
      model.recordedSampleURL = url
      finished = true
    }
  }
}

// MARK: - 14. Processing

struct VoiceProcessingScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var level = 0.4
  @State private var started = false

  var body: some View {
    VStack(spacing: 28) {
      Spacer()
      TimelineView(.animation(minimumInterval: 0.08)) { context in
        let t = context.date.timeIntervalSinceReferenceDate
        WaveformView(level: model.isCloning ? 0.45 + 0.35 * sin(t * 2.2) : 0.1, isActive: model.isCloning, barCount: 32)
      }
      VStack(spacing: 8) {
        Text(model.isCloning ? "Building your voice…" : (model.cloneError == nil ? "Ready." : "That didn't work."))
          .font(StickFont.largeTitle)
          .stickTitleTracking()
          .foregroundStyle(Color.ink)
          .contentTransition(.opacity)
        Text(model.isCloning ? "About 20 seconds. Don't close the app." : (model.cloneError ?? ""))
          .font(StickFont.callout)
          .foregroundStyle(model.cloneError == nil ? Color.inkSecondary : Color.stickDanger)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 24)
      }
      Spacer()
      if !model.isCloning, model.cloneError != nil {
        VStack(spacing: 10) {
          Button {
            Task { await model.cloneVoice() }
          } label: {
            Text("Try again")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          Button {
            model.skipClone()
          } label: {
            Text("Continue with a system voice for now")
          }
          .buttonStyle(SecondaryPillButtonStyle())
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 12)
      }
    }
    .task {
      guard !started else { return }
      started = true
      await model.cloneVoice()
    }
  }
}

// MARK: - 15. Aha

struct AhaScreen: View {
  @Environment(OnboardingModel.self) private var model
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls
  @State private var rang = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      VStack(spacing: 14) {
        Image(systemName: rang ? "checkmark.seal.fill" : "phone.arrow.down.left.fill")
          .font(.system(size: 64, weight: .semibold))
          .foregroundStyle(.white)
          .padding(28)
          .background(Color.white.opacity(0.2), in: Circle())
          .glassEffect(.regular, in: .circle)
          .contentTransition(.symbolEffect(.replace))
        Text(rang ? "That was you." : "Your phone is about to ring.")
          .font(StickFont.largeTitle)
          .stickTitleTracking()
          .multilineTextAlignment(.center)
        Text(rang
             ? "From now on, that's who calls. Every morning, every night, and the second you open TikTok."
             : "It's your voice. Pick up. Listen to what you're about to promise yourself.")
          .font(StickFont.body)
          .multilineTextAlignment(.center)
          .opacity(0.9)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, StickMetrics.screenMargin + 8)
      Spacer()
      VStack(spacing: 10) {
        if rang {
          Button { model.next() } label: { Text("I'm in") }
            .buttonStyle(PrimaryPillButtonStyle())
        } else {
          Button {
            model.persist()
            calls.start(.aha, store: store)
          } label: {
            Label("Ring me", systemImage: "phone.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }
      }
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
    }
    .onChange(of: calls.isPresented) { was, now in
      if was, !now { withAnimation(.bouncy(duration: 0.6)) { rang = true } }
    }
    .onAppear {
      if store.state.calls.contains(where: { $0.kind == .aha }) { rang = true }
    }
  }
}
