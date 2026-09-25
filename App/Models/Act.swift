import SwiftUI

/// The 75 days are five acts of 15 days. Each act changes Stick's tone, the calls, and what the app reveals.
enum Act: Int, CaseIterable, Codable, Identifiable {
  case silence = 0, comeback, identity, trial, flight

  var id: Int { rawValue }

  static let length = 15
  static let totalDays = 75

  static func act(forDay day: Int) -> Act {
    let index = max(0, min(Act.allCases.count - 1, (day - 1) / length))
    return Act(rawValue: index) ?? .silence
  }

  var dayRange: ClosedRange<Int> {
    let start = rawValue * Act.length + 1
    return start...(start + Act.length - 1)
  }

  var numeral: String {
    ["I", "II", "III", "IV", "V"][rawValue]
  }

  var next: Act? { Act(rawValue: rawValue + 1) }

  var name: LocalizedStringResource {
    switch self {
    case .silence: "The Silence"
    case .comeback: "The Comeback"
    case .identity: "The Identity"
    case .trial: "The Trial"
    case .flight: "The Flight"
    }
  }

  var focus: LocalizedStringResource {
    switch self {
    case .silence: "Zero tolerance. Maximum friction. Three calls a day."
    case .comeback: "Replace, don't just block. One new habit chosen every morning."
    case .identity: "\"I am someone who…\" Shorter calls, harder questions. Voice badges."
    case .trial: "The shield comes off: 15 minutes a day, on your honor. Stick still calls every time you open."
    case .flight: "Scaffolding comes off. One call a day. You plan life after day 75."
    }
  }

  /// How Stick speaks during this act.
  var toneTitle: LocalizedStringResource {
    switch self {
    case .silence: "Drill sergeant"
    case .comeback: "Sergeant who builds"
    case .identity: "Fewer orders, harder questions"
    case .trial: "The tester"
    case .flight: "The mentor"
    }
  }

  var toneDescription: LocalizedStringResource {
    switch self {
    case .silence: "Short orders. No open questions. No slack."
    case .comeback: "Still dry, but now Stick builds: a replacement habit every morning, recovered time counted every night."
    case .identity: "Stick stops ordering and starts asking. \"Who are you when nobody's watching?\""
    case .trial: "Stick doubts out loud and checks. The shield is off; you hold the 15-minute window yourself."
    case .flight: "Stick talks less and listens. One call a day. It prepares what comes after."
    }
  }

  var symbol: String {
    switch self {
    case .silence: "moon.fill"
    case .comeback: "arrow.uturn.forward"
    case .identity: "person.fill.checkmark"
    case .trial: "timer"
    case .flight: "bird.fill"
    }
  }

  var callsPerDay: Int {
    switch self {
    case .silence, .comeback: 3
    case .identity, .trial: 2
    case .flight: 1
    }
  }

  /// Whether the evening debrief alarm rings in this act (Act V keeps only the morning call).
  var hasDebriefCall: Bool { self != .flight }

  /// Minutes of intentional use allowed per day on blocked apps (on the honor system until Family Controls is granted).
  var allowedWindowMinutes: Int {
    switch self {
    case .trial: 15
    case .flight: 20
    default: 0
    }
  }

  /// What the ringtone says in your voice during this act.
  func ringtoneLine(language: AppLanguage) -> String {
    let fr = language == .french
    switch self {
    case .silence: return fr ? "C'est toi. Décroche." : "It's you. Pick up."
    case .comeback: return fr ? "C'est toi. On construit." : "It's you. We're building."
    case .identity: return fr ? "C'est toi. Tu sais quoi faire." : "It's you. You know what to do."
    case .trial: return fr ? "C'est toi. Prouve-le." : "It's you. Prove it."
    case .flight: return fr ? "C'est toi. On y est presque." : "It's you. Almost there."
    }
  }

  /// What Stick says, in your voice, when the act opens.
  func revealLine(name: String, identity: String, language: AppLanguage) -> String {
    let who = name.isEmpty ? "" : "\(name). "
    let fr = language == .french
    switch self {
    case .silence: return fr ? "\(who)Acte un. Le Silence. Trois appels par jour, tolérance zéro. On ne discute pas." : "\(who)Act one. The Silence. Three calls a day, zero tolerance. No debate."
    case .comeback: return fr ? "\(who)Acte deux. Le Silence est derrière toi. Maintenant on remplace : chaque matin, une habitude. Chaque soir, je compte le temps que tu as repris." : "\(who)Act two. The Silence is behind you. Now we replace: every morning, one habit. Every night, I count the time you took back."
    case .identity: return fr ? "\(who)Acte trois. Fini les ordres. Maintenant je pose des questions. Tu es quelqu'un qui \(identity). Prouve-le à toi-même." : "\(who)Act three. No more orders. Now I ask questions. You are someone who \(identity). Prove it to yourself."
    case .trial: return fr ? "\(who)Acte quatre. Le bouclier se lève. Quinze minutes par jour, sur l'honneur. Je vérifie chaque soir." : "\(who)Act four. The shield comes off. Fifteen minutes a day, on your honor. I check every night."
    case .flight: return fr ? "\(who)Acte cinq. Un seul appel par jour. Tu n'as plus besoin de moi. Prépare l'après." : "\(who)Act five. One call a day. You don't need me anymore. Prepare what comes next."
    }
  }

