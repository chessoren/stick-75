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
  var freeDaysUntil: Date?
  var leaderboard: [LeaderboardEntry] = []
  var lastCelebratedDay = 0
  var lastCelebratedAct = -1
  var focusModeOn = true
  var interceptionsToday = 0
  var totalInterceptions = 0
}

@Observable
@MainActor
final class StickStore {
  static let jokersTotal = 3

  private(set) var state: StickState
  var pendingCallKind: CallKind?
  var celebration: Celebration?

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
    if state.leaderboard.isEmpty {
      state.leaderboard = LeaderboardFactory.make()
    }
    reconcileMissedDays()
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
      AppGroup.defaults.removeObject(forKey: "stick.pendingCall")
      pendingCallKind = call
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
    case .wake: record.goalsSet = !todayGoals.isEmpty
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

  // MARK: - Entitlement & referral

  var isEntitled: Bool {
    if state.entitlement.isActive, state.entitlement != .trialDays { return true }
    if let until = state.freeDaysUntil, until > .now { return true }
    return false
  }

  var freeDaysLeft: Int {
    guard let until = state.freeDaysUntil, until > .now else { return 0 }
    return max(0, Calendar.current.dateComponents([.day], from: .now, to: until).day ?? 0)
  }

  func grant(_ entitlement: Entitlement) {
    update { $0.entitlement = entitlement }
  }

  /// Friends who install with your link get 5 free days.
  func applyReferral(code: String) {
    let trimmed = code.uppercased().trimmingCharacters(in: .whitespaces)
    guard trimmed.count == 6, trimmed != profile.referralCode, state.profile.referredBy == nil else { return }
    update {
      $0.profile.referredBy = trimmed
      $0.freeDaysUntil = Calendar.current.date(byAdding: .day, value: 5, to: .now)
      if $0.entitlement == .none { $0.entitlement = .trialDays }
    }
    Task { await SupabaseService.shared.registerReferral(code: trimmed) }
  }

  /// Pushes the score to Supabase and pulls the live league when the backend is configured.
  func syncRemote() async {
    let service = SupabaseService.shared
    guard await service.isConfigured else { return }
    await service.pushScore(
      name: profile.firstName,
      hours: hoursRecovered,
      daysHeld: daysHeld,
      dayNumber: dayNumber,
      referralCode: profile.referralCode
    )
    let league = await service.fetchLeague()
    if !league.isEmpty {
      update { $0.leaderboard = league }
    }
  }

  var referralURL: URL {
    URL(string: "https://stick.app/r/\(profile.referralCode)")!
  }

  // MARK: - Leaderboard

  var leaderboard: [LeaderboardEntry] {
    var entries = state.leaderboard.filter { !$0.isMe }
    entries.append(LeaderboardEntry(
      name: profile.firstName.isEmpty ? String(localized: "You") : profile.firstName,
      initials: String(profile.firstName.prefix(1)).uppercased().isEmpty ? "S" : String(profile.firstName.prefix(1)).uppercased(),
      hoursRecovered: hoursRecovered,
      daysHeld: daysHeld,
      isMe: true,
      hue: 0.06
    ))
    return entries.sorted { $0.hoursRecovered > $1.hoursRecovered }
  }

  var myRank: Int {
    (leaderboard.firstIndex(where: \.isMe) ?? 0) + 1
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
    let debrief = profile.debriefTime.next()
    return wake < debrief ? (.wake, wake) : (.debrief, debrief)
  }

  // MARK: - Debug

  func resetEverything() {
    CallScheduler.cancelAll()
    ScreenTimeService.shared.applyShield(enabled: false)
    try? FileManager.default.removeItem(at: VoiceRecorder.voiceDirectory)
    try? FileManager.default.removeItem(at: VoiceClipCache.directory)
    Task { await SupabaseService.shared.deleteAccount() }
    state = StickState()
    state.leaderboard = LeaderboardFactory.make()
    save()
  }
}

/// Seeds a believable 30-person league until Supabase is connected.
enum LeaderboardFactory {
  static func make() -> [LeaderboardEntry] {
    let names = [
      "Léa", "Maxime", "Inès", "Noah", "Chloé", "Lucas", "Manon", "Hugo", "Emma", "Théo",
      "Jade", "Nathan", "Camille", "Louis", "Sarah", "Ethan", "Zoé", "Adam", "Lina", "Gabriel",
      "Anna", "Jules", "Mia", "Rayan", "Alice", "Tom", "Nora", "Sacha", "Eva", "Liam"
    ]
    var generator = SeededGenerator(seed: 75)
    return names.enumerated().map { index, name in
      let days = Int.random(in: 3...60, using: &generator)
      let hours = Double(days) * Double.random(in: 1.4...3.6, using: &generator)
      return LeaderboardEntry(
        name: name,
        initials: String(name.prefix(1)),
        hoursRecovered: (hours * 10).rounded() / 10,
        daysHeld: days,
        hue: Double(index) / Double(names.count)
      )
    }
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
