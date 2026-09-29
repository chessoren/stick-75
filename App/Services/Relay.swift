import Foundation

/// Stick's server relay, a Supabase Edge Function (`supabase/functions/relay`). It holds the Fish Audio and
/// OpenRouter keys, so no private key ships in the app. The app only carries the project's public anon key,
/// which the function requires, and the relay forwards nothing but the few calls Stick makes.
enum Relay {
  static let baseURL = URL(string: "https://yapevehbecccmhfpbfjk.supabase.co/functions/v1/relay")!

  /// Public by design (Supabase "anon" key): it only lets a client call the relay.
  private static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlhcGV2ZWhiZWNjY21oZnBiZmprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2ODcyMjQsImV4cCI6MjEwNjI2MzIyNH0.4ntqdJNBc_KN7D69mvT_0lHmVoTK44sEZaPYTEJO_Ns"

  enum Provider: String {
    case fish
    case openRouter = "openrouter"
  }

  /// A request to `path` at `provider`, already authorized for the relay.
  static func request(_ provider: Provider, path: String, method: String) -> URLRequest {
    var request = URLRequest(url: baseURL.appending(path: provider.rawValue).appending(path: path))
    request.httpMethod = method
    request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    request.setValue(anonKey, forHTTPHeaderField: "apikey")
    return request
  }
}
