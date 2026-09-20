import SwiftUI

/// Voice clone status, test playback, re-record.
struct VoiceSettingsView: View {
  @Environment(StickStore.self) private var store
  @State private var isTesting = false
  @State private var testError: String?
  @State private var showingRecorder = false
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
            Text("Stick only ever uses your own voice, cloned from your consent recording. It is a synthetic voice. You can delete it any time.")
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

          Button(role: .destructive) {
            store.update { $0.profile.voiceModelID = nil }
          } label: {
            Text("Delete my voice clone")
              .font(StickFont.footnoteMedium)
              .foregroundStyle(Color.stickDanger)
              .frame(maxWidth: .infinity)
          }
          .padding(.top, 8)
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle("My voice")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingRecorder) {
      NavigationStack {
        VoiceRecordScreen(embedded: true)
          .environment(OnboardingModel(store: store))
      }
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
