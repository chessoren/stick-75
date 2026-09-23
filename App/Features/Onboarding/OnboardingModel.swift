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
}

/// Drives the 22-screen onboarding and writes answers into the store as it goes.
@Observable
@MainActor
final class OnboardingModel {
  var step: OnboardingStep
  var direction: Edge = .trailing
  var draft: UserProfile
  var cloneError: String?
  var isCloning = false
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
  }

  var progress: Double {
    let all = OnboardingStep.allCases
    return Double(step.rawValue) / Double(all.count - 1)
  }

  var language: AppLanguage { draft.language }

  var hoursPerYear: Int { Int(draft.hoursPerDay * 365) }
  var daysPerYear: Int { hoursPerYear / 24 }
  var hoursIn75Days: Int { Int(draft.hoursPerDay * 75) }

  func next() {
    persist()
    guard let nextStep = OnboardingStep(rawValue: step.rawValue + 1) else { return }
    direction = .trailing
    withAnimation(.smooth(duration: 0.45)) { step = nextStep }
    store.update { $0.onboardingStep = nextStep.rawValue }
  }

  func back() {
    guard step.rawValue > 0, let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
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

  /// Writes the draft into the store without clobbering flags set elsewhere (deep links, referrals).
  func persist() {
    var merged = draft
    merged.shortcutAutomationSet = merged.shortcutAutomationSet || store.profile.shortcutAutomationSet
    merged.referredBy = store.profile.referredBy ?? merged.referredBy
    merged.referralCode = store.profile.referralCode
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
    do {
      let id = try await fish.cloneVoice(
        sampleURL: url,
        title: "Stick · \(draft.firstName.isEmpty ? "User" : draft.firstName)",
        transcript: recordingScript
      )
      draft.voiceModelID = id
      draft.voiceSampleFileName = url.lastPathComponent
      persist()
      await VoiceClipCache.ensureRingtone(voiceID: id, language: language)
      isCloning = false
      if advance { next() }
    } catch {
      cloneError = error.localizedDescription
      isCloning = false
    }
  }

  func skipClone() {
    draft.voiceModelID = nil
    persist()
    next()
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
