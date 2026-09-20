import Foundation

struct ChatMessage: Codable, Hashable {
  enum Role: String, Codable { case system, user, assistant }
  var role: Role
  var content: String
}

/// OpenRouter chat completions with the free models chosen by the user.
struct OpenRouterService {
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
    guard Secrets.hasLLMKeys else { throw RouterError.missingKey }
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
    request.setValue("https://stick.app", forHTTPHeaderField: "HTTP-Referer")
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

  /// Pulls 1–3 goals out of a wake-up call transcript. Returns [] when nothing usable was said.
  func extractGoals(from transcript: [CallTurn], language: AppLanguage) async -> [String] {
    let text = transcript.map { "\($0.speaker == .stick ? "Stick" : "User"): \($0.text)" }.joined(separator: "\n")
    let instruction = language == .french
      ? "Extrais les objectifs concrets que l'utilisateur s'est fixés pour AUJOURD'HUI dans cette conversation. Réponds UNIQUEMENT avec un JSON de la forme {\"goals\":[\"...\"]} (1 à 3 objectifs, phrases courtes à l'infinitif, en français). Si aucun objectif, {\"goals\":[]}."
      : "Extract the concrete goals the user committed to for TODAY in this conversation. Reply ONLY with JSON shaped like {\"goals\":[\"...\"]} (1 to 3 goals, short imperative phrases, in English). If none, {\"goals\":[]}."
    let messages = [
      ChatMessage(role: .system, content: instruction),
      ChatMessage(role: .user, content: text)
    ]
    guard let reply = try? await complete(messages, maxTokens: 150, temperature: 0.1) else { return [] }
    guard let start = reply.firstIndex(of: "{"), let end = reply.lastIndex(of: "}"), start < end else { return [] }
    let jsonText = String(reply[start...end])
    guard let data = jsonText.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let goals = json["goals"] as? [String] else { return [] }
    return Array(goals.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.prefix(3))
  }
}
