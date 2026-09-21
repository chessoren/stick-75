import SwiftUI

/// Call history, next calls and quick actions.
struct CallsView: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls
  @State private var showingSchedule = false

  var body: some View {
    NavigationStack {
      ZStack {
        StickBackground(intensity: 0.85)
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
              VStack(alignment: .leading, spacing: 4) {
                Text("Calls")
                  .font(StickFont.largeTitle)
                  .stickTitleTracking()
                  .foregroundStyle(Color.ink)
                Text("Your voice. Your rules.")
                  .font(StickFont.calloutMedium)
                  .foregroundStyle(Color.ink.opacity(0.7))
              }
              Spacer()
              GlassIconButton(systemImage: "clock", label: "Call schedule", tint: .ink, size: 42) {
                showingSchedule = true
              }
            }
            .padding(.top, 6)
            .appear(index: 0)

            NextCallCard()
              .appear(index: 1)

            VStack(alignment: .leading, spacing: 12) {
              StickSectionHeader("Call now")
              HStack(spacing: 10) {
                QuickCallButton(kind: .wake) { calls.start(.wake, store: store) }
                QuickCallButton(kind: .push) { calls.start(.push, store: store) }
                QuickCallButton(kind: .debrief) { calls.start(.debrief, store: store) }
              }
            }
            .appear(index: 2)

            VStack(alignment: .leading, spacing: 12) {
              StickSectionHeader("History")
              if store.state.calls.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                  Text("No calls yet.")
                    .font(StickFont.headline)
                    .foregroundStyle(Color.ink)
                  Text("Your first wake-up call rings tomorrow at \(store.profile.wakeTime.date, format: .dateTime.hour().minute()).")
                    .font(StickFont.callout)
                    .foregroundStyle(Color.inkSecondary)
                }
                .stickCard()
              } else {
                ForEach(Array(store.state.calls.prefix(30).enumerated()), id: \.element.id) { index, call in
                  NavigationLink {
                    CallDetailView(call: call)
                  } label: {
                    CallHistoryRow(call: call)
                  }
                  .buttonStyle(PressableButtonStyle())
                  .appear(index: index)
                }
              }
            }
            .appear(index: 3)
          }
          .padding(.horizontal, StickMetrics.screenMargin)
          .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
      }
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $showingSchedule) {
        ScheduleSettingsView()
      }
    }
  }
}

struct NextCallCard: View {
  @Environment(StickStore.self) private var store

  var body: some View {
    let next = store.nextCall()
    VStack(alignment: .leading, spacing: 10) {
      Text("Next call")
        .font(StickFont.footnoteMedium)
        .opacity(0.85)
      if let next {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(next.date, format: .dateTime.hour().minute())
            .font(StickFont.heroSmall)
            .monospacedDigit()
          Text(next.kind.title)
            .font(StickFont.title3)
            .opacity(0.9)
        }
        Text(next.date, format: .relative(presentation: .named))
          .font(StickFont.callout)
          .opacity(0.85)
      } else {
        Text("Starts once the program begins.")
          .font(StickFont.title3)
      }
    }
    .stickHeroCard()
  }
}

struct QuickCallButton: View {
  var kind: CallKind
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Image(systemName: kind.symbol)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(Color.brandOrange)
        Text(kind.title)
          .font(StickFont.caption)
          .foregroundStyle(Color.ink)
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 84)
      .stickCard(padding: 10, interactive: true)
    }
    .buttonStyle(PressableButtonStyle())
  }
}

struct CallHistoryRow: View {
  var call: CallRecord

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: call.kind.symbol)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(call.answered ? Color.brandOrange : Color.stickDanger)
        .frame(width: 40, height: 40)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 3) {
        Text(call.kind.title)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Text(call.summary.isEmpty ? String(localized: "Missed") : call.summary)
          .font(StickFont.footnote)
          .foregroundStyle(Color.inkSecondary)
          .lineLimit(1)
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 3) {
        Text(call.startedAt, format: .dateTime.day().month(.abbreviated))
          .font(StickFont.caption)
          .foregroundStyle(Color.inkSecondary)
        Text(duration)
          .font(StickFont.caption)
          .monospacedDigit()
          .foregroundStyle(Color.inkSecondary)
      }
    }
    .stickCard(padding: 14, interactive: true)
  }

  private var duration: String {
    String(format: "%d:%02d", call.durationSeconds / 60, call.durationSeconds % 60)
  }
}

struct CallDetailView: View {
  var call: CallRecord

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Day \(call.dayNumber)")
            Text("·")
            Text(call.startedAt, format: .dateTime.weekday(.wide).hour().minute())
          }
          .font(StickFont.footnoteMedium)
          .foregroundStyle(Color.inkSecondary)

          ForEach(call.turns) { turn in
            VStack(alignment: .leading, spacing: 4) {
              Text(turn.speaker == .stick ? "Stick" : "You")
                .font(StickFont.caption)
                .foregroundStyle(turn.speaker == .stick ? Color.brandOrange : Color.inkSecondary)
              Text(turn.text)
                .font(StickFont.body)
                .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .stickCard(padding: 14)
          }
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle(Text(call.kind.title))
    .navigationBarTitleDisplayMode(.inline)
  }
}
