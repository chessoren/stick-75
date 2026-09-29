import SwiftUI

/// Onboarding step: the Shortcuts automation that makes Stick ring the instant a blocked app opens.
/// Without it (or the Screen Time entitlement) the interception simply never fires.
struct AutomationScreen: View {
  @Environment(OnboardingModel.self) private var model
  @Environment(StickStore.self) private var store
  @State private var copied = false

  private var detected: Bool { store.profile.shortcutAutomationSet }
  private var firstApp: String {
    if let app = model.draft.timeSinks.lazy.compactMap(\.appName).first { return app }
    return model.draft.timeSinks.isEmpty ? "TikTok" : String(localized: "a blocked app")
  }

  var body: some View {
    OnboardingPage("Make it ring when \(firstApp) opens.", subtitle: "One minute in the Shortcuts app. Without this step, nothing happens when you open \(firstApp). Do it now, not later.") {
      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 14) {
          StepRow(number: 1, text: "Tap \"Open Shortcuts\" below, go to the Automation tab, tap +.")
          StepRow(number: 2, text: "Choose \"App\", pick \(firstApp) (and the other apps you block), keep \"Is Opened\", select \"Run Immediately\", then Next.")
          StepRow(number: 3, text: "Search the action \"Open URLs\", tap the URL field and paste the link below.")
          StepRow(number: 4, text: "Tap Done. Then open \(firstApp) once: Stick should ring.")
        }
        .stickCard()
        .appear(index: 2)

        Button {
          UIPasteboard.general.string = "stick://intercept"
          copied = true
        } label: {
          HStack {
            Text(verbatim: "stick://intercept")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
            Spacer()
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
              .font(StickFont.footnoteMedium)
              .foregroundStyle(Color.brandOrange)
              .contentTransition(.symbolEffect(.replace))
          }
          .stickCard(padding: 16, interactive: true)
        }
        .buttonStyle(PressableButtonStyle())
        .sensoryFeedback(.success, trigger: copied)
        .appear(index: 3)

        HStack(spacing: 12) {
          Image(systemName: detected ? "checkmark.circle.fill" : "circle.dashed")
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(detected ? Color.stickSuccess : Color.inkSecondary)
            .contentTransition(.symbolEffect(.replace))
          Text(detected ? "Automation detected. Stick rang." : "Not tested yet. Open \(firstApp) once to check.")
            .font(StickFont.calloutMedium)
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)
        }
        .stickCard(padding: 14)
        .appear(index: 4)
        .animation(.bouncy(duration: 0.5), value: detected)
      }
      .padding(.top, 4)
    } footer: {
      if detected {
        Button {
          model.draft.shortcutAutomationSet = true
          model.next()
        } label: {
          Text("Continue")
        }
        .buttonStyle(PrimaryPillButtonStyle())
      } else {
        if let url = URL(string: "shortcuts://") {
          Link(destination: url) {
            Label("Open Shortcuts", systemImage: "arrow.up.forward.app")
          }
          .buttonStyle(PrimaryPillButtonStyle())
        }
        Button {
          model.draft.shortcutAutomationSet = false
          model.next()
        } label: {
          Text("I'll do it later")
        }
        .buttonStyle(SecondaryPillButtonStyle())
      }
    }
    .onChange(of: detected) { _, new in
      if new { model.draft.shortcutAutomationSet = true }
    }
  }
}

/// Home reminder shown while the interception is not armed.
struct InterceptionReminderCard: View {
  @Environment(StickStore.self) private var store
  @State private var showingGuide = false

  private var armed: Bool { store.profile.shortcutAutomationSet || ScreenTimeService.shared.isAuthorized }

  var body: some View {
    if !armed {
      Button {
        showingGuide = true
      } label: {
        HStack(spacing: 14) {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 40, height: 40)
            .background(Color.stickDanger, in: Circle())
          VStack(alignment: .leading, spacing: 3) {
            Text("Interception is off")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
            Text("Stick can't ring when you open TikTok until the Shortcuts automation is set. One minute.")
              .font(StickFont.footnote)
              .foregroundStyle(Color.inkSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.ink.opacity(0.4))
        }
        .stickCard(padding: 14, interactive: true)
      }
      .buttonStyle(PressableButtonStyle())
      .sheet(isPresented: $showingGuide) {
        NavigationStack {
          ShortcutAutomationGuide()
        }
      }
    }
  }
}
