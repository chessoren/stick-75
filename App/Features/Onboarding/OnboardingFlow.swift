import SwiftUI

/// Container: background, progress, back button, and the animated step.
struct OnboardingFlow: View {
  @Environment(StickStore.self) private var store
  @State private var model: OnboardingModel?

  var body: some View {
    Group {
      if let model {
        OnboardingContainer()
          .environment(model)
      } else {
        StickBackground()
      }
    }
    .onAppear {
      if model == nil { model = OnboardingModel(store: store) }
    }
  }
}

struct OnboardingContainer: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    ZStack {
      if model.step.usesCreamBackground {
        StickCreamBackground()
          .transition(.opacity)
      } else {
        StickBackground()
          .transition(.opacity)
      }

      VStack(spacing: 0) {
        topBar
          .padding(.horizontal, StickMetrics.screenMargin)
          .padding(.top, 8)

        ZStack {
          stepView
            .id(model.step)
            .transition(.asymmetric(
              insertion: .move(edge: model.direction).combined(with: .opacity),
              removal: .move(edge: model.direction == .trailing ? .leading : .trailing).combined(with: .opacity)
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .animation(.smooth(duration: 0.45), value: model.step)
    .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: model.step)
  }

  private var topBar: some View {
    HStack(spacing: 12) {
      if model.step.rawValue > 0, model.step != .done, model.step != .paywall, model.step != .voiceProcessing {
        Button {
          model.back()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(Color.ink)
            .frame(width: 38, height: 38)
            .background(Color.white.opacity(0.7), in: Circle())
            .glassEffect(.regular.interactive(), in: .circle)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text("Back"))
      } else {
        Color.clear.frame(width: 38, height: 38)
      }

      if model.step.showsProgress {
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            Capsule().fill(Color.ink.opacity(0.1))
            Capsule()
              .fill(Color.brandOrange)
              .frame(width: max(12, geo.size.width * model.progress))
              .animation(.smooth(duration: 0.5), value: model.progress)
          }
        }
        .frame(height: 6)
        .accessibilityLabel(Text("Onboarding progress"))
        .accessibilityValue(Text(model.progress, format: .percent.precision(.fractionLength(0))))
      } else {
        Spacer()
      }

      Color.clear.frame(width: 38, height: 38)
    }
    .frame(height: 44)
  }

  @ViewBuilder
  private var stepView: some View {
    switch model.step {
    case .hook: HookScreen()
    case .pitch: PitchScreen()
    case .quizApps: QuizAppsScreen()
    case .quizHours: QuizHoursScreen()
    case .quizMoments: QuizMomentsScreen()
    case .quizFeelings: QuizFeelingsScreen()
    case .quizDreams: QuizDreamsScreen()
    case .quizTried: QuizTriedScreen()
    case .result: ResultScreen()
    case .journey: JourneyScreen()
    case .identity: IdentityScreen()
    case .name: NameScreen()
    case .voiceConsent: VoiceConsentScreen()
    case .voiceRecord: VoiceRecordScreen()
    case .voiceProcessing: VoiceProcessingScreen()
    case .aha: AhaScreen()
    case .contract: ContractScreen()
    case .paywall: PaywallStep()
    case .screenTime: ScreenTimeScreen()
    case .permissions: PermissionsScreen()
    case .schedule: ScheduleScreen()
    case .automation: AutomationScreen()
    case .vault: VaultRecordScreen()
    case .done: DoneScreen()
    }
  }
}

/// Standard page layout: title, subtitle, content, sticky CTA.
struct OnboardingPage<Content: View, Footer: View>: View {
  var title: LocalizedStringKey
  var subtitle: LocalizedStringKey?
  var light: Bool
  @ViewBuilder var content: Content
  @ViewBuilder var footer: Footer

  init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, light: Bool = true, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
    self.title = title
    self.subtitle = subtitle
    self.light = light
    self.content = content()
    self.footer = footer()
  }

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          VStack(alignment: .leading, spacing: 8) {
            Text(title)
              .font(StickFont.largeTitle)
              .stickTitleTracking()
              .foregroundStyle(light ? Color.ink : .white)
              .fixedSize(horizontal: false, vertical: true)
              .appear(index: 0)
            if let subtitle {
              Text(subtitle)
                .font(StickFont.body)
                .foregroundStyle(light ? Color.inkSecondary : .white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .appear(index: 1)
            }
          }
          .padding(.top, 12)
          content
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 24)
      }
      .scrollIndicators(.hidden)

      VStack(spacing: 10) {
        footer
      }
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
    }
  }
}

/// Multi-select chip list used by the quiz.
struct ChoiceList<T: Hashable>: View {
  var options: [(value: T, title: LocalizedStringKey, symbol: String)]
  @Binding var selection: [T]

  var body: some View {
    VStack(spacing: 10) {
      ForEach(Array(options.enumerated()), id: \.offset) { index, option in
        let selected = selection.contains(option.value)
        Button {
          if let i = selection.firstIndex(of: option.value) { selection.remove(at: i) } else { selection.append(option.value) }
        } label: {
          HStack(spacing: 12) {
            Image(systemName: option.symbol)
              .font(.system(size: 15, weight: .semibold))
              .frame(width: 24)
            Text(option.title)
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(selected ? Color.brandOrange : Color.ink.opacity(0.25))
          }
        }
        .buttonStyle(ChoiceChipStyle(isSelected: selected))
        .appear(index: index + 2)
        .accessibilityAddTraits(selected ? .isSelected : [])
      }
    }
  }
}
