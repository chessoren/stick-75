import FamilyControls
import SwiftUI

// MARK: - 16. Contract (finger signature)

struct ContractScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var strokes: [[CGPoint]] = []
  @State private var current: [CGPoint] = []

  private var hasSignature: Bool { strokes.contains { $0.count > 5 } }

  var body: some View {
    @Bindable var model = model
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Sign it.")
            .font(StickFont.largeTitle)
            .stickTitleTracking()
            .foregroundStyle(.white)
            .padding(.top, 12)

          VStack(alignment: .leading, spacing: 12) {
            Text("The contract")
              .font(StickFont.caption)
              .foregroundStyle(Color.inkSecondary)
            ContractLine(text: "I, \(model.draft.firstName), commit to 75 days.")
            ContractLine(text: "I pick up when my voice calls.")
            ContractLine(text: "I set real goals every morning and report every night.")
            ContractLine(text: "I never miss twice.")
            ContractLine(text: "I am becoming: \(model.draft.identityStatement)")
          }
          .stickCard()
          .appear(index: 1)

          ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .fill(Color.white.opacity(0.85))
              .glassEffect(.regular, in: .rect(cornerRadius: 24))
              .frame(height: 190)
            Canvas { ctx, _ in
              for stroke in strokes + [current] where stroke.count > 1 {
                var path = Path()
                path.move(to: stroke[0])
                for p in stroke.dropFirst() { path.addLine(to: p) }
                ctx.stroke(path, with: .color(.ink), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
              }
            }
            .frame(height: 190)
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in current.append(value.location) }
                .onEnded { _ in
                  strokes.append(current)
                  current = []
                }
            )
            HStack {
              Text(hasSignature ? "" : "Sign with your finger")
                .font(StickFont.footnote)
                .foregroundStyle(Color.inkSecondary)
              Spacer()
              if hasSignature {
                Button("Clear") { strokes = []; current = [] }
                  .font(StickFont.footnoteMedium)
                  .foregroundStyle(Color.brandOrange)
              }
            }
            .padding(14)
          }
          .appear(index: 2)
          .accessibilityLabel(Text("Signature area"))
          .accessibilityHint(Text("Draw your signature with one finger"))
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 20)
      }
      .scrollIndicators(.hidden)

      Button {
        model.signContract()
        model.next()
      } label: {
        Text("I commit to 75 days")
      }
      .buttonStyle(PrimaryPillButtonStyle())
      .disabled(!hasSignature)
      .sensoryFeedback(.success, trigger: hasSignature)
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
    }
  }
}

struct ContractLine: View {
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: "checkmark")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(Color.brandOrange)
        .padding(.top, 3)
      Text(text)
        .font(StickFont.bodyMedium)
        .foregroundStyle(Color.ink)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

// MARK: - 17. Paywall

struct PaywallStep: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    PaywallView(onUnlocked: { model.next() }, onDismiss: nil)
  }
}

// MARK: - 18. Screen Time + app selection

struct ScreenTimeScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var showingPicker = false
  @State private var requested = false
  @State private var failed = false

  private var screenTime: ScreenTimeService { .shared }

  var body: some View {
    @Bindable var model = model
    OnboardingPage("Block the apps for real.", subtitle: "Stick uses Apple's Screen Time to shield the apps you picked. When one opens, you get the shield and your voice calls.") {
      VStack(alignment: .leading, spacing: 12) {
        ConsentRow(symbol: "shield.lefthalf.filled", text: "Apple asks for Screen Time access. Stick only uses it to block and to count time on your chosen apps.")
        ConsentRow(symbol: "eye.slash.fill", text: "Stick never sees which apps you use or what you do in them. Apple keeps that on your phone.")
        if failed {
          VStack(alignment: .leading, spacing: 8) {
            Text("Screen Time isn't available on this device yet.")
              .font(StickFont.headline)
              .foregroundStyle(Color.ink)
            Text("No problem: the Shortcuts automation makes your voice call the instant TikTok opens. You'll set it up in one minute at the end.")
              .font(StickFont.callout)
              .foregroundStyle(Color.inkSecondary)
              .fixedSize(horizontal: false, vertical: true)
          }
          .stickCard()
        }
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
        }
      }
      .padding(.top, 8)
    } footer: {
      if screenTime.isAuthorized {
        Button {
          model.draft.blockedAppsSelected = screenTime.hasSelection
          model.next()
        } label: {
          Text("Continue")
        }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(!screenTime.hasSelection)
      } else if failed {
        Button { model.next() } label: { Text("Continue") }
          .buttonStyle(PrimaryPillButtonStyle())
      } else {
        Button {
          requested = true
          Task {
            let ok = await screenTime.requestAuthorization()
            model.screenTimeAuthorized = ok
            failed = !ok
            if ok { showingPicker = true }
            requested = false
          }
        } label: {
          Text(requested ? "Asking…" : "Allow Screen Time")
        }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(requested)
      }
    }
    .familyActivityPicker(isPresented: $showingPicker, selection: Binding(
      get: { screenTime.selection },
      set: { screenTime.selection = $0 }
    ))
  }
}

