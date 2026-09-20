import SwiftUI

/// The 30-second message you leave yourself on day 1, replayed on day 75.
struct VaultView: View {
  @Environment(StickStore.self) private var store
  @State private var isPlaying = false
  private let player = AudioPlayerService()

  var body: some View {
    ZStack {
      StickBackground()
      VStack(spacing: 24) {
        Spacer()
        Image(systemName: store.isFinished ? "lock.open.fill" : "lock.fill")
          .font(.system(size: 64, weight: .semibold))
          .foregroundStyle(.white)
          .padding(28)
          .background(Color.white.opacity(0.2), in: Circle())
          .glassEffect(.regular, in: .circle)
          .contentTransition(.symbolEffect(.replace))
        VStack(spacing: 10) {
          Text(store.isFinished ? "Day 75. It's open." : "Sealed until day 75.")
            .font(StickFont.largeTitle)
            .stickTitleTracking()
            .multilineTextAlignment(.center)
          Text(store.isFinished
               ? "This is you on day 1. Listen to who you were."
               : "On day 1 you recorded 30 seconds for the person you'd be on day 75. Nobody hears it before. Not even you.")
            .font(StickFont.body)
            .multilineTextAlignment(.center)
            .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        Spacer()
        if store.isFinished, let file = store.profile.vaultRecordingFileName {
          Button {
            isPlaying = true
            Task {
              AudioSessionManager.activateForPlayback()
              await player.play(url: VoiceRecorder.url(for: file))
              isPlaying = false
            }
          } label: {
            Label(isPlaying ? "Playing…" : "Play day 1", systemImage: "play.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(isPlaying)
          .padding(.bottom, 24)
        }
      }
      .padding(.horizontal, StickMetrics.screenMargin)
    }
    .navigationTitle("The Vault")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(.hidden, for: .navigationBar)
  }
}
