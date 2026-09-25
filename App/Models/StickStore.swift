import Foundation
import Observation
import SwiftUI
import WidgetKit

/// Everything the app persists. Saved as JSON inside the App Group container.
struct StickState: Codable {
  var profile = UserProfile()
  var onboardingComplete = false
  var onboardingStep = 0
  var startDate: Date?
  var days: [DayRecord] = []
  var goals: [Goal] = []
  var calls: [CallRecord] = []
  var jokersUsed = 0
  var actRestarts = 0
  var badges: [Badge] = []
  var entitlement: Entitlement = .none
  var lastCelebratedDay = 0
  var lastCelebratedAct = -1
  var focusModeOn = true
  var interceptionsToday = 0
  var interceptionsDay = 0
  var lastSeenAct = -1
  var postPlanNotes: [String] = []
  var trialsDone: [Trial] = []
  var trialsWeek = 0
  var totalInterceptions = 0

  init() {}

  /// Every field is optional on decode so an app update that adds a field never wipes the 75 days.
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let d = StickState()
    profile = (try? c.decodeIfPresent(UserProfile.self, forKey: .profile)) ?? d.profile
    onboardingComplete = try c.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? d.onboardingComplete
    onboardingStep = try c.decodeIfPresent(Int.self, forKey: .onboardingStep) ?? d.onboardingStep
    startDate = try c.decodeIfPresent(Date.self, forKey: .startDate)
    days = (try? c.decodeIfPresent([DayRecord].self, forKey: .days)) ?? d.days
    goals = (try? c.decodeIfPresent([Goal].self, forKey: .goals)) ?? d.goals
    calls = (try? c.decodeIfPresent([CallRecord].self, forKey: .calls)) ?? d.calls
    jokersUsed = try c.decodeIfPresent(Int.self, forKey: .jokersUsed) ?? d.jokersUsed
    actRestarts = try c.decodeIfPresent(Int.self, forKey: .actRestarts) ?? d.actRestarts
    badges = ((try? c.decodeIfPresent([String].self, forKey: .badges)) ?? []).compactMap(Badge.init(rawValue:))
    entitlement = (try? c.decodeIfPresent(Entitlement.self, forKey: .entitlement)) ?? d.entitlement
    lastCelebratedDay = try c.decodeIfPresent(Int.self, forKey: .lastCelebratedDay) ?? d.lastCelebratedDay
    lastCelebratedAct = try c.decodeIfPresent(Int.self, forKey: .lastCelebratedAct) ?? d.lastCelebratedAct
    focusModeOn = try c.decodeIfPresent(Bool.self, forKey: .focusModeOn) ?? d.focusModeOn
    interceptionsToday = try c.decodeIfPresent(Int.self, forKey: .interceptionsToday) ?? d.interceptionsToday
    interceptionsDay = try c.decodeIfPresent(Int.self, forKey: .interceptionsDay) ?? d.interceptionsDay
    lastSeenAct = try c.decodeIfPresent(Int.self, forKey: .lastSeenAct) ?? d.lastSeenAct
    postPlanNotes = try c.decodeIfPresent([String].self, forKey: .postPlanNotes) ?? d.postPlanNotes
    trialsDone = ((try? c.decodeIfPresent([String].self, forKey: .trialsDone)) ?? []).compactMap(Trial.init(rawValue:))
    trialsWeek = try c.decodeIfPresent(Int.self, forKey: .trialsWeek) ?? d.trialsWeek
    totalInterceptions = try c.decodeIfPresent(Int.self, forKey: .totalInterceptions) ?? d.totalInterceptions
  }
}

@Observable
@MainActor
final class StickStore {
  static let jokersTotal = 3

  private(set) var state: StickState
  var pendingCallKind: CallKind?
  var celebration: Celebration?
  var pendingReveal: Act?

  enum Celebration: Equatable {
    case dayHeld(Int)
    case actCompleted(Act)
    case finisher
  }

