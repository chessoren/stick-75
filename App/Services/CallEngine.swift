import Foundation
import Observation
import SwiftUI

/// Orchestrates one call: ring → answer → (Stick speaks ↔ user talks) → end → save.
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
  private(set) var extractedGoals: [String] = []
  private(set) var usedCloneVoice = false

  private let fish = FishAudioService()
  private let router = OpenRouterService()
  private let player = AudioPlayerService()
  private let system = SystemSpeechService()
  private let listener = SpeechListener()
  private var loopTask: Task<Void, Never>?
  private var tickTask: Task<Void, Never>?
  private var context: StickPersona.Context?
  private var voiceID: String?
  private var maxTurns = 8

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
    maxTurns = kind == .aha ? 1 : (kind == .intercept || kind == .recovery ? 4 : 8)
    phase = .ringing
    StickHaptics.shared.startRinging()
    LiveActivityManager.shared.start(kind: kind, userName: context.name)
    AudioSessionManager.activateForPlayback()
    Task {
      if let ringtone = VoiceClipCache.ringtone(language: context.language) {
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
    loopTask = Task { await runConversation() }
  }

  func decline() {
    StickHaptics.shared.stopRinging()
    player.stop()
    finish(answered: false)
  }

  func hangUp() {
    loopTask?.cancel()
    player.stop()
    system.stop()
    listener.stop()
    finish(answered: true)
  }

  private func finish(answered: Bool) {
    tickTask?.cancel()
    phase = .ended
    LiveActivityManager.shared.end()
    StickHaptics.shared.callEnded()
    AudioSessionManager.deactivate()
    _ = answered
  }

  func reset() {
    loopTask?.cancel()
    tickTask?.cancel()
    player.stop()
    system.stop()
    listener.stop()
    StickHaptics.shared.stopRinging()
    turns = []
    level = 0
    elapsedSeconds = 0
    startedAt = nil
    lastError = nil
    extractedGoals = []
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
      }
    }
  }

  // MARK: - Conversation

  private func runConversation() async {
    guard let context else { return }
    var messages = [ChatMessage(role: .system, content: StickPersona.systemPrompt(kind: kind, context: context))]
    let kickoff = context.language == .french ? "(L'appel vient de commencer. Parle en premier.)" : "(The call just started. Speak first.)"
    messages.append(ChatMessage(role: .user, content: kickoff))

    phase = .thinking
    var reply = await generate(messages) ?? StickPersona.fallbackOpening(kind: kind, context: context)
    var stickTurns = 0

    while !Task.isCancelled {
      let (clean, shouldEnd) = strip(reply)
      messages.append(ChatMessage(role: .assistant, content: reply))
      turns.append(CallTurn(speaker: .stick, text: clean))
      LiveActivityManager.shared.update(phase: .talking, lastLine: clean)
      stickTurns += 1
      await speak(clean)
      if Task.isCancelled { return }
      if shouldEnd || stickTurns >= maxTurns { break }

      phase = .listening
      let heard = (try? await listener.listen(locale: context.language.speechLocale)) ?? ""
      if Task.isCancelled { return }
      let userText = heard.isEmpty ? (context.language == .french ? "(silence)" : "(silence)") : heard
      turns.append(CallTurn(speaker: .user, text: userText))
      messages.append(ChatMessage(role: .user, content: userText))

      phase = .thinking
      reply = await generate(messages) ?? StickPersona.fallbackReply(kind: kind, turn: stickTurns - 1, language: context.language)
    }

    if kind == .wake {
      extractedGoals = await router.extractGoals(from: turns, language: context.language)
      if extractedGoals.isEmpty {
        extractedGoals = turns.filter { $0.speaker == .user && !$0.text.hasPrefix("(") }.prefix(3).map { $0.text }
      }
    }
    hangUp()
  }

  private func generate(_ messages: [ChatMessage]) async -> String? {
    do {
      return try await router.complete(messages)
    } catch {
      lastError = error.localizedDescription
      return nil
    }
  }

  private func strip(_ text: String) -> (String, Bool) {
    let shouldEnd = text.contains("[END]")
    var clean = text.replacingOccurrences(of: "[END]", with: "")
    clean = clean.replacingOccurrences(of: "*", with: "")
    clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
    return (clean, shouldEnd)
  }

  private func speak(_ text: String) async {
    guard !text.isEmpty, let context else { return }
    phase = .speaking
    if let voiceID, let data = try? await fish.synthesize(text, referenceID: voiceID) {
      usedCloneVoice = true
      await player.play(data)
    } else {
      await system.speak(text, language: context.language)
    }
  }

  // MARK: - Record

  func makeRecord(dayNumber: Int) -> CallRecord {
    let summary = turns.first(where: { $0.speaker == .stick })?.text ?? ""
    return CallRecord(
      kind: kind,
      dayNumber: dayNumber,
      startedAt: startedAt ?? .now,
      durationSeconds: elapsedSeconds,
      turns: turns,
      summary: summary,
      answered: startedAt != nil
    )
  }
}
