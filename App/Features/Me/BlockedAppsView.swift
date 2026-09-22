import FamilyControls
import SwiftUI

/// Change the shielded apps after onboarding.
struct BlockedAppsView: View {
  @Environment(StickStore.self) private var store
  @State private var showingPicker = false
  @State private var asking = false

  private var screenTime: ScreenTimeService { .shared }

  var body: some View {
    ZStack {
      StickCreamBackground()
      VStack(alignment: .leading, spacing: 14) {
        if screenTime.isAuthorized {
          Button {
            showingPicker = true
          } label: {
            HStack {
              Image(systemName: "checklist")
                .foregroundStyle(Color.brandOrange)
              Text(screenTime.hasSelection ? "Apps selected · change" : "Choose the apps to block")
                .font(StickFont.headline)
                .foregroundStyle(Color.ink)
              Spacer()
              Image(systemName: "chevron.right")
                .foregroundStyle(Color.ink.opacity(0.4))
            }
            .stickCard(padding: 16, interactive: true)
          }
          .buttonStyle(PressableButtonStyle())
          Text(store.currentAct.allowedWindowMinutes == 0
               ? "Shield is on for this act."
               : "Shield is off for this act (15 minutes a day, on your honor). Stick still calls when an app opens.")
            .font(StickFont.footnote)
            .foregroundStyle(Color.inkSecondary)
        } else {
          VStack(alignment: .leading, spacing: 8) {
            Text("Screen Time is not connected.")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
            Text("Allow Screen Time to shield your apps. Without it, the Shortcuts automation still makes Stick call when an app opens.")
              .font(StickFont.callout)
              .foregroundStyle(Color.inkSecondary)
              .fixedSize(horizontal: false, vertical: true)
            if let error = screenTime.lastError {
              Text(error)
                .font(StickFont.caption)
                .foregroundStyle(Color.stickDanger)
            }
          }
          .stickCard()
          Button {
            asking = true
            Task {
              _ = await screenTime.requestAuthorization()
              asking = false
              if screenTime.isAuthorized { showingPicker = true }
            }
          } label: {
            Text(asking ? "Asking…" : "Allow Screen Time")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(asking)
        }
        NavigationLink("Set up instant interception") {
          ShortcutAutomationGuide()
        }
        .font(StickFont.headline)
        .foregroundStyle(Color.brandOrange)
        Spacer()
      }
      .padding(StickMetrics.screenMargin)
    }
    .navigationTitle("Blocked apps")
    .navigationBarTitleDisplayMode(.inline)
    .familyActivityPicker(isPresented: $showingPicker, selection: Binding(
      get: { screenTime.selection },
      set: { screenTime.selection = $0 }
    ))
    .onChange(of: showingPicker) { was, now in
      if was, !now {
        store.update { $0.profile.blockedAppsSelected = screenTime.hasSelection }
        screenTime.applyShield(enabled: store.currentAct.allowedWindowMinutes == 0)
      }
    }
  }
}
