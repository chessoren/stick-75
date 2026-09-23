import SwiftUI

struct RootView: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    @Bindable var calls = calls
    ZStack {
      Group {
        if store.state.onboardingComplete {
          MainTabView()
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
          OnboardingFlow()
            .transition(.opacity)
        }
      }
      .animation(.smooth(duration: 0.5), value: store.state.onboardingComplete)
      .fullScreenCover(isPresented: Binding(
        get: { store.state.onboardingComplete && !store.isEntitled && !calls.isPresented },
        set: { _ in }
      )) {
        PaywallView(onUnlocked: {}, onDismiss: nil)
          .environment(store)
          .interactiveDismissDisabled()
      }
    }
    .fullScreenCover(isPresented: $calls.isPresented) {
      CallScreen()
        .environment(calls)
        .environment(store)
    }
    .overlay {
      if let celebration = store.celebration {
        CelebrationView(celebration: celebration) {
          store.celebration = nil
        }
        .transition(.opacity)
        .zIndex(10)
      } else if let act = store.pendingReveal, store.state.onboardingComplete, act != .silence, !calls.isPresented {
        ActRevealView(act: act) {}
          .transition(.opacity.combined(with: .scale(scale: 1.02)))
          .zIndex(9)
      }
    }
    .animation(.smooth(duration: 0.4), value: store.celebration)
    .animation(.smooth(duration: 0.4), value: store.pendingReveal)
    .onOpenURL { url in
      guard let link = DeepLink(url: url) else { return }
      if store.state.onboardingComplete {
        calls.handle(link, store: store)
      } else if case .referral(let code) = link {
        store.applyReferral(code: code)
      } else if case .intercept = link {
        store.update { $0.profile.shortcutAutomationSet = true }
      }
    }
    .task {
      await AuthService.shared.refresh()
      if let userID = AuthService.shared.userID, AuthService.shared.isSignedIn {
        await PurchaseService.shared.identify(userID: userID)
      }
      store.absorbWidgetChanges()
      if let kind = store.pendingCallKind, store.state.onboardingComplete, !calls.isPresented {
        store.pendingCallKind = nil
        calls.start(kind, store: store)
      }
      if let entitlement = await PurchaseService.shared.currentEntitlement(),
         entitlement != .none || store.state.entitlement != .trialDays {
        store.grant(entitlement)
      }
      await store.syncRemote()
      if let voice = store.profile.voiceModelID, store.hasStarted {
        await VoiceClipCache.ensureRingtone(voiceID: voice, language: store.profile.language, act: store.currentAct)
      }
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      store.reconcile()
      store.absorbWidgetChanges()
      ScreenTimeService.shared.applyShield(enabled: store.hasStarted && store.currentAct.allowedWindowMinutes == 0)
      Task { await store.syncRemote() }
      if let kind = store.pendingCallKind, store.state.onboardingComplete, !calls.isPresented {
        store.pendingCallKind = nil
        calls.start(kind, store: store)
      }
    }
  }
}
