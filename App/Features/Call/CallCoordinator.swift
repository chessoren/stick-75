import Foundation
import Observation
import SwiftUI

/// Bridges the store and the call engine: builds the persona context, presents the call, saves the record.
@Observable
@MainActor
final class CallCoordinator {
  let engine = CallEngine()
  var isPresented = false
  var pendingDeepLink: DeepLink?
  var selectedTab: MainTab = .today

  func start(_ kind: CallKind, store: StickStore) {
    let profile = store.profile
    let context = StickPersona.Context(
      name: profile.firstName,
      identity: profile.identityStatement,
      day: max(1, store.dayNumber),
      act: store.currentAct,
      goals: store.todayGoals,
      hoursPerDay: profile.hoursPerDay,
      hoursRecovered: store.hoursRecovered,
      jokersLeft: store.jokersLeft,
      timeSinks: profile.timeSinks,
      language: profile.language
    )
    engine.ring(kind: kind, context: context, voiceID: profile.voiceModelID)
    isPresented = true
  }

  /// Called when the call screen is dismissed.
  func complete(store: StickStore) {
    defer {
      engine.reset()
      isPresented = false
    }
    guard engine.startedAt != nil else { return }
    let record = engine.makeRecord(dayNumber: store.dayNumber)
    if engine.kind == .wake, !engine.extractedGoals.isEmpty {
      store.setGoals(engine.extractedGoals)
    }
    if engine.kind == .intercept {
      let saidYes = engine.turns.contains { turn in
        turn.speaker == .user && ["oui", "yes", "ok", "je ferme", "closing", "close"].contains { turn.text.lowercased().contains($0) }
      }
      store.recordInterception(closedApp: saidYes || engine.turns.count <= 2)
    }
    store.addCall(record)
  }

  func handle(_ link: DeepLink, store: StickStore) {
    switch link {
    case .call(let kind):
      start(kind, store: store)
    case .intercept:
      start(.intercept, store: store)
    case .referral(let code):
      store.applyReferral(code: code)
    case .tab(let name):
      if let tab = MainTab(rawValue: name) { selectedTab = tab }
    }
  }
}

enum MainTab: String, CaseIterable, Identifiable {
  case today, calls, league, me

  var id: String { rawValue }

  var title: LocalizedStringResource {
    switch self {
    case .today: "Today"
    case .calls: "Calls"
    case .league: "League"
    case .me: "Me"
    }
  }

  var symbol: String {
    switch self {
    case .today: "house.fill"
    case .calls: "phone.fill"
    case .league: "trophy.fill"
    case .me: "person.fill"
    }
  }
}
