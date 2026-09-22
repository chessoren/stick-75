import SwiftUI
import WidgetKit

/// Same identity as the app: warm orange gradient, milky glass, Inter, hero figures.
enum WidgetTheme {
  static let orange = Color(red: 0.949, green: 0.404, blue: 0.227)
  static let orangeDeep = Color(red: 0.886, green: 0.306, blue: 0.106)
  static let peach = Color(red: 1.0, green: 0.690, blue: 0.478)
  static let cream = Color(red: 1.0, green: 0.957, blue: 0.925)
  static let sand = Color(red: 0.98, green: 0.90, blue: 0.84)
  static let ink = Color(red: 0.067, green: 0.067, blue: 0.067)
  static let inkSecondary = Color(red: 0.353, green: 0.353, blue: 0.353)
  static let success = Color(red: 0.184, green: 0.702, blue: 0.478)
  static let danger = Color(red: 0.898, green: 0.282, blue: 0.302)

  /// Full-bleed warm gradient with a soft highlight, like the app background.
  static var heroBackground: some View {
    ZStack {
      LinearGradient(
        colors: [orangeDeep, orange, Color(red: 1.0, green: 0.60, blue: 0.38)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      RadialGradient(
        colors: [Color.white.opacity(0.28), .clear],
        center: .topTrailing,
        startRadius: 0,
        endRadius: 220
      )
      RadialGradient(
        colors: [peach.opacity(0.55), .clear],
        center: .bottomLeading,
        startRadius: 0,
        endRadius: 200
      )
    }
  }

  static var creamBackground: some View {
    LinearGradient(colors: [sand, cream], startPoint: .top, endPoint: .bottom)
  }
}

enum WidgetFont {
  static func inter(_ size: CGFloat, _ weight: String = "Regular") -> Font {
    .custom("Inter-\(weight)", size: size)
  }
  static func hero(_ size: CGFloat) -> Font { inter(size, "SemiBold") }
  static let headline = inter(15, "SemiBold")
  static let body = inter(13, "Medium")
  static let caption = inter(11, "Medium")
  static let caption2 = inter(10, "Medium")
}

/// Milky glass pill / card used inside widgets and activities.
struct GlassPill: ViewModifier {
  var radius: CGFloat = 14
  var opacity: Double = 0.22

  func body(content: Content) -> some View {
    content
      .background(Color.white.opacity(opacity), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
      }
  }
}

extension View {
  func glassPill(radius: CGFloat = 14, opacity: Double = 0.22) -> some View {
    modifier(GlassPill(radius: radius, opacity: opacity))
  }
}

/// Avatar with the user's initial, white on orange or orange on white.
struct InitialAvatar: View {
  var name: String
  var size: CGFloat = 40
  var inverted = false

  var body: some View {
    Circle()
      .fill(inverted ? WidgetTheme.orange : Color.white)
      .frame(width: size, height: size)
      .overlay {
        Text(name.isEmpty ? "S" : String(name.prefix(1)).uppercased())
          .font(WidgetFont.hero(size * 0.46))
          .foregroundStyle(inverted ? Color.white : WidgetTheme.orange)
      }
      .shadow(color: WidgetTheme.orangeDeep.opacity(0.25), radius: 6, y: 3)
  }
}

/// Static waveform (activities can't animate continuously, so the shape itself carries the energy).
struct StaticWaveform: View {
  var color: Color = .white
  var bars = 18
  var height: CGFloat = 22
  var energetic = true

  private static let pattern: [Double] = [0.25, 0.55, 0.9, 0.6, 0.35, 0.8, 1.0, 0.5, 0.3, 0.7, 0.95, 0.45, 0.6, 0.85, 0.4, 0.3, 0.65, 0.5, 0.9, 0.35, 0.55, 0.75]

  var body: some View {
    HStack(alignment: .center, spacing: 3) {
      ForEach(0..<bars, id: \.self) { i in
        let amp = energetic ? Self.pattern[i % Self.pattern.count] : 0.18
        Capsule()
          .fill(color)
          .frame(width: 3, height: max(4, height * amp))
      }
    }
    .frame(height: height)
    .accessibilityHidden(true)
  }
}

/// Small progress ring for widgets.
struct MiniRing: View {
  var progress: Double
  var lineWidth: CGFloat = 5
  var tint: Color = .white
  var track: Color = Color.white.opacity(0.3)

  var body: some View {
    ZStack {
      Circle().stroke(track, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
      Circle()
        .trim(from: 0, to: max(0.02, min(1, progress)))
        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
  }
}

struct SnapshotEntry: TimelineEntry {
  var date: Date
  var snapshot: SharedSnapshot
}

struct SnapshotProvider: TimelineProvider {
  func placeholder(in context: Context) -> SnapshotEntry {
    SnapshotEntry(date: .now, snapshot: .placeholder)
  }

  func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
    completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .placeholder : SharedSnapshot.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
    let entry = SnapshotEntry(date: .now, snapshot: SharedSnapshot.load())
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
    completion(Timeline(entries: [entry], policy: .after(next)))
  }
}

extension SharedSnapshot {
  var goalProgress: Double {
    guard !goals.isEmpty else { return 0 }
    return Double(goals.filter(\.isDone).count) / Double(goals.count)
  }

  var callTitle: LocalizedStringKey {
    switch nextCallKind {
    case .wake: "Wake-up call"
    case .debrief: "Evening debrief"
    case .intercept: "Interception"
    case .recovery: "Recovery call"
    case .push: "Push"
    case .aha, .none: "Next call"
    }
  }

  var callSymbol: String {
    switch nextCallKind {
    case .wake: "sunrise.fill"
    case .debrief: "moon.stars.fill"
    default: "phone.fill"
    }
  }
}