// MARK: - 19. Alarms + notifications

struct PermissionsScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var asking = false

  var body: some View {
    OnboardingPage("Let your voice ring.", subtitle: "The wake-up call and the debrief use iOS alarms: they ring on the Lock Screen, on your Watch, and through Silent mode.") {
      VStack(alignment: .leading, spacing: 12) {
        PermissionRow(symbol: "alarm.fill", title: "Alarms", detail: "So your voice can wake you up and ring at debrief time.", granted: model.alarmsAuthorized)
        PermissionRow(symbol: "bell.badge.fill", title: "Notifications", detail: "Backup ringer and the intercept alert when a blocked app opens.", granted: model.notificationsAuthorized)
      }
      .padding(.top, 8)
    } footer: {
      if model.alarmsAuthorized || model.notificationsAuthorized {
        Button { model.next() } label: { Text("Continue") }
          .buttonStyle(PrimaryPillButtonStyle())
      } else {
        Button {
          asking = true
          Task {
            model.alarmsAuthorized = await CallScheduler.requestAlarmAuthorization()
            model.notificationsAuthorized = await CallScheduler.requestNotificationAuthorization()
            asking = false
            if !model.alarmsAuthorized, !model.notificationsAuthorized { model.next() }
          }
        } label: {
          Text(asking ? "Asking…" : "Allow")
        }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(asking)
      }
    }
  }
}

struct PermissionRow: View {
  var symbol: String
  var title: LocalizedStringKey
  var detail: LocalizedStringKey
  var granted: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 40, height: 40)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Text(detail)
          .font(StickFont.callout)
          .foregroundStyle(Color.inkSecondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      Spacer()
      Image(systemName: granted ? "checkmark.circle.fill" : "circle")
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(granted ? Color.stickSuccess : Color.ink.opacity(0.25))
        .contentTransition(.symbolEffect(.replace))
    }
    .stickCard(padding: 14)
  }
}

// MARK: - 20. Schedule

struct ScheduleScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var wake = ClockTime.defaultWake.date
  @State private var debrief = ClockTime.defaultDebrief.date

  var body: some View {
    OnboardingPage("When do I call?", subtitle: "Two calls a day, every day. Pick times you'll actually be awake for.") {
      VStack(spacing: 12) {
        TimeCard(symbol: "sunrise.fill", title: "Wake-up call", subtitle: "Goals for the day", selection: $wake)
        TimeCard(symbol: "moon.stars.fill", title: "Evening debrief", subtitle: "What you actually did", selection: $debrief)
      }
      .padding(.top, 8)
    } footer: {
      Button {
        model.draft.wakeTime = ClockTime(date: wake)
        model.draft.debriefTime = ClockTime(date: debrief)
        model.next()
      } label: {
        Text("Continue")
      }
      .buttonStyle(PrimaryPillButtonStyle())
    }
    .onAppear {
      wake = model.draft.wakeTime.date
      debrief = model.draft.debriefTime.date
    }
  }
}

