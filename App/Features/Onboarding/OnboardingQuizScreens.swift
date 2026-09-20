import SwiftUI

// MARK: - 1. Hook

struct HookScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var hours = 0
  @State private var shown = false

  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      VStack(alignment: .leading, spacing: 14) {
        Text("You spend")
          .font(StickFont.title2)
          .foregroundStyle(.white.opacity(0.9))
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          CountingText(value: hours, font: StickFont.font(88, .semibold, relativeTo: .largeTitle), color: .white)
          Text("hours")
            .font(StickFont.title)
            .foregroundStyle(.white.opacity(0.9))
        }
        Text("a year on TikTok. That's 25 full days. Gone.")
          .font(StickFont.title2)
          .foregroundStyle(.white)
          .fixedSize(horizontal: false, vertical: true)
          .opacity(shown ? 1 : 0)
          .offset(y: shown ? 0 : 12)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, StickMetrics.screenMargin)
      Spacer()
      VStack(spacing: 10) {
        Button {
          model.next()
        } label: {
          Text("I want them back")
        }
        .buttonStyle(PrimaryPillButtonStyle())
        Text("75 days. Your voice. Your life.")
          .font(StickFont.footnoteMedium)
          .foregroundStyle(.white.opacity(0.8))
      }
      .padding(.horizontal, StickMetrics.screenMargin)
      .padding(.bottom, 12)
      .opacity(shown ? 1 : 0)
    }
    .onAppear {
      withAnimation(.smooth(duration: 1.6)) { hours = 608 }
      withAnimation(.smooth(duration: 0.6).delay(1.2)) { shown = true }
    }
  }
}

// MARK: - 2. Pitch

struct PitchScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var isPlaying = false
  private let speech = SystemSpeechService()

  var body: some View {
    OnboardingPage("What if your own voice called you to stop?", subtitle: "Stick clones your voice. It calls you in the morning for your goals, the second you open TikTok, and at night for the debrief. You can ignore anyone. Not yourself.", light: false) {
      VStack(alignment: .leading, spacing: 12) {
        PitchRow(symbol: "sunrise.fill", title: "7:00 · Wake-up call", text: "\"Up. Give me three goals. Real ones.\"")
        PitchRow(symbol: "hand.raised.fill", title: "14:12 · You open TikTok", text: "\"You promised me this morning. Close it. Yes or no?\"")
        PitchRow(symbol: "moon.stars.fill", title: "21:30 · Debrief", text: "\"What did you actually do today?\"")
      }
      .padding(.top, 8)
    } footer: {
      Button {
        model.next()
      } label: {
        Text("Continue")
      }
      .buttonStyle(PrimaryPillButtonStyle())
      Button {
        play()
      } label: {
        Label(isPlaying ? "Playing…" : "Hear an example", systemImage: "play.fill")
      }
      .buttonStyle(SecondaryPillButtonStyle())
      .disabled(isPlaying)
    }
  }

  private func play() {
    isPlaying = true
    Task {
      AudioSessionManager.activateForPlayback()
      let line = model.language == .french
        ? "Tu m'as promis ce matin. Tu fermes TikTok. Oui ou non ?"
        : "You promised me this morning. Close TikTok. Yes or no?"
      await speech.speak(line, language: model.language)
      isPlaying = false
    }
  }
}

struct PitchRow: View {
  var symbol: String
  var title: LocalizedStringKey
  var text: LocalizedStringKey

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 40, height: 40)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(StickFont.footnoteMedium)
          .foregroundStyle(Color.inkSecondary)
        Text(text)
          .font(StickFont.headline)
          .foregroundStyle(Color.ink)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .stickCard(padding: 14)
  }
}

// MARK: - 3. Which apps

struct QuizAppsScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("Which apps steal your time?", subtitle: "Pick everything that applies. Stick blocks and intercepts these.") {
      ChoiceList(options: TimeSink.allCases.map { ($0, LocalizedStringKey($0.title), $0.symbol) }, selection: $model.draft.timeSinks)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(model.draft.timeSinks.isEmpty)
    }
  }
}

// MARK: - 4. How many hours

struct QuizHoursScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("How many hours a day?", subtitle: "Be honest. Check Screen Time if you're not sure. Most people underestimate by half.") {
      VStack(alignment: .leading, spacing: 20) {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
          Text(model.draft.hoursPerDay, format: .number.precision(.fractionLength(1)))
            .font(StickFont.hero)
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(Color.ink)
          Text("h / day")
            .font(StickFont.title3)
            .foregroundStyle(Color.inkSecondary)
        }
        .animation(.smooth(duration: 0.2), value: model.draft.hoursPerDay)

        Slider(value: $model.draft.hoursPerDay, in: 0.5...8) {
          Text("Hours per day")
        } minimumValueLabel: {
          Text("½h").font(StickFont.caption)
        } maximumValueLabel: {
          Text("8h").font(StickFont.caption)
        }
        .tint(.brandOrange)
        .sensoryFeedback(.selection, trigger: Int(model.draft.hoursPerDay * 2))

        VStack(alignment: .leading, spacing: 6) {
          Text("That's \(model.daysPerYear) full days a year.")
            .font(StickFont.title3)
            .foregroundStyle(Color.ink)
            .contentTransition(.numericText())
          Text("Days you'll never get back. Unless you stop now.")
            .font(StickFont.callout)
            .foregroundStyle(Color.inkSecondary)
        }
        .stickCard()
        .animation(.smooth(duration: 0.3), value: model.daysPerYear)
      }
      .padding(.top, 10)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
    }
  }
}

