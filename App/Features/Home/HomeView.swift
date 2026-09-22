import SwiftUI

/// "Today": greeting, week rings, hero card, Stick's suggestion, goals, act, life counter, mini league.
struct HomeView: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls
  @State private var showingSettings = false
  @State private var showingAddGoal = false

  var body: some View {
    NavigationStack {
      ZStack {
        StickBackground()
        ScrollView {
          VStack(alignment: .leading, spacing: 22) {
            header
              .appear(index: 0)

            JourneyRail()
              .appear(index: 1)

            VStack(alignment: .leading, spacing: 12) {
              StickSectionHeader("Weekly goal")
              WeekRingsView(days: store.weekCompletion())
            }
            .appear(index: 1)

            HeroGoalCard()
              .appear(index: 2)

            SuggestionCard()
              .appear(index: 3)

            InterceptionReminderCard()
              .appear(index: 3)

            GoalsSection(showingAddGoal: $showingAddGoal)
              .appear(index: 4)

            if store.isUnlocked(.habit) {
              HabitCard()
                .appear(index: 5)
            }

            if store.isUnlocked(.lifeCounter) {
              LifeCounterCard()
                .appear(index: 6)
            } else {
              LockedFeatureCard(feature: .lifeCounter)
                .appear(index: 6)
            }

            if store.isUnlocked(.trials) {
              TrialsSection()
                .appear(index: 7)
            }

            if store.isUnlocked(.postPlan) {
              PostPlanCard()
                .appear(index: 7)
            }

            if store.shouldPitchLife {
              NavigationLink {
                SubscriptionView()
              } label: {
                VStack(alignment: .leading, spacing: 6) {
                  Text("After day 75")
                    .font(StickFont.headline)
                  Text("Stick Life keeps the calls, opens new seasons and the leagues. Have a look before the end.")
                    .font(StickFont.callout)
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .stickHeroCard()
              }
              .buttonStyle(PressableButtonStyle())
              .appear(index: 6)
            }

            if store.isUnlocked(.league) {
              MiniLeaderboardCard()
                .appear(index: 8)
            } else {
              LockedFeatureCard(feature: .league)
                .appear(index: 8)
            }
          }
          .padding(.horizontal, StickMetrics.screenMargin)
          .padding(.top, 8)
          .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
      }
      .toolbar(.hidden, for: .navigationBar)
      .sheet(isPresented: $showingSettings) {
        ScheduleSettingsView()
      }
      .sheet(isPresented: $showingAddGoal) {
        AddGoalSheet()
      }
    }
  }

  private var header: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(greeting)
          .font(StickFont.largeTitle)
          .stickTitleTracking()
          .foregroundStyle(Color.ink)
        HStack(spacing: 6) {
          Text("Day \(store.dayNumber) of 75")
          Text("·")
          Text("Act \(store.currentAct.numeral)")
        }
        .font(StickFont.calloutMedium)
        .foregroundStyle(Color.ink.opacity(0.75))
      }
      Spacer()
      GlassIconButton(systemImage: "slider.horizontal.3", label: "Call schedule", tint: .ink, size: 42) {
        showingSettings = true
      }
    }
    .padding(.top, 6)
  }

  private var greeting: LocalizedStringKey {
    let hour = Calendar.current.component(.hour, from: .now)
    let name = store.profile.firstName
    if name.isEmpty {
      return hour < 12 ? "Good morning," : (hour < 18 ? "Good afternoon," : "Good evening,")
    }
    return hour < 12 ? "Good morning, \(name)" : (hour < 18 ? "Good afternoon, \(name)" : "Good evening, \(name)")
  }
}

/// Seven open arcs, Monday to Sunday, today highlighted with an orange dot.
struct WeekRingsView: View {
  var days: [(date: Date, progress: Double, isToday: Bool, dayNumber: Int)]

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(days.enumerated()), id: \.offset) { index, day in
        VStack(spacing: 8) {
          ArcDayRing(progress: day.progress, isToday: day.isToday)
            .frame(width: 38, height: 38)
            .appear(index: index)
          Text(letter(for: day.date))
            .font(StickFont.caption)
            .foregroundStyle(day.isToday ? Color.white : Color.ink.opacity(0.6))
            .frame(width: 22, height: 22)
            .background(day.isToday ? Color.brandOrange : Color.clear, in: Circle())
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide)))
        .accessibilityValue(Text(day.progress, format: .percent.precision(.fractionLength(0))))
      }
    }
    .padding(.horizontal, 4)
  }

  private func letter(for date: Date) -> String {
    let symbol = date.formatted(.dateTime.weekday(.narrow))
    return String(symbol.prefix(1)).uppercased()
  }
}
