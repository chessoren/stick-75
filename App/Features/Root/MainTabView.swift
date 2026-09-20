import SwiftUI

struct MainTabView: View {
  @Environment(CallCoordinator.self) private var calls

  var body: some View {
    @Bindable var calls = calls
    TabView(selection: $calls.selectedTab) {
      ForEach(MainTab.allCases) { tab in
        Tab(value: tab) {
          tabContent(tab)
        } label: {
          Label {
            Text(tab.title)
          } icon: {
            Image(systemName: tab.symbol)
          }
        }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tint(.brandOrange)
  }

  @ViewBuilder
  private func tabContent(_ tab: MainTab) -> some View {
    switch tab {
    case .today: HomeView()
    case .calls: CallsView()
    case .league: LeagueView()
    case .me: MeView()
    }
  }
}
