import Foundation
import Observation
import SwiftUI

/// Orchestrates one call: ring → answer → scripted conversation (the code drives the steps,
/// the model only writes Stick's lines) → end → save.
@Observable
@MainActor
final class CallEngine {
  enum Phase: Equatable {
    case idle, ringing, connecting, speaking, listening, thinking, ended
  }

  private(set) var phase: Phase = .idle
  private(set) var kind: CallKind = .wake
  private(set) var turns: [CallTurn] = []
  private(set) var level: Double = 0
  private(set) var startedAt: Date?
  private(set) var elapsedSeconds = 0
  private(set) var lastError: String?
  private(set) var usedCloneVoice = false
  /// Set when the call could not run as a conversation (no microphone): Stick says one line and hangs up.
  private(set) var degraded = false

  /// Wake call: clean goals the user committed to.
  private(set) var extractedGoals: [String] = []
  /// Wake call: the "if… then…" plan.
  private(set) var ifThenPlan = ""
  /// Debrief: goal id → did the user say it's done.
  private(set) var goalResults: [UUID: Bool] = [:]
  /// Intercept: did the user agree to close the app.
  private(set) var interceptClosed: Bool?
  /// Act II+: the replacement habit chosen this morning.
  private(set) var habitOfDay: String?
  /// Act III+: the answer to the identity question.
  private(set) var identityAnswer: String?
  /// Act IV+: did the user hold the 15-minute window today.
  private(set) var windowHeld: Bool?
  /// Act V: what stays after day 75.
  private(set) var postPlanNote: String?

  private let fish = FishAudioService()
  private var router = OpenRouterService()
  private let player = AudioPlayerService()
  private let system = SystemSpeechService()
  private let listener = SpeechListener()
  private var loopTask: Task<Void, Never>?
  private var tickTask: Task<Void, Never>?
  private var context: StickPersona.Context?
  private var voiceID: String?
  private var history: [ChatMessage] = []

  init() {
    player.onLevel = { [weak self] in self?.level = $0 }
    listener.onLevel = { [weak self] in self?.level = $0 }
  }

  var isActive: Bool { phase != .idle && phase != .ended }
  var currentLine: String { turns.last(where: { $0.speaker == .stick })?.text ?? "" }

  // MARK: - Lifecycle

  func ring(kind: CallKind, context: StickPersona.Context, voiceID: String?) {
    reset()
    self.kind = kind
    self.context = context
    self.voiceID = voiceID
    router.enabled = context.aiEnabled
    phase = .ringing
    AppGroup.defaults.removeObject(forKey: "stick.call.endRequested")
    StickHaptics.shared.startRinging()
    LiveActivityManager.shared.start(kind: kind, userName: context.name)
    AudioSessionManager.activateForPlayback()
    Task {
      if let ringtone = VoiceClipCache.ringtone(language: context.language, act: context.act) {
        await player.play(ringtone, loop: true)
      }
    }
  }

  func answer() {
    guard phase == .ringing else { return }
    StickHaptics.shared.stopRinging()
    player.stop()
    phase = .connecting
    startedAt = .now
    LiveActivityManager.shared.update(phase: .talking, lastLine: "")
    AudioSessionManager.activateForCall()
    startTicking()
    loopTask = Task { await runScript() }
  }

  func decline() {
    StickHaptics.shared.stopRinging()
    player.stop()
    finish()
  }

  func hangUp() {
    loopTask?.cancel()
    player.stop()
    system.stop()
    listener.stop()
    finish()
  }

  private func finish() {
    guard phase != .ended else { return }
    tickTask?.cancel()
    phase = .ended
    LiveActivityManager.shared.end()
    StickHaptics.shared.callEnded()
    AudioSessionManager.deactivate()
  }

  func reset() {
    loopTask?.cancel()
    tickTask?.cancel()
    player.stop()
    system.stop()
    listener.stop()
    StickHaptics.shared.stopRinging()
    turns = []
    history = []
    level = 0
    elapsedSeconds = 0
    startedAt = nil
    lastError = nil
    extractedGoals = []
    ifThenPlan = ""
    goalResults = [:]
    interceptClosed = nil
    habitOfDay = nil
    identityAnswer = nil
    windowHeld = nil
    postPlanNote = nil
    degraded = false
    usedCloneVoice = false
    phase = .idle
  }

