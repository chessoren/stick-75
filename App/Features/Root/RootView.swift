import SwiftUI

struct RootView: View {
  @Environment(StickStore.self) private var store
  @Environment(CallCoordinator.self) private var calls
  @Environment(\.scenePhase) private var scenePhase

  var body: some View {
    @Bindable var calls = calls
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
      }
    }
    .animation(.smooth(duration: 0.4), value: store.celebration)
    .onOpenURL { url in
      guard let link = DeepLink(url: url) else { return }
      if store.state.onboardingComplete {
        calls.handle(link, store: store)
      } else if case .referral(let code) = link {
        store.applyReferral(code: code)
      }
    }
    .task {
      if let entitlement = await PurchaseService.shared.currentEntitlement(),
         entitlement != .none || store.state.entitlement != .trialDays {
        store.grant(entitlement)
      }
      await store.syncRemote()
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      store.absorbWidgetChanges()
      Task { await store.syncRemote() }
      if let kind = store.pendingCallKind, store.state.onboardingComplete, !calls.isPresented {
        store.pendingCallKind = nil
        calls.start(kind, store: store)
      }
    }
  }
}
