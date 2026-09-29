import Foundation
import Observation
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
  case hook, pitch, quizApps, quizHours, quizMoments, quizFeelings, quizDreams, quizTried, result, journey,
       identity, name, voiceConsent, voiceRecord, voiceProcessing, aha, contract, paywall, account,
       screenTime, permissions, schedule, automation, vault, done

  var showsProgress: Bool {
    switch self {
    case .hook, .pitch, .aha, .paywall, .done: false
    default: true
    }
  }

  var usesCreamBackground: Bool {
    switch self {
    case .hook, .pitch, .result, .journey, .aha, .contract, .done, .vault: false
    default: true
    }
  }

  /// Screen Time needs the Family Controls distribution entitlement; until Apple grants it, the step is skipped.
  var isEnabled: Bool {
    self != .screenTime || ScreenTimeService.isAvailable
  }
}

/// Drives the onboarding and writes answers into the store as it goes.
@Observable
@MainActor
final class OnboardingModel {
  var step: OnboardingStep
  var direction: Edge = .trailing
  var draft: UserProfile
  var cloneError: String?
  var isCloning = false
  /// The ringtone rendering in the new voice, started as soon as the clone exists.
  @ObservationIgnored private var voiceWarmUp: Task<Void, Never>?
  var recordedSampleURL: URL?
  var ahaDone = false
  var contractPath: [CGPoint] = []
  var screenTimeAuthorized = false
  var alarmsAuthorized = false
  var notificationsAuthorized = false

  private let store: StickStore

  init(store: StickStore) {
    self.store = store
    draft = store.profile
    step = OnboardingStep(rawValue: store.state.onboardingStep) ?? .hook
    if step == .voiceProcessing { step = .voiceRecord }
    if !step.isEnabled { step = Self.neighbour(of: step, forward: true) ?? .done }
  }

  var progress: Double {
    let all = OnboardingStep.allCases
    return Double(step.rawValue) / Double(all.count - 1)
  }

  var language: AppLanguage { draft.language }

  var hoursPerYear: Int { Int(draft.hoursPerDay * 365) }
  var daysPerYear: Int { hoursPerYear / 24 }
  var hoursIn75Days: Int { Int(draft.hoursPerDay * 75) }

  private static func neighbour(of step: OnboardingStep, forward: Bool) -> OnboardingStep? {
    var candidate = OnboardingStep(rawValue: step.rawValue + (forward ? 1 : -1))
    while let current = candidate, !current.isEnabled {
      candidate = OnboardingStep(rawValue: current.rawValue + (forward ? 1 : -1))
    }
    return candidate
  }

  func next() {
    persist()
    guard let nextStep = Self.neighbour(of: step, forward: true) else { return }
    direction = .trailing
    withAnimation(.smooth(duration: 0.45)) { step = nextStep }
    store.update { $0.onboardingStep = nextStep.rawValue }
  }

  func back() {
    guard step.rawValue > 0, let prev = Self.neighbour(of: step, forward: false) else { return }
    direction = .leading
    let target: OnboardingStep = prev == .voiceProcessing ? .voiceRecord : prev
    withAnimation(.smooth(duration: 0.45)) { step = target }
    store.update { $0.onboardingStep = target.rawValue }
  }

  func go(to target: OnboardingStep) {
    persist()
    direction = target.rawValue >= step.rawValue ? .trailing : .leading
    withAnimation(.smooth(duration: 0.45)) { step = target }
    store.update { $0.onboardingStep = target.rawValue }
  }

  /// Writes the draft into the store without clobbering flags set elsewhere (deep links).
  func persist() {
    var merged = draft
    merged.shortcutAutomationSet = merged.shortcutAutomationSet || store.profile.shortcutAutomationSet
    draft = merged
    store.update { $0.profile = merged }
  }

  func toggle<T: Equatable>(_ value: T, in list: inout [T]) {
    if let index = list.firstIndex(of: value) { list.remove(at: index) } else { list.append(value) }
  }

  // MARK: - Voice

  var recordingScript: String {
    StickPersona.recordingScript(name: draft.firstName, identity: draft.identityStatement, language: language)
  }

  func cloneVoice(advance: Bool = true) async {
    guard let url = recordedSampleURL else { return }
    isCloning = true
    cloneError = nil
    let fish = FishAudioService()
    let previousID = store.profile.voiceModelID
    do {
      let id = try await fish.cloneVoice(
        sampleURL: url,
        title: "Stick · \(draft.firstName.isEmpty ? "User" : draft.firstName)",
        transcript: recordingScript
      )
      draft = store.profile
      draft.voiceModelID = id
      draft.voiceSampleFileName = url.lastPathComponent
      persist()
      // Every clip rendered with the old voice goes. Then the first call's words (known now) and the ringtone
      // render in the background while the next screen announces the call, so nothing waits once it rings.
      VoiceClipCache.clear()
      VoiceClipCache.prefetchLine(StickPersona.scripted(.aha, CallCoordinator.context(store: store)), voiceID: id)
      let language = language
      let act = store.hasStarted ? store.currentAct : .silence
      voiceWarmUp = Task { await VoiceClipCache.ensureRingtone(voiceID: id, language: language, act: act) }
      // Re-recorded: the old clone goes too.
      if let previousID, previousID != id {
        Task { try? await fish.deleteVoice(id: previousID) }
      }
      isCloning = false
      if advance { next() }
    } catch {
      cloneError = error.localizedDescription
      isCloning = false
    }
  }

  /// Waits for the ringtone in the new voice, at most `limit`: past that, the call rings with the default sound.
  func waitForVoiceWarmUp(limit: Duration) async {
    guard let voiceWarmUp else { return }
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await voiceWarmUp.value }
      group.addTask { try? await Task.sleep(for: limit) }
      await group.next()
      group.cancelAll()
    }
  }

  /// Continue with the system voice: no recording, nothing sent to the voice provider.
  func skipClone() {
    draft.voiceModelID = nil
    persist()
    go(to: .aha)
  }

  // MARK: - Finish

  func signContract() {
    draft.contractSignedAt = .now
    persist()
  }

  func finish() {
    persist()
    store.startProgram()
    let profile = store.profile
    Task { await CallScheduler.scheduleDailyCalls(profile: profile, act: .silence) }
    ScreenTimeService.shared.applyShield(enabled: true)
  }
}