  private func startTicking() {
    tickTask?.cancel()
    tickTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        guard let self, let start = self.startedAt else { break }
        self.elapsedSeconds = Int(Date.now.timeIntervalSince(start))
        // "Hang up" tapped in the Dynamic Island or on the Lock Screen.
        let requested = AppGroup.defaults.double(forKey: "stick.call.endRequested")
        if requested > start.timeIntervalSince1970 {
          AppGroup.defaults.removeObject(forKey: "stick.call.endRequested")
          self.hangUp()
          break
        }
      }
    }
  }

  // MARK: - Scripts

  private func runScript() async {
    guard let context else { return }
    history = [ChatMessage(role: .system, content: StickPersona.systemPrompt(kind: kind, context: context))]
    if kind != .aha, !(await prepareConversation()) {
      degraded = true
      let line = StickPersona.cannotHearLine(kind: kind, context)
      turns.append(CallTurn(speaker: .stick, text: line))
      LiveActivityManager.shared.update(phase: .talking, lastLine: line)
      await speak(line)
      if !Task.isCancelled { hangUp() }
      return
    }
    switch kind {
    case .wake: await wakeScript(context)
    case .debrief: await debriefScript(context)
    case .intercept: await interceptScript(context)
    case .push: await pushScript(context)
    case .recovery: await recoveryScript(context)
    case .aha: await ahaScript(context)
    }
    if !Task.isCancelled { hangUp() }
  }

  /// Conversations need the microphone; without it Stick speaks once and hangs up. The model is a bonus:
  /// when the user didn't allow it, or it's unreachable (free-tier limits), the call runs on the script.
  private func prepareConversation() async -> Bool {
    if !(await SpeechListener.hasPermissions()), !(await SpeechListener.requestPermissions()) { return false }
    if router.enabled {
      let reachable = router.isAvailable ? await router.ping() : false
      if !reachable { router.enabled = false }
    }
    return true
  }

  private func wakeScript(_ c: StickPersona.Context) async {
    let language = c.language
    var refusals = 0
    var index = 0
    await say(.askGoal(1), c)
    while index < 3, !Task.isCancelled {
      let heard = await hear(c)
      if Task.isCancelled { return }
      if heard.isEmpty {
        if extractedGoals.isEmpty { await say(.notAGoal, c); refusals += 1; if refusals >= 2 { break } else { continue } }
        break
      }
      let parsed = await router.normalizeGoal(heard, existing: extractedGoals, language: language)
      if let goal = parsed.goal {
        extractedGoals.append(goal)
        index += 1
        if parsed.done || index >= 3 { break }
        await say(.askGoal(index + 1), c)
      } else if parsed.done, !extractedGoals.isEmpty {
        break
      } else {
        refusals += 1
        if refusals >= 3 { break }
        await say(.notAGoal, c)
      }
    }
    guard !extractedGoals.isEmpty, !Task.isCancelled else {
      await say(.noGoalsClose, c)
      return
    }
    if c.act.rawValue >= Act.comeback.rawValue {
      await say(.askHabit, c)
      let heard = await hear(c)
      if Task.isCancelled { return }
      let parsed = await router.normalizeGoal(heard, existing: [], language: language)
      habitOfDay = parsed.goal ?? (heard.isEmpty ? nil : heard)
    }
    switch c.act {
    case .silence, .comeback:
      await say(.askIfThen, c)
      let plan = await hear(c)
      if Task.isCancelled { return }
      ifThenPlan = plan
    case .identity, .trial:
      await say(.askIdentity, c)
      let answer = await hear(c)
      if Task.isCancelled { return }
      identityAnswer = answer.isEmpty ? nil : answer
    case .flight:
      await say(.askPostPlan, c)
      let note = await hear(c)
      if Task.isCancelled { return }
      postPlanNote = note.isEmpty ? nil : note
    }
    await say(.recap(extractedGoals), c)
  }

  private func debriefScript(_ c: StickPersona.Context) async {
    if c.goals.isEmpty {
      await say(.debriefGeneral, c)
      _ = await hear(c)
      if Task.isCancelled { return }
    } else {
      for (i, goal) in c.goals.enumerated() {
        await say(.debriefGoal(goal.title, i == 0), c)
        let heard = await hear(c)
        if Task.isCancelled { return }
        let done = await router.classifyYesNo(heard, question: "Did the user complete this goal: \(goal.title)?", language: c.language)
        goalResults[goal.id] = done ?? goal.isDone
        if done == false {
          await say(.whyNot(goal.title), c)
          _ = await hear(c)
          if Task.isCancelled { return }
        }
      }
    }
    if c.act.rawValue >= Act.comeback.rawValue {
      await say(.recoveredTime, c)
    }
    if c.act.rawValue >= Act.trial.rawValue {
      await say(.askWindow, c)
      let heard = await hear(c)
      if Task.isCancelled { return }
      windowHeld = await router.classifyYesNo(heard, question: "Did the user stay within the 15-minute window today?", language: c.language)
    }
    await say(.askTomorrow, c)
    _ = await hear(c)
    if Task.isCancelled { return }
    if c.day >= Act.totalDays {
      await say(.vaultOpen, c)
    } else {
      await say(.debriefClose, c)
    }
  }

  private func interceptScript(_ c: StickPersona.Context) async {
    await say(.confront, c)
    var heard = await hear(c)
    if Task.isCancelled { return }
    if heard.isEmpty { await say(.didntHear, c); heard = await hear(c); if Task.isCancelled { return } }
    let yes = await router.classifyYesNo(heard, question: "Did the user agree to close the app now?", language: c.language)
    if yes == false {
      interceptClosed = false
      await say(.closeNo, c)
      let second = await hear(c)
      if Task.isCancelled { return }
      let again = await router.classifyYesNo(second, question: "Did the user agree to close the app now?", language: c.language)
      interceptClosed = again == true
      await say(again == true ? .closeYes : .closeFinal, c)
    } else {
      interceptClosed = true
      await say(.closeYes, c)
    }
  }

  private func pushScript(_ c: StickPersona.Context) async {
    await say(.pushOpen, c)
    _ = await hear(c)
    if Task.isCancelled { return }
    await say(.pushOrder, c)
  }

  private func recoveryScript(_ c: StickPersona.Context) async {
    await say(.recoveryOpen, c)
    var heard = await hear(c)
    if Task.isCancelled { return }
    if heard.isEmpty { await say(.didntHear, c); heard = await hear(c); if Task.isCancelled { return } }
    await say(.recoveryClose, c)
  }

  private func ahaScript(_ c: StickPersona.Context) async {
    let line = StickPersona.scripted(.aha, c)
    turns.append(CallTurn(speaker: .stick, text: line))
    LiveActivityManager.shared.update(phase: .talking, lastLine: line)
    await speak(line)
  }

  // MARK: - Turn helpers

  /// Generates Stick's line for a script step (model with a strict directive, scripted fallback), then speaks it.
  private func say(_ step: StickPersona.Step, _ c: StickPersona.Context) async {
    phase = .thinking
    let fallback = StickPersona.scripted(step, c)
    var line = fallback
    if !step.isFixed, router.isAvailable {
      // The provider rejects requests without a user message, so the step directive travels as one.
      let directive = StickPersona.directive(step, c)
      var messages = history
      messages.append(ChatMessage(role: .user, content: directive))
      if let generated = try? await router.complete(messages, maxTokens: 120, temperature: 0.7) {
        let cleaned = StickPersona.clean(generated)
        if cleaned.count >= 4, cleaned.count <= 320 { line = cleaned }
      }
    }
    if Task.isCancelled { return }
    history.append(ChatMessage(role: .assistant, content: line))
    turns.append(CallTurn(speaker: .stick, text: line))
    LiveActivityManager.shared.update(phase: .talking, lastLine: line)
    await speak(line)
  }

  /// Listens once and records what the user said. Empty string when nothing was heard.
  private func hear(_ c: StickPersona.Context) async -> String {
    guard !Task.isCancelled else { return "" }
    phase = .listening
    let heard = (try? await listener.listen(locale: c.language.speechLocale)) ?? ""
    let text = heard.isEmpty ? "…" : heard
    turns.append(CallTurn(speaker: .user, text: text))
    history.append(ChatMessage(role: .user, content: heard.isEmpty ? "(silence)" : heard))
    return heard
  }

  private func speak(_ text: String) async {
    guard !text.isEmpty, let context else { return }
    phase = .speaking
    let budget: Duration = .seconds(min(45, 4 + Double(text.count) / 10))
    if let voiceID, let data = try? await fish.synthesize(text, referenceID: voiceID) {
      usedCloneVoice = true
      await withTimeout(budget) { await self.player.play(data) }
      player.stop()
    } else {
      await withTimeout(budget) { await self.system.speak(text, language: context.language) }
      system.stop()
    }
  }

  private func withTimeout(_ limit: Duration, _ work: @escaping @MainActor () async -> Void) async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { @MainActor in await work() }
      group.addTask { try? await Task.sleep(for: limit) }
      await group.next()
      group.cancelAll()
    }
  }

  // MARK: - Record

  func makeRecord(dayNumber: Int) -> CallRecord {
    let summary: String
    switch kind {
    case .wake where !extractedGoals.isEmpty: summary = extractedGoals.joined(separator: " · ")
    default: summary = turns.first(where: { $0.speaker == .stick })?.text ?? ""
    }
    return CallRecord(
      kind: kind,
      dayNumber: dayNumber,
      startedAt: startedAt ?? .now,
      durationSeconds: elapsedSeconds,
      turns: turns,
      summary: summary,
      answered: startedAt != nil,
      degraded: degraded
    )
  }
}
