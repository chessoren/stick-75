import SwiftUI

/// Press feedback shared by every tappable thing: scale 0.97 + soft haptic.
struct PressableButtonStyle: ButtonStyle {
  var scale: CGFloat = 0.97

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? scale : 1)
      .animation(.snappy(duration: 0.25), value: configuration.isPressed)
      .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: configuration.isPressed) { _, new in new }
  }
}

/// The black pill ("Done"). The single heavy element on any screen.
struct PrimaryPillButtonStyle: ButtonStyle {
  var fill: Color = .ink
  var foreground: Color = .white
  var fullWidth = true

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StickFont.headline)
      .foregroundStyle(foreground)
      .padding(.vertical, 17)
      .padding(.horizontal, 28)
      .frame(maxWidth: fullWidth ? .infinity : nil)
      .background(fill, in: Capsule())
      .contentShape(Capsule())
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .opacity(configuration.isPressed ? 0.92 : 1)
      .animation(.snappy(duration: 0.25), value: configuration.isPressed)
      .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: configuration.isPressed) { _, new in new }
  }
}

/// The soft glass pill ("Dismiss").
struct SecondaryPillButtonStyle: ButtonStyle {
  var fullWidth = true

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StickFont.headline)
      .foregroundStyle(Color.ink.opacity(0.8))
      .padding(.vertical, 17)
      .padding(.horizontal, 28)
      .frame(maxWidth: fullWidth ? .infinity : nil)
      .background(Color.white.opacity(0.5), in: Capsule())
      .glassEffect(.regular.interactive(), in: .capsule)
      .contentShape(Capsule())
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.snappy(duration: 0.25), value: configuration.isPressed)
      .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: configuration.isPressed) { _, new in new }
  }
}

/// Orange pill for CTAs on cream backgrounds.
struct OrangePillButtonStyle: ButtonStyle {
  var fullWidth = true

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StickFont.headline)
      .foregroundStyle(.white)
      .padding(.vertical, 17)
      .padding(.horizontal, 28)
      .frame(maxWidth: fullWidth ? .infinity : nil)
      .background(
        LinearGradient(colors: [.brandOrange, .brandOrangeDeep], startPoint: .leading, endPoint: .trailing),
        in: Capsule()
      )
      .glassEffect(.regular.tint(.brandOrange).interactive(), in: .capsule)
      .contentShape(Capsule())
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.snappy(duration: 0.25), value: configuration.isPressed)
      .sensoryFeedback(.impact(weight: .medium, intensity: 0.7), trigger: configuration.isPressed) { _, new in new }
  }
}

/// Selectable option chip used by the onboarding quiz.
struct ChoiceChipStyle: ButtonStyle {
  var isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(StickFont.bodyMedium)
      .foregroundStyle(isSelected ? Color.white : Color.ink)
      .padding(.vertical, 16)
      .padding(.horizontal, 18)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(isSelected ? Color.ink : Color.white.opacity(0.6))
      }
      .glassEffect(isSelected ? .regular.tint(.ink) : .regular.interactive(), in: .rect(cornerRadius: 20))
      .overlay {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .strokeBorder(Color.white.opacity(isSelected ? 0.1 : 0.5), lineWidth: 0.5)
      }
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.snappy(duration: 0.25), value: configuration.isPressed)
      .animation(.smooth(duration: 0.3), value: isSelected)
      .sensoryFeedback(.selection, trigger: isSelected)
  }
}
