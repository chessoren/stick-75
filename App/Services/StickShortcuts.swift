import AppIntents

/// Exposes "Call Stick" to Shortcuts, Siri and Spotlight so the automation can also use the action directly.
struct StickShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartCallIntent(),
      phrases: ["Call \(.applicationName)", "Appelle \(.applicationName)"],
      shortTitle: "Call Stick",
      systemImageName: "phone.fill"
    )
  }
}