  private static var fileURL: URL {
    let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)
      ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    return container.appending(path: "stick-state.json")
  }

  init() {
    if let data = try? Data(contentsOf: Self.fileURL),
       let decoded = try? JSONDecoder().decode(StickState.self, from: data) {
      state = decoded
    } else {
      state = StickState()
    }
    if state.profile.language != .device {
      state.profile.language = .device
    }
    reconcile()
    syncWidgets()
  }

  // MARK: - Persistence

  private func save() {
    if let data = try? JSONEncoder().encode(state) {
      try? data.write(to: Self.fileURL, options: .atomic)
    }
    syncWidgets()
  }

  func update(_ change: (inout StickState) -> Void) {
    change(&state)
    save()
  }

  // MARK: - Program

  var profile: UserProfile { state.profile }
  var hasStarted: Bool { state.startDate != nil }

  /// 1…75 while the program runs. 0 before start.
  var dayNumber: Int {
    guard let start = state.startDate else { return 0 }
    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: .now)).day ?? 0
    return max(1, min(Act.totalDays, days + 1))
  }

  var currentAct: Act { Act.act(forDay: max(1, dayNumber)) }
  var dayInAct: Int { max(1, dayNumber - currentAct.dayRange.lowerBound + 1) }
  var daysHeld: Int { state.days.filter(\.isHeld).count }
  var jokersLeft: Int { max(0, Self.jokersTotal - state.jokersUsed) }
  var isFinished: Bool { dayNumber >= Act.totalDays && today.isHeld }

  var today: DayRecord {
    record(forDay: dayNumber)
  }

  func record(forDay day: Int) -> DayRecord {
    if let existing = state.days.first(where: { $0.dayNumber == day }) { return existing }
    let date = Calendar.current.date(byAdding: .day, value: day - 1, to: state.startDate ?? .now) ?? .now
    return DayRecord(dayNumber: day, date: date)
  }

  private func upsert(_ record: DayRecord) {
    if let index = state.days.firstIndex(where: { $0.dayNumber == record.dayNumber }) {
      state.days[index] = record
    } else {
      state.days.append(record)
      state.days.sort { $0.dayNumber < $1.dayNumber }
    }
  }

  /// The last wake-up call today could not take goals (model or microphone unavailable).
  var lastWakeCallDegraded: Bool {
    guard let call = state.calls.first(where: { $0.kind == .wake && $0.dayNumber == dayNumber }) else { return false }
    return call.degraded
  }

  var todayGoals: [Goal] {
    state.goals.filter { $0.dayNumber == dayNumber }
  }

  var todayProgress: Double {
    var record = today
    record.goalsTotal = todayGoals.count
    record.goalsCompleted = todayGoals.filter(\.isDone).count
    return record.completion
  }

  /// Hours won back: held days × hours per day, plus today's share.
  var hoursRecovered: Double {
    let base = Double(daysHeld) * profile.hoursPerDay
    return base + todayProgress * profile.hoursPerDay * 0.5
  }

  /// Completion for the last seven days ending today (Monday-first ordering handled by the view).
  func weekCompletion() -> [(date: Date, progress: Double, isToday: Bool, dayNumber: Int)] {
    let calendar = Calendar.current
    let todayStart = calendar.startOfDay(for: .now)
    let weekday = calendar.component(.weekday, from: todayStart) // 1 = Sunday
    let mondayOffset = (weekday + 5) % 7
    let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: todayStart) ?? todayStart
    return (0..<7).map { offset in
      let date = calendar.date(byAdding: .day, value: offset, to: monday) ?? monday
      let isToday = calendar.isDate(date, inSameDayAs: todayStart)
      let number = dayNumber(for: date)
      let progress: Double
      if isToday {
        progress = todayProgress
      } else if number > 0, let record = state.days.first(where: { $0.dayNumber == number }) {
        progress = record.isHeld ? 1 : record.completion
      } else {
        progress = 0
      }
      return (date, progress, isToday, number)
    }
  }

  private func dayNumber(for date: Date) -> Int {
    guard let start = state.startDate else { return 0 }
    let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: date)).day ?? 0
    let number = days + 1
    return (1...Act.totalDays).contains(number) ? number : 0
  }

  // MARK: - Actions

  func startProgram() {
    update {
      $0.startDate = Calendar.current.startOfDay(for: .now)
      $0.onboardingComplete = true
      $0.lastSeenAct = 0
    }
  }

  func setGoals(_ titles: [String]) {
    let cleaned = titles.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    guard !cleaned.isEmpty else { return }
    let day = dayNumber
    state.goals.removeAll { $0.dayNumber == day }
    state.goals.append(contentsOf: cleaned.prefix(3).map { Goal(title: $0, dayNumber: day) })
    var record = today
    record.goalsSet = true
    record.goalsTotal = min(3, cleaned.count)
    record.goalsCompleted = 0
    upsert(record)
    save()
  }

  /// Batch update from the debrief call; the caller saves (via `addCall`).
  func setGoalDone(_ id: UUID, _ done: Bool) {
    guard let index = state.goals.firstIndex(where: { $0.id == id }) else { return }
    state.goals[index].isDone = done
  }

  func toggleGoal(_ goal: Goal) {
    guard let index = state.goals.firstIndex(where: { $0.id == goal.id }) else { return }
    state.goals[index].isDone.toggle()
    var record = today
    record.goalsCompleted = todayGoals.filter(\.isDone).count
    record.goalsTotal = todayGoals.count
    upsert(record)
    save()
    checkCelebrations()
  }

  func addGoal(_ title: String) {
    let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty, todayGoals.count < 5 else { return }
    state.goals.append(Goal(title: cleaned, dayNumber: dayNumber))
    var record = today
    record.goalsSet = true
    record.goalsTotal = todayGoals.count
    upsert(record)
    save()
  }

  func removeGoal(_ goal: Goal) {
    state.goals.removeAll { $0.id == goal.id }
    var record = today
    record.goalsTotal = todayGoals.count
    record.goalsCompleted = todayGoals.filter(\.isDone).count
    upsert(record)
    save()
  }

  /// Pulls goal toggles made from the widget back into the app.
  func absorbWidgetChanges() {
    let snapshot = SharedSnapshot.load()
    var changed = false
    for shared in snapshot.goals {
      if let index = state.goals.firstIndex(where: { $0.id == shared.id }), state.goals[index].isDone != shared.isDone {
        state.goals[index].isDone = shared.isDone
        changed = true
      }
    }
    if changed {
      var record = today
      record.goalsCompleted = todayGoals.filter(\.isDone).count
      record.goalsTotal = todayGoals.count
      upsert(record)
      save()
      checkCelebrations()
    }
    if let kind = AppGroup.defaults.string(forKey: "stick.pendingCall"), let call = CallKind(rawValue: kind) {
      // An "Answer" tapped hours ago must not ring the next time the app opens.
      let at = AppGroup.defaults.double(forKey: "stick.pendingCall.at")
      AppGroup.defaults.removeObject(forKey: "stick.pendingCall")
      if at == 0 || Date.now.timeIntervalSince1970 - at < 15 * 60 {
        pendingCallKind = call
      }
    }
  }

  func completeDebrief() {
    var record = today
    record.debriefDone = true
    record.goalsCompleted = todayGoals.filter(\.isDone).count
    record.goalsTotal = todayGoals.count
    upsert(record)
    save()
    checkCelebrations()
  }

  func recordInterception(closedApp: Bool) {
    update {
      $0.interceptionsToday += 1
      $0.totalInterceptions += 1
    }
    if !closedApp {
      recordLapse()
    }
  }

  /// A lapse is not a failure. One joker + a recovery call. Never back to day one.
  func recordLapse() {
    var record = today
    guard !record.lapsed else { return }
    record.lapsed = true
    if jokersLeft > 0 {
      record.jokerUsed = true
      state.jokersUsed += 1
      if !state.badges.contains(.recovery) { state.badges.append(.recovery) }
    }
    upsert(record)
    save()
  }

  /// Runs on launch and whenever the app comes back: day rollover, act restarts, act reveals.
  func reconcile() {
    if state.interceptionsDay != dayNumber {
      state.interceptionsDay = dayNumber
      state.interceptionsToday = 0
    }
    reconcileMissedDays()
    guard hasStarted else { return }
    let week = dayNumber / 7
    if state.trialsWeek != week {
      state.trialsWeek = week
      state.trialsDone = []
    }
    if currentAct.rawValue > state.lastSeenAct {
      if currentAct == .silence {
        state.lastSeenAct = 0
      } else {
        pendingReveal = currentAct
      }
    }
  }

  /// Called once the act reveal has been seen: reschedules calls and prepares the new ringtone and voice badge.
  func acknowledgeReveal(_ act: Act) {
    update { $0.lastSeenAct = act.rawValue }
    pendingReveal = nil
    let profile = self.profile
    Task {
      await CallScheduler.scheduleDailyCalls(profile: profile, act: act)
      if let voice = profile.voiceModelID {
        await VoiceClipCache.ensureRingtone(voiceID: voice, language: profile.language, act: act)
        await VoiceClipCache.ensureVoiceBadge(voiceID: voice, act: act, identity: profile.identityStatement, language: profile.language)
      }
    }
  }

  func isUnlocked(_ feature: Feature) -> Bool {
    hasStarted && currentAct.rawValue >= feature.unlockAct.rawValue
  }

  func daysUntil(_ feature: Feature) -> Int {
    max(0, feature.unlockDay - dayNumber)
  }

  /// Days until something new is revealed.
  var daysUntilNextReveal: Int? {
    guard let next = currentAct.next else { return nil }
    return max(0, next.dayRange.lowerBound - dayNumber)
  }

  func toggleTrial(_ trial: Trial) {
    update {
      if let index = $0.trialsDone.firstIndex(of: trial) { $0.trialsDone.remove(at: index) } else { $0.trialsDone.append(trial) }
    }
  }

  func addPostPlanNote(_ note: String) {
    let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleaned.isEmpty else { return }
    update { $0.postPlanNotes.append(cleaned) }
  }

  func setToday(habit: String?, windowHeld: Bool?, identityAnswer: String?) {
    var record = today
    if let habit, !habit.isEmpty { record.habit = habit }
    if let windowHeld { record.windowHeld = windowHeld }
    if let identityAnswer, !identityAnswer.isEmpty { record.identityAnswer = identityAnswer }
    upsert(record)
    save()
  }

  /// Real calendar date of a program day.
  func date(forDay day: Int) -> Date {
    let start = state.startDate ?? Calendar.current.startOfDay(for: .now)
    return Calendar.current.date(byAdding: .day, value: day - 1, to: start) ?? start
  }

  /// Two consecutive missed days restart the act, never the program.
  private func reconcileMissedDays() {
    guard state.startDate != nil, dayNumber > 2 else { return }
    let yesterday = record(forDay: dayNumber - 1)
    let beforeYesterday = record(forDay: dayNumber - 2)
    let missedTwice = !yesterday.isHeld && !beforeYesterday.isHeld
      && !yesterday.goalsSet && !beforeYesterday.goalsSet
    guard missedTwice, dayInAct > 2 else { return }
    let actStart = currentAct.dayRange.lowerBound
    let shift = dayNumber - actStart
    state.startDate = Calendar.current.date(byAdding: .day, value: shift, to: state.startDate ?? .now)
    state.actRestarts += 1
    state.days.removeAll { $0.dayNumber >= actStart }
    state.goals.removeAll { $0.dayNumber >= actStart }
    save()
  }

  func addCall(_ call: CallRecord) {
    state.calls.insert(call, at: 0)
    if call.kind == .aha || call.kind == .wake, !state.badges.contains(.firstCall) {
      state.badges.append(.firstCall)
    }
    var record = today
    switch call.kind {
    case .wake: record.goalsSet = !todayGoals.isEmpty || record.goalsSet
    case .debrief: record.debriefDone = true
    case .recovery: record.recoveryDone = true
    default: break
    }
    record.goalsTotal = todayGoals.count
    record.goalsCompleted = todayGoals.filter(\.isDone).count
    upsert(record)
    save()
    checkCelebrations()
  }

  private func checkCelebrations() {
    if today.isHeld, state.lastCelebratedDay != dayNumber {
      state.lastCelebratedDay = dayNumber
      awardDayBadges()
      if dayNumber == Act.totalDays {
        if !state.badges.contains(.finisher) { state.badges.append(.finisher) }
        celebration = .finisher
      } else if dayNumber == currentAct.dayRange.upperBound, state.lastCelebratedAct != currentAct.rawValue {
        state.lastCelebratedAct = currentAct.rawValue
        let badge: Badge = [.silence, .comeback, .identity, .trial, .flight][currentAct.rawValue]
        if !state.badges.contains(badge) { state.badges.append(badge) }
        celebration = .actCompleted(currentAct)
      } else {
        celebration = .dayHeld(dayNumber)
      }
      save()
    }
  }

  private func awardDayBadges() {
    if daysHeld >= 7, !state.badges.contains(.week) { state.badges.append(.week) }
    if daysHeld >= 38, !state.badges.contains(.halfway) { state.badges.append(.halfway) }
  }

  // MARK: - Entitlement

  var isEntitled: Bool { state.entitlement.isActive }

  func grant(_ entitlement: Entitlement) {
    update { $0.entitlement = entitlement }
  }

  // MARK: - Widgets

  func syncWidgets() {
    let calls = nextCall()
    let snapshot = SharedSnapshot(
      dayNumber: dayNumber,
      daysHeld: daysHeld,
      actIndex: currentAct.rawValue,
      actNameKey: String(localized: currentAct.name),
      goals: todayGoals.map { SharedSnapshot.Goal(id: $0.id, title: $0.title, isDone: $0.isDone) },
      nextCallKind: calls.map { SharedSnapshot.CallKind(rawValue: $0.kind.rawValue) ?? .wake },
      nextCallDate: calls?.date,
      hoursRecovered: hoursRecovered,
      userName: profile.firstName,
      focusModeOn: state.focusModeOn
    )
    snapshot.save()
    WidgetCenter.shared.reloadAllTimelines()
  }

  func nextCall() -> (kind: CallKind, date: Date)? {
    guard hasStarted else { return nil }
    let wake = profile.wakeTime.next()
    guard currentAct.hasDebriefCall else { return (.wake, wake) }
    let debrief = profile.debriefTime.next()
    return wake < debrief ? (.wake, wake) : (.debrief, debrief)
  }

  // MARK: - Deletion

  /// Deletes the voice clone at Fish Audio, the local sample and every clip rendered with it.
  /// Throws when the provider can't be reached; the local copy is kept so the user can retry.
  func deleteVoiceClone() async throws {
    if let voiceID = profile.voiceModelID {
      try await FishAudioService().deleteVoice(id: voiceID)
    }
    if let sample = profile.voiceSampleFileName {
      try? FileManager.default.removeItem(at: VoiceRecorder.url(for: sample))
    }
    VoiceClipCache.clear()
    update {
      $0.profile.voiceModelID = nil
      $0.profile.voiceSampleFileName = nil
    }
  }

  /// App Review 5.1.1(v): wipes everything Stick keeps on the phone and forgets the Apple sign-in.
  /// Call `deleteVoiceClone()` first so the remote voice goes too.
  func deleteAccount() async {
    CallScheduler.cancelAll()
    ScreenTimeService.shared.applyShield(enabled: false)
    LiveActivityManager.shared.end()
    try? FileManager.default.removeItem(at: VoiceRecorder.voiceDirectory)
    VoiceClipCache.clear()
    AppGroup.defaults.removeObject(forKey: AppGroup.snapshotKey)
    AppGroup.defaults.removeObject(forKey: "stick.pendingCall")
    await AuthService.shared.signOut()
    pendingCallKind = nil
    pendingReveal = nil
    celebration = nil
    state = StickState()
    save()
  }
}

struct SeededGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }

  mutating func next() -> UInt64 {
    state = state &* 6364136223846793005 &+ 1442695040888963407
    var x = state
    x ^= x >> 33
    x &*= 0xff51afd7ed558ccd
    x ^= x >> 33
    return x
  }
}
