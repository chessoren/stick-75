import SwiftUI

/// White glass card: Stick's next move, with Dismiss / Done like the reference.
struct SuggestionCard: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls
  @State private var dismissedFor = 0

  private enum Suggestion {
    case setGoals, debrief, keepGoing(Goal), lapse, none
  }

  private var suggestion: Suggestion {
    if !store.today.goalsSet { return .setGoals }
    if store.today.lapsed, !store.today.recoveryDone { return .lapse }
    if let goal = store.todayGoals.first(where: { !$0.isDone }) { return .keepGoing(goal) }
    if !store.today.debriefDone { return .debrief }
    return .none
  }

  var body: some View {
    if dismissedFor != store.dayNumber, case .none = suggestion {
      EmptyView()
    } else if dismissedFor != store.dayNumber {
      VStack(spacing: 18) {
        Text(text)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 12) {
          Button {
            withAnimation(.smooth(duration: 0.35)) { dismissedFor = store.dayNumber }
          } label: {
            Text("Dismiss")
          }
          .buttonStyle(SecondaryPillButtonStyle())

          Button(action: primaryAction) {
            Text(primaryTitle)
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }
      }
      .stickCard(padding: 20)
    }
  }

  private var text: LocalizedStringKey {
    switch suggestion {
    case .setGoals: "Stick hasn't called yet. Set 1 to 3 goals for today with your own voice."
    case .debrief: "Every goal is done. Take the evening debrief to lock the day."
    case .keepGoing(let goal): "Next up: \(goal.title). Finish it before you touch anything else."
    case .lapse: "You slipped today. One lapse is fine, two is not. Take the recovery call."
    case .none: ""
    }
  }

  private var primaryTitle: LocalizedStringKey {
    switch suggestion {
    case .setGoals: "Call me"
    case .debrief: "Debrief"
    case .keepGoing: "Done"
    case .lapse: "Recover"
    case .none: ""
    }
  }

  private func primaryAction() {
    switch suggestion {
    case .setGoals: calls.start(.wake, store: store)
    case .debrief: calls.start(.debrief, store: store)
    case .keepGoing(let goal): store.toggleGoal(goal)
    case .lapse: calls.start(.recovery, store: store)
    case .none: break
    }
  }
}
