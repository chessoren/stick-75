import SwiftUI

/// Shown once when a new act opens: Stick's new tone, the new calls, what unlocks, in your voice.
struct ActRevealView: View {
  @Environment(StickStore.self) private var store
  var act: Act
  var dismiss: () -> Void

  @State private var shown = false
  @State private var voiceState: VoiceState = .idle
  private let player = AudioPlayerService()

  private enum VoiceState { case idle, loading, playing, done }

  var body: some View {
    ZStack {
      StickBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          VStack(alignment: .leading, spacing: 8) {
            Text("New in Act \(act.numeral)")
              .font(StickFont.caption)
              .foregroundStyle(.white.opacity(0.8))
              .textCase(.uppercase)
            Text(act.name)
              .font(StickFont.font(48, .semibold, relativeTo: .largeTitle))
              .stickTitleTracking()
              .foregroundStyle(.white)
            Text(act.focus)
              .font(StickFont.body)
              .foregroundStyle(.white.opacity(0.9))
              .fixedSize(horizontal: false, vertical: true)
          }
          .padding(.top, 48)
          .opacity(shown ? 1 : 0)
          .offset(y: shown ? 0 : 16)

          VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
              Image(systemName: "waveform")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.brandOrange)
                .frame(width: 36, height: 36)
                .background(Color.brandOrange.opacity(0.12), in: Circle())
              VStack(alignment: .leading, spacing: 2) {
                Text("Stick becomes: \(Text(act.toneTitle))")
                  .font(StickFont.headline)
                  .foregroundStyle(Color.ink)
                Text(act.toneDescription)
                  .font(StickFont.footnote)
                  .foregroundStyle(Color.inkSecondary)
                  .fixedSize(horizontal: false, vertical: true)
              }
            }
            HStack(spacing: 10) {
              Image(systemName: "phone.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.brandOrange)
                .frame(width: 36, height: 36)
                .background(Color.brandOrange.opacity(0.12), in: Circle())
              Text(act.callsPerDay == 1 ? "One call a day. The morning one." : "\(act.callsPerDay) calls a day.")
                .font(StickFont.calloutMedium)
                .foregroundStyle(Color.ink)
            }
            HStack(spacing: 10) {
              Image(systemName: "bell.badge.waveform.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.brandOrange)
                .frame(width: 36, height: 36)
                .background(Color.brandOrange.opacity(0.12), in: Circle())
              Text("New ringtone: “\(act.ringtoneLine(language: store.profile.language))”")
                .font(StickFont.calloutMedium)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
          .stickCard()
          .appear(index: 1, when: shown)

          if !act.unlocks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Text("Unlocked")
                .font(StickFont.headline)
                .foregroundStyle(Color.ink)
              ForEach(Array(act.unlocks.enumerated()), id: \.element.id) { index, feature in
                HStack(alignment: .top, spacing: 12) {
                  Image(systemName: feature.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.brandOrange, in: Circle())
                  VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                      .font(StickFont.headline)
                      .foregroundStyle(Color.ink)
                    Text(feature.detail)
                      .font(StickFont.footnote)
                      .foregroundStyle(Color.inkSecondary)
                      .fixedSize(horizontal: false, vertical: true)
                  }
                }
                .appear(index: index + 2, when: shown)
              }
            }
            .stickCard()
            .appear(index: 2, when: shown)
          }
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 140)
      }
      .scrollIndicators(.hidden)

      VStack {
        Spacer()
        VStack(spacing: 10) {
          if store.profile.voiceModelID != nil {
            Button(action: playVoice) {
              Label(voiceLabel, systemImage: voiceState == .playing ? "waveform" : "play.fill")
            }
            .buttonStyle(SecondaryPillButtonStyle())
            .disabled(voiceState == .loading || voiceState == .playing)
          }
          Button {
            player.stop()
            store.acknowledgeReveal(act)
            dismiss()
          } label: {
            Text("Let's go")
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 16)
        .background(
          LinearGradient(colors: [.clear, Color.brandPeach.opacity(0.9)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
      }
    }
    .onAppear {
      withAnimation(.bouncy(duration: 0.7)) { shown = true }
      StickHaptics.shared.actCompleted()
      playVoice()
    }
    .accessibilityAddTraits(.isModal)
  }

  private var voiceLabel: LocalizedStringKey {
    switch voiceState {
    case .idle: "Hear Stick announce it"
    case .loading: "Preparing your voice…"
    case .playing: "Playing…"
    case .done: "Play again"
    }
  }

  private func playVoice() {
    guard let voice = store.profile.voiceModelID, voiceState != .loading, voiceState != .playing else { return }
    voiceState = .loading
    let profile = store.profile
    Task {
      guard let data = await VoiceClipCache.ensureReveal(voiceID: voice, act: act, name: profile.firstName, identity: profile.identityStatement, language: profile.language) else {
        voiceState = .done
        return
      }
      voiceState = .playing
      AudioSessionManager.activateForPlayback()
      await player.play(data)
      voiceState = .done
    }
  }
}
