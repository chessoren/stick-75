import SwiftUI

/// Today's goals with checkable rows, "+" and jokers indicator.
struct GoalsSection: View {
  @Environment(StickStore.self) private var store
  @Binding var showingAddGoal: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      StickSectionHeader("Goals") {
        HStack(spacing: 10) {
          GlassIconButton(systemImage: "plus", label: "Add a goal", tint: .ink, size: 36) {
            showingAddGoal = true
          }
          JokerPill(left: store.jokersLeft)
        }
      }

      if store.todayGoals.isEmpty {
        VStack(alignment: .leading, spacing: 6) {
          Text("No goals yet.")
            .font(StickFont.headline)
            .foregroundStyle(Color.ink)
          Text("Stick sets them with you on the wake-up call. Or add one by hand.")
            .font(StickFont.callout)
            .foregroundStyle(Color.inkSecondary)
        }
        .stickCard()
      } else {
        VStack(spacing: 10) {
          ForEach(Array(store.todayGoals.enumerated()), id: \.element.id) { index, goal in
            GoalRow(goal: goal) {
              store.toggleGoal(goal)
            }
            .appear(index: index)
            .contextMenu {
              Button(role: .destructive) {
                store.removeGoal(goal)
              } label: {
                Label("Remove", systemImage: "trash")
              }
            }
          }
        }
      }
    }
  }
}

struct GoalRow: View {
  var goal: Goal
  var toggle: () -> Void

  var body: some View {
    Button(action: toggle) {
      HStack(spacing: 14) {
        ZStack {
          Circle()
            .strokeBorder(goal.isDone ? Color.stickSuccess : Color.ink.opacity(0.25), lineWidth: 2)
            .background(Circle().fill(goal.isDone ? Color.stickSuccess : Color.clear))
          Image(systemName: "checkmark")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .opacity(goal.isDone ? 1 : 0)
            .scaleEffect(goal.isDone ? 1 : 0.4)
        }
        .frame(width: 28, height: 28)
        .animation(.bouncy(duration: 0.4), value: goal.isDone)

        Text(goal.title)
          .font(StickFont.bodyMedium)
          .foregroundStyle(goal.isDone ? Color.inkSecondary : Color.ink)
          .strikethrough(goal.isDone, color: Color.inkSecondary)
          .animation(.smooth(duration: 0.3), value: goal.isDone)
          .multilineTextAlignment(.leading)
        Spacer()
      }
      .stickCard(padding: 16, interactive: true)
    }
    .buttonStyle(PressableButtonStyle())
    .sensoryFeedback(.success, trigger: goal.isDone) { _, new in new }
    .accessibilityLabel(Text(goal.title))
    .accessibilityValue(goal.isDone ? Text("Done") : Text("Not done"))
    .accessibilityAddTraits(.isButton)
  }
}

struct JokerPill: View {
  var left: Int

  var body: some View {
    HStack(spacing: 5) {
      ForEach(0..<StickStore.jokersTotal, id: \.self) { i in
        Image(systemName: i < left ? "heart.fill" : "heart")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(i < left ? Color.brandOrange : Color.ink.opacity(0.3))
      }
    }
    .padding(.horizontal, 10)
    .frame(height: 36)
    .background(Color.white.opacity(0.7), in: Capsule())
    .glassEffect(.regular, in: .capsule)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("Jokers left"))
    .accessibilityValue(Text(left, format: .number))
  }
}

struct AddGoalSheet: View {
  @Environment(StickStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @State private var title = ""
  @FocusState private var focused: Bool

  var body: some View {
    NavigationStack {
      ZStack {
        StickCreamBackground()
        VStack(alignment: .leading, spacing: 16) {
          Text("One concrete goal for today.")
            .font(StickFont.title2)
            .stickTitleTracking()
            .foregroundStyle(Color.ink)
          TextField("Finish the report, run 5 km…", text: $title)
            .font(StickFont.body)
            .focused($focused)
            .submitLabel(.done)
            .onSubmit(add)
            .padding(16)
            .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .glassEffect(.regular, in: .rect(cornerRadius: 18))
          Spacer()
          Button(action: add) {
            Text("Add")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(StickMetrics.screenMargin)
      }
      .navigationTitle("New goal")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) { dismiss() }
        }
      }
      .onAppear { focused = true }
    }
    .presentationDetents([.medium])
  }

  private func add() {
    store.addGoal(title)
    dismiss()
  }
}
