import SwiftUI

// MARK: - Colors

extension Color {
  static let brandOrange = Color(red: 0.949, green: 0.404, blue: 0.227)      // #F2673A
  static let brandOrangeDeep = Color(red: 0.886, green: 0.306, blue: 0.106)  // #E24E1B
  static let brandPeach = Color(red: 1.0, green: 0.690, blue: 0.478)         // #FFB07A
  static let brandCream = Color(red: 1.0, green: 0.957, blue: 0.925)         // #FFF4EC
  static let brandSand = Color(red: 0.98, green: 0.90, blue: 0.84)
  static let ink = Color(red: 0.067, green: 0.067, blue: 0.067)              // #111111
  static let inkSecondary = Color(red: 0.353, green: 0.353, blue: 0.353)     // #5A5A5A
  static let stickSuccess = Color(red: 0.184, green: 0.702, blue: 0.478)     // #2FB37A
  static let stickDanger = Color(red: 0.898, green: 0.282, blue: 0.302)      // #E5484D
  static let glassMilk = Color.white.opacity(0.62)
}

// MARK: - Typography (Inter)

enum StickFont {
  enum Weight {
    case regular, medium, semibold, bold

    var name: String {
      switch self {
      case .regular: "Inter-Regular"
      case .medium: "Inter-Medium"
      case .semibold: "Inter-SemiBold"
      case .bold: "Inter-Bold"
      }
    }
  }

  static func font(_ size: CGFloat, _ weight: Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
    .custom(weight.name, size: size, relativeTo: style)
  }

  /// 56-64 pt hero figures.
  static let hero = font(60, .semibold, relativeTo: .largeTitle)
  static let heroSmall = font(44, .semibold, relativeTo: .largeTitle)
  static let largeTitle = font(34, .semibold, relativeTo: .largeTitle)
  static let title = font(28, .semibold, relativeTo: .title)
  static let title2 = font(22, .semibold, relativeTo: .title2)
  static let title3 = font(19, .semibold, relativeTo: .title3)
  static let headline = font(17, .semibold, relativeTo: .headline)
  static let body = font(17, .regular, relativeTo: .body)
  static let bodyMedium = font(17, .medium, relativeTo: .body)
  static let callout = font(15, .regular, relativeTo: .callout)
  static let calloutMedium = font(15, .medium, relativeTo: .callout)
  static let footnote = font(13, .regular, relativeTo: .footnote)
  static let footnoteMedium = font(13, .medium, relativeTo: .footnote)
  static let caption = font(12, .medium, relativeTo: .caption)
  static let caption2 = font(11, .medium, relativeTo: .caption2)
}

// MARK: - Metrics

enum StickMetrics {
  static let cardRadius: CGFloat = 24
  static let heroRadius: CGFloat = 28
  static let screenMargin: CGFloat = 20
  static let cardGap: CGFloat = 12
  static let cardPadding: CGFloat = 18
}

// MARK: - Modifiers

extension View {
  /// Titles use tight tracking like the reference design.
  func stickTitleTracking() -> some View {
    tracking(-0.5)
  }

  /// Soft orange shadow used under every glass card.
  func stickShadow(_ opacity: Double = 0.18) -> some View {
    shadow(color: Color.brandOrangeDeep.opacity(opacity), radius: 22, x: 0, y: 12)
  }
}
