import Foundation
import Supabase

/// Supabase backend: anonymous auth, weekly league, referral credits.
/// Inactive until SUPABASE_URL and SUPABASE_ANON_KEY are set in Secrets.local.plist.
/// Schema: see `supabase/schema.sql`.
actor SupabaseService {
  static let shared = SupabaseService()

  struct LeagueRow: Codable {
    var user_id: String
    var name: String
    var hours_recovered: Double
    var days_held: Int
    var day_number: Int
    var referral_code: String
    var updated_at: Date?
  }

  private var client: SupabaseClient?

  var isConfigured: Bool {
    !Secrets.supabaseURL.isEmpty && !Secrets.supabaseAnonKey.isEmpty
  }

  private func makeClient() -> SupabaseClient? {
    if let client { return client }
    guard isConfigured, let url = URL(string: Secrets.supabaseURL) else { return nil }
    let client = SupabaseClient(supabaseURL: url, supabaseKey: Secrets.supabaseAnonKey)
    self.client = client
    return client
  }

  /// Signs in anonymously once and returns the user id.
  private func session() async throws -> String {
    guard let client = makeClient() else { throw ServiceError.notConfigured }
    if let session = try? await client.auth.session { return session.user.id.uuidString }
    let session = try await client.auth.signInAnonymously()
    return session.user.id.uuidString
  }

  func pushScore(name: String, hours: Double, daysHeld: Int, dayNumber: Int, referralCode: String) async {
    guard let client = makeClient(), let userID = try? await session() else { return }
    let row = LeagueRow(user_id: userID, name: name, hours_recovered: hours, days_held: daysHeld, day_number: dayNumber, referral_code: referralCode, updated_at: .now)
    _ = try? await client.from("league").upsert(row, onConflict: "user_id").execute()
  }

  func fetchLeague() async -> [LeaderboardEntry] {
    guard let client = makeClient(), let userID = try? await session() else { return [] }
    guard let rows: [LeagueRow] = try? await client.from("league")
      .select()
      .order("hours_recovered", ascending: false)
      .limit(30)
      .execute()
      .value else { return [] }
    return rows.enumerated().map { index, row in
      LeaderboardEntry(
        name: row.name,
        initials: String(row.name.prefix(1)).uppercased(),
        hoursRecovered: row.hours_recovered,
        daysHeld: row.days_held,
        isMe: row.user_id == userID,
        hue: Double(index % 12) / 12
      )
    }
  }

  /// Records that this install came from a friend's code. The Edge Function credits both sides.
  func registerReferral(code: String) async {
    guard let client = makeClient(), let userID = try? await session() else { return }
    _ = try? await client.from("referrals").insert(["code": code, "invited_user_id": userID]).execute()
  }

  enum ServiceError: Error { case notConfigured }
}