// MARK: - 5. When you crack

struct QuizMomentsScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("When do you crack?", subtitle: "Stick learns your weak moments so the calls land when they should.") {
      ChoiceList(options: [
        ("bed", "In bed, before sleep", "bed.double.fill"),
        ("wake", "First thing in the morning", "sunrise.fill"),
        ("toilet", "On the toilet", "toilet.fill"),
        ("work", "At work or in class", "laptopcomputer"),
        ("evening", "Evenings on the couch", "sofa.fill"),
        ("waiting", "Any time I'm waiting", "clock.fill")
      ], selection: $model.draft.crackMoments)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(model.draft.crackMoments.isEmpty)
    }
  }
}

// MARK: - 6. How you feel after

struct QuizFeelingsScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("How do you feel after a long scroll?", subtitle: "No wrong answer. Stick will remind you of this one.") {
      ChoiceList(options: [
        ("shame", "Ashamed", "eye.slash.fill"),
        ("empty", "Empty", "circle.dashed"),
        ("tired", "Exhausted", "battery.25percent"),
        ("anxious", "Anxious", "waveform.path.ecg"),
        ("behind", "Behind on everything", "clock.badge.exclamationmark.fill"),
        ("nothing", "Nothing at all", "minus")
      ], selection: $model.draft.feelings)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(model.draft.feelings.isEmpty)
    }
  }
}

// MARK: - 7. What you'd do with the time

struct QuizDreamsScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("What would you do with \(Int(model.draft.hoursPerDay.rounded())) hours a day?", subtitle: "This becomes your morning goals. Choose what actually matters.") {
      ChoiceList(options: [
        ("project", "Build my project or business", "hammer.fill"),
        ("sport", "Train. Get in shape.", "figure.run"),
        ("study", "Study. Pass. Level up.", "graduationcap.fill"),
        ("read", "Read real books", "book.fill"),
        ("sleep", "Sleep properly", "moon.zzz.fill"),
        ("people", "Be with people I love", "person.2.fill"),
        ("money", "Earn more money", "banknote.fill")
      ], selection: $model.draft.dreams)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(model.draft.dreams.isEmpty)
    }
  }
}

// MARK: - 8. What you tried

struct QuizTriedScreen: View {
  @Environment(OnboardingModel.self) private var model

  var body: some View {
    @Bindable var model = model
    OnboardingPage("What have you tried?", subtitle: "Screen Time limits get skipped with one tap. Stick doesn't have a skip button.") {
      ChoiceList(options: [
        ("screentime", "Screen Time limits", "hourglass"),
        ("delete", "Deleting the app (and reinstalling)", "trash.fill"),
        ("blocker", "A blocker app", "lock.fill"),
        ("willpower", "Pure willpower", "flame.fill"),
        ("nothing", "Nothing yet", "questionmark")
      ], selection: $model.draft.triedBefore)
    } footer: {
      Button { model.next() } label: { Text("Continue") }
        .buttonStyle(PrimaryPillButtonStyle())
        .disabled(model.draft.triedBefore.isEmpty)
    }
  }
}

// MARK: - 9. Result

struct ResultScreen: View {
  @Environment(OnboardingModel.self) private var model
  @State private var hours = 0

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Text("In 75 days you get back")
            .font(StickFont.title2)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.top, 12)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            CountingText(value: hours, font: StickFont.font(88, .semibold, relativeTo: .largeTitle), color: .white)
            Text("hours")
              .font(StickFont.title)
              .foregroundStyle(.white.opacity(0.9))
          }
          Text("That's what your \(model.draft.hoursPerDay, format: .number.precision(.fractionLength(1))) hours a day are worth. Here's what people do with them:")
            .font(StickFont.body)
            .foregroundStyle(.white.opacity(0.9))
            .fixedSize(horizontal: false, vertical: true)

          VStack(spacing: 10) {
            ResultRow(symbol: "book.fill", value: max(1, model.hoursIn75Days / 6), text: "books read cover to cover")
            ResultRow(symbol: "figure.run", value: max(1, Int(Double(model.hoursIn75Days) / 0.75)), text: "45-minute runs")
            ResultRow(symbol: "hammer.fill", value: max(1, model.hoursIn75Days / 40), text: "full work weeks on your project")
            ResultRow(symbol: "bed.double.fill", value: max(1, model.hoursIn75Days / 8), text: "full nights of sleep")
          }
        }
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 24)
      }
      .scrollIndicators(.hidden)

      Button { model.next() } label: { Text("Let's get them") }
        .buttonStyle(PrimaryPillButtonStyle())
        .padding(.horizontal, StickMetrics.screenMargin)
        .padding(.bottom, 12)
    }
    .onAppear {
      withAnimation(.smooth(duration: 1.4)) { hours = model.hoursIn75Days }
    }
  }
}

struct ResultRow: View {
  var symbol: String
  var value: Int
  var text: LocalizedStringKey

  var body: some View {
    HStack(spacing: 14) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.brandOrange)
        .frame(width: 40, height: 40)
        .background(Color.brandOrange.opacity(0.12), in: Circle())
      Text(value, format: .number)
        .font(StickFont.title2)
        .monospacedDigit()
        .foregroundStyle(Color.ink)
      Text(text)
        .font(StickFont.callout)
        .foregroundStyle(Color.inkSecondary)
      Spacer()
    }
    .stickCard(padding: 14)
  }
}
