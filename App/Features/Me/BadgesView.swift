import SwiftUI

struct BadgesView: View {
  @Environment(StickStore.self) private var store

  private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

  @State private var playing: Act?
  private let player = AudioPlayerService()

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("Voice badges")
            .font(StickFont.title3)
            .foregroundStyle(Color.ink)
          ForEach([Act.identity, .trial, .flight]) { act in
            let available = VoiceClipCache.exists(VoiceClipCache.voiceBadgeName(act))
            let unlocked = store.hasStarted && store.currentAct.rawValue >= act.rawValue
            Button {
              guard available, let data = VoiceClipCache.data(VoiceClipCache.voiceBadgeName(act)) else { return }
              playing = act
              Task {
                AudioSessionManager.activateForPlayback()
                await player.play(data)
                playing = nil
              }
            } label: {
              HStack(spacing: 14) {
                Image(systemName: unlocked ? (playing == act ? "waveform" : "play.fill") : "lock.fill")
                  .font(.system(size: 15, weight: .bold))
                  .foregroundStyle(unlocked ? .white : Color.ink.opacity(0.5))
                  .frame(width: 40, height: 40)
                  .background(unlocked ? Color.brandOrange : Color.ink.opacity(0.06), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                  Text("Act \(act.numeral) · \(Text(act.name))")
                    .font(StickFont.headline)
                    .foregroundStyle(Color.ink)
                  Text(unlocked ? (available ? "In your voice. Tap to play." : "Recording in your voice…") : "Opens on day \(act.dayRange.lowerBound)")
                    .font(StickFont.footnote)
                    .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
              }
              .stickCard(padding: 14, interactive: unlocked)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(!unlocked || !available)
          }
          Text("Badges")
            .font(StickFont.title3)
            .foregroundStyle(Color.ink)
            .padding(.top, 8)
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(Array(Badge.allCases.enumerated()), id: \.element.id) { index, badge in
            let earned = store.state.badges.contains(badge)
            VStack(spacing: 10) {
              Image(systemName: badge.symbol)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(earned ? .white : Color.ink.opacity(0.3))
                .frame(width: 60, height: 60)
                .background(earned ? Color.brandOrange : Color.ink.opacity(0.08), in: Circle())
              Text(badge.title)
                .font(StickFont.footnoteMedium)
                .foregroundStyle(earned ? Color.ink : Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .stickCard(padding: 12)
            .opacity(earned ? 1 : 0.75)
            .appear(index: index)
          }
        }
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle("Badges")
    .navigationBarTitleDisplayMode(.inline)
  }
}
