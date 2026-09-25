import Foundation

/// Fish Audio: instant voice cloning (`POST /model`) and text-to-speech (`POST /v1/tts`).
struct FishAudioService {
  enum FishError: LocalizedError {
    case missingKey
    case badResponse(Int, String)
    case noModelID

    var errorDescription: String? {
      switch self {
      case .missingKey: "Fish Audio key is missing from Secrets.local.plist."
      case .badResponse(let code, let body): "Fish Audio error \(code): \(body.prefix(200))"
      case .noModelID: "Fish Audio did not return a voice ID."
      }
    }
  }

  private let base = URL(string: "https://api.fish.audio")!
  private let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 90
    return URLSession(configuration: config)
  }()

  /// Uploads a voice sample and returns the reference id of the trained clone.
  func cloneVoice(sampleURL: URL, title: String, transcript: String?) async throws -> String {
    guard Secrets.hasVoiceKeys else { throw FishError.missingKey }
    let boundary = "stick-\(UUID().uuidString)"
    var request = URLRequest(url: base.appending(path: "model"))
    request.httpMethod = "POST"
    request.setValue("Bearer \(Secrets.fishAudioKey)", forHTTPHeaderField: "Authorization")
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()
    func field(_ name: String, _ value: String) {
      body.append("--\(boundary)\r\n".data(using: .utf8)!)
      body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
      body.append("\(value)\r\n".data(using: .utf8)!)
    }
    field("visibility", "private")
    field("type", "tts")
    field("title", title)
    field("train_mode", "fast")
    if let transcript, !transcript.isEmpty { field("texts", transcript) }

    let audio = try Data(contentsOf: sampleURL)
    let ext = sampleURL.pathExtension.isEmpty ? "wav" : sampleURL.pathExtension
    let mime = ext == "m4a" ? "audio/m4a" : "audio/wav"
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"voices\"; filename=\"sample.\(ext)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
    body.append(audio)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body

    let (data, response) = try await session.data(for: request)
    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(code) else {
      throw FishError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
    }
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let id = json?["_id"] as? String else { throw FishError.noModelID }
    return id
  }

  /// Deletes the voice model at Fish Audio (`DELETE /model/{id}`). A model that no longer exists counts as deleted.
  func deleteVoice(id: String) async throws {
    guard Secrets.hasVoiceKeys else { throw FishError.missingKey }
    var request = URLRequest(url: base.appending(path: "model").appending(path: id))
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(Secrets.fishAudioKey)", forHTTPHeaderField: "Authorization")
    let (data, response) = try await session.data(for: request)
    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(code) || code == 404 else {
      throw FishError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
    }
  }

  /// Synthesizes `text` with the cloned voice. Returns MP3 bytes.
  func synthesize(_ text: String, referenceID: String) async throws -> Data {
    guard Secrets.hasVoiceKeys else { throw FishError.missingKey }
    var request = URLRequest(url: base.appending(path: "v1/tts"))
    request.httpMethod = "POST"
    request.setValue("Bearer \(Secrets.fishAudioKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(Secrets.fishAudioModel, forHTTPHeaderField: "model")
    let payload: [String: Any] = [
      "text": text,
      "reference_id": referenceID,
      "format": "mp3",
      "mp3_bitrate": 128,
      "latency": "balanced",
      "temperature": 0.7,
      "top_p": 0.7
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    let (data, response) = try await session.data(for: request)
    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(code) else {
      throw FishError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
    }
    return data
  }
}
