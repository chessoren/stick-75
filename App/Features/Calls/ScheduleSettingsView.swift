import SwiftUI

/// Wake-up and debrief times, alarm permission status, Shortcuts automation guide.
struct ScheduleSettingsView: View {
  @Environment(StickStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  @State private var wake = Date.now
  @State private var debrief = Date.now
  @State private var alarmAuthorized = false

  var body: some View {
    NavigationStack {
      Form {
        Section {
          DatePicker("Wake-up call", selection: $wake, displayedComponents: .hourAndMinute)
          DatePicker("Evening debrief", selection: $debrief, displayedComponents: .hourAndMinute)
        } header: {
          Text("Daily calls")
        } footer: {
          Text("Both calls ring on the Lock Screen and Apple Watch, and break through Silent mode.")
        }

        Section {
          LabeledContent("Alarm permission") {
            Text(alarmAuthorized ? "On" : "Off")
              .foregroundStyle(alarmAuthorized ? Color.stickSuccess : Color.stickDanger)
          }
          if !alarmAuthorized {
            Button("Allow alarms") {
              Task {
                alarmAuthorized = await CallScheduler.requestAlarmAuthorization()
              }
            }
          }
        } header: {
          Text("Permissions")
        }

        Section {
          NavigationLink("Set up instant interception") {
            ShortcutAutomationGuide()
          }
        } footer: {
          Text("A Shortcuts automation opens Stick the second a blocked app launches, so your voice can call you immediately.")
        }
      }
      .scrollContentBackground(.hidden)
      .background(StickCreamBackground())
      .navigationTitle("Call schedule")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { save() }
        }
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) { dismiss() }
        }
      }
      .onAppear {
        wake = store.profile.wakeTime.date
        debrief = store.profile.debriefTime.date
        alarmAuthorized = CallScheduler.alarmStatus == .authorized
      }
    }
  }

  private func save() {
    store.update {
      $0.profile.wakeTime = ClockTime(date: wake)
      $0.profile.debriefTime = ClockTime(date: debrief)
    }
    let profile = store.profile
    Task { await CallScheduler.scheduleDailyCalls(profile: profile) }
    dismiss()
  }
}

struct ShortcutAutomationGuide: View {
  @Environment(StickStore.self) private var store

  var body: some View {
    ZStack {
      StickCreamBackground()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("When TikTok opens, Stick calls.")
            .font(StickFont.title)
            .stickTitleTracking()
            .foregroundStyle(Color.ink)
          Text("iOS lets an automation open Stick instantly when another app launches. Takes one minute.")
            .font(StickFont.callout)
            .foregroundStyle(Color.inkSecondary)

          VStack(alignment: .leading, spacing: 14) {
            StepRow(number: 1, text: "Open the Shortcuts app, tap Automation, then +.")
            StepRow(number: 2, text: "Choose \"App\", pick TikTok (and the others you block), keep \"Is Opened\", choose \"Run Immediately\".")
            StepRow(number: 3, text: "Add the action \"Open URL\" and paste: stick://intercept")
            StepRow(number: 4, text: "Done. From now on, opening TikTok makes your phone ring with your voice.")
          }
          .stickCard()

          Button {
            UIPasteboard.general.string = "stick://intercept"
            store.update { $0.profile.shortcutAutomationSet = true }
          } label: {
            Label("Copy stick://intercept", systemImage: "doc.on.doc")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .sensoryFeedback(.success, trigger: store.profile.shortcutAutomationSet)

          if let url = URL(string: "shortcuts://") {
            Link(destination: url) {
              Text("Open Shortcuts")
            }
            .buttonStyle(SecondaryPillButtonStyle())
          }
        }
        .padding(StickMetrics.screenMargin)
        .padding(.bottom, 80)
      }
    }
    .navigationTitle("Instant interception")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct StepRow: View {
  var number: Int
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text("\(number)")
        .font(StickFont.footnoteMedium)
        .foregroundStyle(.white)
        .frame(width: 26, height: 26)
        .background(Color.brandOrange, in: Circle())
      Text(text)
        .font(StickFont.callout)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
