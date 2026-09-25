import Foundation

struct ChatMessage: Codable, Hashable {
  enum Role: String, Codable { case system, user, assistant }
  var role: Role
  var content: String
}

/// OpenRouter chat completions with the free models chosen by the user.
/// Disabled unless the user explicitly allowed sending call text to the AI provider: every helper then
/// falls back to its local, scripted behaviour.
struct OpenRouterService {
  var enabled = true

  var isAvailable: Bool { enabled && Secrets.hasLLMKeys }

  enum RouterError: LocalizedError {
    case missingKey
    case badResponse(Int, String)
    case empty

    var errorDescription: String? {
      switch self {
      case .missingKey: "OpenRouter key is missing from Secrets.local.plist."
      case .badResponse(let code, let body): "OpenRouter error \(code): \(body.prefix(200))"
      case .empty: "OpenRouter returned an empty reply."
      }
    }
  }

  private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
  private let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 40
    return URLSession(configuration: config)
  }()

  func complete(_ messages: [ChatMessage], maxTokens: Int = 300, temperature: Double = 0.85) async throws -> String {
    guard isAvailable else { throw RouterError.missingKey }
    do {
      return try await complete(messages, model: Secrets.openRouterModel, maxTokens: maxTokens, temperature: temperature)
    } catch {
      return try await complete(messages, model: Secrets.openRouterFallbackModel, maxTokens: maxTokens, temperature: temperature)
    }
  }

  private func complete(_ messages: [ChatMessage], model: String, maxTokens: Int, temperature: Double) async throws -> String {
    var request = URLRequest(url: endpoint)
    request.httpMethod = "POST"
    request.setValue("Bearer \(Secrets.openRouterKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(AppLinks.website, forHTTPHeaderField: "HTTP-Referer")
    request.setValue("Stick", forHTTPHeaderField: "X-Title")
    let payload: [String: Any] = [
      "model": model,
      "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
      "max_tokens": maxTokens,
      "temperature": temperature,
      "reasoning": ["enabled": false]
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    let (data, response) = try await session.data(for: request)
    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(code) else {
      throw RouterError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
    }
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let choices = json?["choices"] as? [[String: Any]]
    let message = choices?.first?["message"] as? [String: Any]
    guard let content = message?["content"] as? String, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw RouterError.empty
    }
    return content.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Quick reachability check before a call (tiny completion, short timeout).
  func ping() async -> Bool {
    let messages = [ChatMessage(role: .user, content: "Reply with the single word OK.")]
    let result = await withTaskGroup(of: Bool.self) { group -> Bool in
      group.addTask { (try? await self.complete(messages, maxTokens: 5, temperature: 0)) != nil }
      group.addTask { try? await Task.sleep(for: .seconds(12)); return false }
      let first = await group.next() ?? false
      group.cancelAll()
      return first
    }
    return result
  }

  struct ParsedGoal {
    var goal: String?
    var done: Bool
  }

  /// Turns what the user said into one clean goal (fixes speech-recognition slips, imperative, ≤ 8 words).
  /// `done` is true when the user said they have no more goals.
  func normalizeGoal(_ heard: String, existing: [String], language: AppLanguage) async -> ParsedGoal {
    let text = heard.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return ParsedGoal(goal: nil, done: false) }
    let lower = text.lowercased()
    let stopWords = language == .french
      ? ["c'est tout", "c'est bon", "pas d'autre", "rien d'autre", "non merci", "ça suffit", "juste ça", "c'est déjà bien"]
      : ["that's all", "that's it", "nothing else", "no more", "that is all", "just that", "i'm good"]
    let saysDone = stopWords.contains { lower.contains($0) }
    let instruction = language == .french
      ? "Tu reçois la transcription vocale (parfois imparfaite) d'une personne qui donne UN objectif pour aujourd'hui. Réécris-le en français, à l'infinitif, concret, 8 mots maximum, en corrigeant les erreurs de reconnaissance vocale. Si la phrase ne contient aucun objectif (blabla, question, refus, « je sais pas »), goal = null. Si la personne dit qu'elle n'a pas d'autre objectif, done = true. Réponds UNIQUEMENT avec {\"goal\": string|null, \"done\": bool}. Objectifs déjà notés : \(existing.joined(separator: " | "))"
      : "You get the (sometimes imperfect) voice transcript of a person giving ONE goal for today. Rewrite it in English as a concrete imperative phrase, 8 words max, fixing speech-recognition slips. If the sentence contains no goal (chit-chat, a question, a refusal, \"I don't know\"), goal = null. If the person says they have no more goals, done = true. Reply ONLY with {\"goal\": string|null, \"done\": bool}. Goals already noted: \(existing.joined(separator: " | "))"
    let messages = [
      ChatMessage(role: .system, content: instruction),
      ChatMessage(role: .user, content: text)
    ]
    if let reply = try? await complete(messages, maxTokens: 80, temperature: 0),
       let json = Self.json(in: reply) {
      let goal = (json["goal"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
      let done = (json["done"] as? Bool) ?? saysDone
      if let goal, !goal.isEmpty, goal.lowercased() != "null", goal.count <= 80 {
        return ParsedGoal(goal: Self.capitalized(goal), done: done)
      }
      return ParsedGoal(goal: nil, done: done)
    }
    // Offline: keep the raw sentence, trimmed, unless it's a stop phrase.
    if saysDone { return ParsedGoal(goal: nil, done: true) }
    let words = text.split(separator: " ").prefix(10).joined(separator: " ")
    return ParsedGoal(goal: Self.capitalized(words), done: false)
  }

  /// Yes / no classification of a spoken answer. nil when unclear.
  func classifyYesNo(_ heard: String, question: String, language: AppLanguage) async -> Bool? {
    let lower = heard.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    guard !lower.isEmpty else { return nil }
    let yesWords = language == .french ? ["oui", "ouais", "c'est fait", "je ferme", "ok", "d'accord", "yes", "terminé", "fini", "je l'ai fait"] : ["yes", "yeah", "yep", "done", "did it", "closing", "close it", "i'm closing", "finished", "sure", "ok"]
    let noWords = language == .french ? ["non", "pas fait", "pas encore", "je ferme pas", "nan", "je continue", "pas eu le temps", "rien fait"] : ["no", "nope", "not done", "didn't", "did not", "not yet", "not closing", "no way", "keep"]
    if lower.count <= 12 {
      if yesWords.contains(where: { lower.hasPrefix($0) }) { return true }
      if noWords.contains(where: { lower.hasPrefix($0) }) { return false }
    }
    let instruction = language == .french
      ? "Question : \(question) Voici la réponse vocale de la personne. Réponds UNIQUEMENT avec {\"answer\": \"yes\"|\"no\"|\"unclear\"}."
      : "Question: \(question) Here is the person's spoken answer. Reply ONLY with {\"answer\": \"yes\"|\"no\"|\"unclear\"}."
    let messages = [ChatMessage(role: .system, content: instruction), ChatMessage(role: .user, content: heard)]
    if let reply = try? await complete(messages, maxTokens: 20, temperature: 0),
       let json = Self.json(in: reply), let answer = json["answer"] as? String {
      switch answer.lowercased() {
      case "yes": return true
      case "no": return false
      default: return nil
      }
    }
    if yesWords.contains(where: { lower.contains($0) }) && !noWords.contains(where: { lower.contains($0) }) { return true }
    if noWords.contains(where: { lower.contains($0) }) { return false }
    return nil
  }

  private static func json(in reply: String) -> [String: Any]? {
    guard let start = reply.firstIndex(of: "{"), let end = reply.lastIndex(of: "}"), start < end,
          let data = String(reply[start...end]).data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  }

  private static func capitalized(_ text: String) -> String {
    guard let first = text.first else { return text }
    return first.uppercased() + text.dropFirst()
  }
}
