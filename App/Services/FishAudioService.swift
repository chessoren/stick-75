import Foundation

/// Fish Audio: instant voice cloning (`POST /model`) and text-to-speech (`POST /v1/tts`), through Stick's relay
/// so the Fish Audio key never ships in the app.
struct FishAudioService {
  enum FishError: LocalizedError {
    case badResponse(Int, String)
    case noModelID

    /// Shown to the user. The status code and body stay in the error for debugging.
    var errorDescription: String? {
      switch self {
      case .badResponse: String(localized: "Stick couldn't reach its voice service. Check your connection and try again.")
      case .noModelID: String(localized: "Stick couldn't build your voice. Try again, somewhere quiet.")
      }
    }
  }

  /// Fish Audio speech model used for every line.
  private static let model = "s2.1-pro-free"

  private let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 90
    return URLSession(configuration: config)
  }()

  /// Uploads a voice sample and returns the reference id of the trained clone.
  func cloneVoice(sampleURL: URL, title: String, transcript: String?) async throws -> String {
    let boundary = "stick-\(UUID().uuidString)"
    var request = Relay.request(.fish, path: "model", method: "POST")
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

  /// Deletes the voice model at Fish Audio (`DELETE /model/{id}`). The relay answers 204 for a model that no
  /// longer exists, so any other status, including 404, means the clone may still be there.
  func deleteVoice(id: String) async throws {
    let request = Relay.request(.fish, path: "model/\(id)", method: "DELETE")
    let (data, response) = try await session.data(for: request)
    let code = (response as? HTTPURLResponse)?.statusCode ?? 0
    guard (200..<300).contains(code) else {
      throw FishError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
    }
  }

  /// Synthesizes `text` with the cloned voice. Returns MP3 bytes.
  func synthesize(_ text: String, referenceID: String) async throws -> Data {
    var request = Relay.request(.fish, path: "v1/tts", method: "POST")
    // A call can't wait long for a line: past this, the system voice takes over.
    request.timeoutInterval = 15
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(Self.model, forHTTPHeaderField: "model")
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
