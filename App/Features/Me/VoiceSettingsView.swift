import SwiftUI

/// Voice clone status, test playback, re-record.
struct VoiceSettingsView: View {
  @Environment(StickStore.self) private var store
  @State private var isTesting = false
  @State private var testError: String?
  @State private var showingRecorder = false
  @State private var recorderModel: OnboardingModel?
  @State private var showingDelete = false
  @State private var deleting = false
  private let player = AudioPlayerService()

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Image(systemName: "waveform")
                .foregroundStyle(Color.brandOrange)
              Text(store.profile.voiceModelID == nil ? "No clone yet" : "Voice cloned")
                .font(StickFont.headline)
                .foregroundStyle(Color.ink)
            }
            Text("Stick only uses your own voice, cloned from your consent recording at Fish Audio. It is a synthetic voice. You can delete it any time.")
              .font(StickFont.callout)
              .foregroundStyle(Color.inkSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .stickCard()

          Button {
            test()
          } label: {
            Label(isTesting ? "Playing…" : "Hear my voice", systemImage: "play.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(isTesting || store.profile.voiceModelID == nil)

          Button {
            recorderModel = OnboardingModel(store: store)
            showingRecorder = true
          } label: {
            Label("Record again", systemImage: "mic.fill")
          }
          .buttonStyle(SecondaryPillButtonStyle())

          if let testError {
            Text(testError)
              .font(StickFont.footnote)
              .foregroundStyle(Color.stickDanger)
          }

          if !store.profile.voiceConsentGiven {
            Text("Recording again asks for your consent to send the sample to Fish Audio.")
              .font(StickFont.footnote)
              .foregroundStyle(Color.inkSecondary)
          }

          Toggle(isOn: Binding(
            get: { store.profile.aiConsentGiven },
            set: { value in store.update { $0.profile.aiConsentGiven = value } }
          )) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Smart replies")
                .font(StickFont.headline)
                .foregroundStyle(Color.ink)
              Text("Sends the text of your calls (no audio) to OpenRouter, an AI provider, so Stick can understand and answer you. Off: calls follow a fixed script.")
                .font(StickFont.footnote)
                .foregroundStyle(Color.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .tint(.brandOrange)
          .stickCard()

          Button(role: .destructive) {
            showingDelete = true
          } label: {
            HStack {
              Text("Delete my voice clone")
              if deleting { ProgressView() }
            }
            .font(StickFont.footnoteMedium)
            .foregroundStyle(Color.stickDanger)
            .frame(maxWidth: .infinity)
          }
          .disabled(store.profile.voiceModelID == nil || deleting)
          .padding(.top, 8)
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle("My voice")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingRecorder) {
      if let recorderModel {
        NavigationStack {
          ReconsentView(alreadyConsented: recorderModel.draft.voiceConsentGiven)
        }
        .environment(recorderModel)
      }
    }
    .confirmationDialog("Delete my voice clone?", isPresented: $showingDelete, titleVisibility: .visible) {
      Button("Delete", role: .destructive) {
        deleting = true
        testError = nil
        Task {
          do {
            try await store.deleteVoiceClone()
          } catch {
            testError = String(localized: "Stick couldn't reach the voice provider. Check your connection and try again.")
          }
          deleting = false
        }
      }
    } message: {
      Text("Stick deletes it at Fish Audio and on this iPhone. Calls use a system voice until you record again.")
    }
  }

  private func test() {
    guard let id = store.profile.voiceModelID else { return }
    isTesting = true
    testError = nil
    let line = store.profile.language == .french
      ? "C'est toi. Tu m'entends ? Demain matin, c'est moi qui te réveille."
      : "It's you. Hear that? Tomorrow morning, I'm the one waking you up."
    Task {
      AudioSessionManager.activateForPlayback()
      do {
        let data = try await FishAudioService().synthesize(line, referenceID: id)
        await player.play(data)
      } catch {
        testError = error.localizedDescription
      }
      isTesting = false
    }
  }
}

/// Re-recording: asks for consent first when it was never given (the user skipped cloning in onboarding).
private struct ReconsentView: View {
  @Environment(OnboardingModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  @State private var proceed: Bool

  init(alreadyConsented: Bool) {
    _proceed = State(initialValue: alreadyConsented)
  }

  var body: some View {
    @Bindable var model = model
    if proceed {
      VoiceRecordScreen(embedded: true)
    } else {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Before you record")
            .font(StickFont.title2)
            .foregroundStyle(Color.ink)
          ConsentRow(symbol: "cloud.fill", text: "The sample and the sentences Stick speaks are sent to Fish Audio, our voice provider, to build and use a private synthetic voice. It is never shared or made public.")
          ConsentToggle(isOn: $model.draft.voiceConsentGiven, text: "I confirm this is my own voice and I agree to send my recording to Fish Audio to create my private synthetic voice.")
          Button {
            model.persist()
            proceed = true
          } label: {
            Text("Record my voice")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(!model.draft.voiceConsentGiven)
        }
        .padding(StickMetrics.screenMargin)
      }
      .background(StickCreamBackground())
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) { dismiss() }
        }
      }
    }
  }
}