struct TimeCard: View {
  var symbol: String
  var title: LocalizedStringKey
  var subtitle: LocalizedStringKey
  @Binding var selection: Date

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 40, height: 40)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
        Text(subtitle)
          .font(StickFont.footnote)
          .foregroundStyle(Color.inkSecondary)
      }
      Spacer()
      DatePicker(selection: $selection, displayedComponents: .hourAndMinute) {
        Text(title)
      }
      .labelsHidden()
      .tint(.brandOrange)
    }
    .stickCard(padding: 14)
  }
}

// MARK: - 21. Vault

struct VaultRecordScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var recorder = VoiceRecorder()
  @State private var done = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      VStack(spacing: 14) {
        Image(systemName: done ? "lock.fill" : "lock.open.fill")
          .font(.system(size: 56, weight: .semibold))
          .foregroundStyle(.white)
          .padding(26)
          .background(Color.white.opacity(0.2), in: Circle())
          .glassEffect(.regular, in: .circle)
          .contentTransition(.symbolEffect(.replace))
        Text(done ? "Sealed until day 75." : "30 seconds for the person you'll be on day 75.")
          .font(StickFont.largeTitle)
          .stickTitleTracking()
          .multilineTextAlignment(.center)
        Text(done
             ? "Stick plays it back the night you finish. Nobody hears it before."
             : "Say why you're doing this. What you're tired of. What you want them to remember. Nobody hears it before day 75. Not even you.")
          .font(StickFont.body)
          .multilineTextAlignment(.center)
          .opacity(0.9)
      }
      .foregroundStyle(.white)
      .padding(.horizontal, StickMetrics.screenMargin + 8)
      Spacer()
      VStack(spacing: 12) {
        WaveformView(level: recorder.level, isActive: recorder.isRecording, color: .white)
          .frame(height: 50)
        if recorder.isRecording {
          Text(String(format: "0:%02d", Int(recorder.elapsed)))
            .font(StickFont.headline)
            .monospacedDigit()
            .foregroundStyle(.white)
          Button {
            stop()
          } label: {
            Label("Seal it", systemImage: "lock.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          .disabled(recorder.elapsed < 5)
        } else if done {
          Button { model.next() } label: { Text("Continue") }
            .buttonStyle(PrimaryPillButtonStyle())
        } else {
          Button {
            Task {
              guard await SpeechListener.requestPermissions() else { return }
              try? recorder.start(fileName: "vault-day1.wav")
            }
          } label: {
            Label("Record", systemImage: "mic.fill")
          }
          .buttonStyle(PrimaryPillButtonStyle())
          Button { model.next() } label: { Text("Skip for now") }
            .buttonStyle(SecondaryPillButtonStyle())
        }
      }
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
      .animation(.smooth(duration: 0.3), value: recorder.isRecording)
    }
    .onChange(of: recorder.elapsed) { _, elapsed in
      if recorder.isRecording, elapsed >= 45 { stop() }
    }
  }

  private func stop() {
    if let url = recorder.stop() {
      model.draft.vaultRecordingFileName = url.lastPathComponent
      model.persist()
      withAnimation(.bouncy(duration: 0.6)) { done = true }
    }
  }
}

// MARK: - 22. Done

struct DoneScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var shown = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      VStack(spacing: 16) {
        Text("Day 1")
          .font(StickFont.font(96, .semibold, relativeTo: .largeTitle))
          .foregroundStyle(.white)
          .scaleEffect(shown ? 1 : 0.7)
          .opacity(shown ? 1 : 0)
        Text("starts now.")
          .font(StickFont.largeTitle)
          .stickTitleTracking()
          .foregroundStyle(.white)
        Text("Your first wake-up call rings at \(model.draft.wakeTime.date, format: .dateTime.hour().minute()). Until then: one goal for today, right now.")
          .font(StickFont.body)
          .foregroundStyle(.white.opacity(0.9))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 12)
      }
      .padding(.horizontal, StickMetrics.screenMargin)
      Spacer()
      Button {
        model.finish()
      } label: {
        Text("Go")
      }
      .buttonStyle(PrimaryPillButtonStyle())
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
    }
    .onAppear {
      withAnimation(.bouncy(duration: 0.8)) { shown = true }
      StickHaptics.shared.actCompleted()
    }
  }
}
