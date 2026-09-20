import SwiftUI

/// Milky glass card used everywhere. One idea per card.
struct StickCardModifier: ViewModifier {
  var radius: CGFloat = StickMetrics.cardRadius
  var padding: CGFloat = StickMetrics.cardPadding
  var interactive = false

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(Color.white.opacity(0.58))
      }
      .glassEffect(interactive ? .regular.interactive() : .regular, in: .rect(cornerRadius: radius))
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(Color.white.opacity(0.45), lineWidth: 0.5)
      }
      .stickShadow()
  }
}

/// Orange tinted glass card with white text (the "hero" card).
struct StickHeroCardModifier: ViewModifier {
  var radius: CGFloat = StickMetrics.heroRadius
  var padding: CGFloat = 20

  func body(content: Content) -> some View {
    content
      .padding(padding)
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(.white)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(
            LinearGradient(
              colors: [Color.brandOrange, Color.brandOrangeDeep],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
      }
      .glassEffect(.regular.tint(.brandOrange.opacity(0.85)), in: .rect(cornerRadius: radius))
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5)
      }
      .stickShadow(0.32)
  }
}

/// Solid ink (black) card for the heaviest visual weight.
struct StickInkCardModifier: ViewModifier {
  var radius: CGFloat = StickMetrics.heroRadius

  func body(content: Content) -> some View {
    content
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(.white)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(Color.ink)
      }
      .shadow(color: .black.opacity(0.22), radius: 22, x: 0, y: 12)
  }
}

extension View {
  func stickCard(radius: CGFloat = StickMetrics.cardRadius, padding: CGFloat = StickMetrics.cardPadding, interactive: Bool = false) -> some View {
    modifier(StickCardModifier(radius: radius, padding: padding, interactive: interactive))
  }

  func stickHeroCard(radius: CGFloat = StickMetrics.heroRadius, padding: CGFloat = 20) -> some View {
    modifier(StickHeroCardModifier(radius: radius, padding: padding))
  }

  func stickInkCard(radius: CGFloat = StickMetrics.heroRadius) -> some View {
    modifier(StickInkCardModifier(radius: radius))
  }
}

/// Section header used on Home and other tabs.
struct StickSectionHeader<Trailing: View>: View {
  var title: LocalizedStringKey
  @ViewBuilder var trailing: Trailing

  init(_ title: LocalizedStringKey, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
    self.title = title
    self.trailing = trailing()
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(StickFont.title2)
        .stickTitleTracking()
        .foregroundStyle(Color.ink)
      Spacer()
      trailing
    }
    .padding(.horizontal, 4)
  }
}

/// Small round glass icon button (like the "⚡" on the hero card).
struct GlassIconButton: View {
  var systemImage: String
  var label: LocalizedStringKey
  var tint: Color = .brandOrange
  var size: CGFloat = 40
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: size * 0.42, weight: .semibold))
        .foregroundStyle(tint)
        .frame(width: size, height: size)
        .background(Color.white.opacity(0.85), in: Circle())
        .glassEffect(.regular.interactive(), in: .circle)
    }
    .buttonStyle(PressableButtonStyle())
    .accessibilityLabel(Text(label))
  }
}