  /// Voice badge recorded in your voice at the start of acts III, IV and V.
  func voiceBadgeLine(identity: String, language: AppLanguage) -> String? {
    let fr = language == .french
    switch self {
    case .identity: return fr ? "Acte trois. Je suis quelqu'un qui \(identity)." : "Act three. I am someone who \(identity)."
    case .trial: return fr ? "Acte quatre. La porte est ouverte et je ne la prends pas." : "Act four. The door is open and I'm not taking it."
    case .flight: return fr ? "Acte cinq. Je n'ai plus besoin qu'on m'appelle." : "Act five. I no longer need to be called."
    default: return nil
    }
  }

  /// Features that open with this act.
  var unlocks: [Feature] {
    Feature.allCases.filter { $0.unlockAct == self }
  }
}

/// Everything that is revealed over the 75 days. Visible from day 1, usable from its act.
enum Feature: String, CaseIterable, Identifiable {
  case calls, goals, jokers, interception
  case lifeCounter, habit
  case voiceBadges
  case window, trials
  case postPlan, vault

  var id: String { rawValue }

  var unlockAct: Act {
    switch self {
    case .calls, .goals, .jokers, .interception: .silence
    case .lifeCounter, .habit: .comeback
    case .voiceBadges: .identity
    case .window, .trials: .trial
    case .postPlan, .vault: .flight
    }
  }

  var unlockDay: Int { unlockAct.dayRange.lowerBound }

  var title: LocalizedStringResource {
    switch self {
    case .calls: "Calls in your voice"
    case .goals: "Daily goals"
    case .jokers: "3 jokers"
    case .interception: "Interception"
    case .lifeCounter: "Life counter"
    case .habit: "Habit of the day"
    case .voiceBadges: "Voice badges"
    case .window: "15-minute window"
    case .trials: "Weekly trials"
    case .postPlan: "Plan after 75"
    case .vault: "The Vault opens"
    }
  }

  var detail: LocalizedStringResource {
    switch self {
    case .calls: "Morning, evening, and the second you open a blocked app."
    case .goals: "1 to 3 real goals, pushed to your widgets."
    case .jokers: "A slip costs one. Never miss twice."
    case .interception: "Your voice rings when TikTok opens."
    case .lifeCounter: "Hours won back, converted into books, runs, nights."
    case .habit: "Every morning, Stick makes you pick what replaces the scroll."
    case .voiceBadges: "Stick records a sentence in your voice at each act."
    case .window: "The shield comes off 15 minutes a day. You hold it."
    case .trials: "A phone-free evening, a disconnected Sunday. On your honor."
    case .postPlan: "Stick makes you write what stays after day 75."
    case .vault: "Your message from day 1, played on day 75."
    }
  }

  var symbol: String {
    switch self {
    case .calls: "phone.fill"
    case .goals: "checklist"
    case .jokers: "heart.fill"
    case .interception: "hand.raised.fill"
    case .lifeCounter: "clock.arrow.circlepath"
    case .habit: "leaf.fill"
    case .voiceBadges: "waveform.badge.mic"
    case .window: "timer"
    case .trials: "flame.fill"
    case .postPlan: "map.fill"
    case .vault: "lock.open.fill"
    }
  }
}

/// Weekly trials of Act IV, on the honor system.
enum Trial: String, CaseIterable, Codable, Identifiable {
  case phoneFreeEvening, disconnectedSunday, twentyFourHours

  var id: String { rawValue }

  var title: LocalizedStringResource {
    switch self {
    case .phoneFreeEvening: "Phone-free evening"
    case .disconnectedSunday: "Disconnected Sunday"
    case .twentyFourHours: "24 hours without the apps"
    }
  }

  var detail: LocalizedStringResource {
    switch self {
    case .phoneFreeEvening: "From dinner to sleep, the phone stays in another room."
    case .disconnectedSunday: "No blocked app from waking up to bed. Not even the window."
    case .twentyFourHours: "A full day, window included, without opening one of your apps."
    }
  }

  var symbol: String {
    switch self {
    case .phoneFreeEvening: "moon.zzz.fill"
    case .disconnectedSunday: "sun.max.fill"
    case .twentyFourHours: "24.circle.fill"
    }
  }
}
