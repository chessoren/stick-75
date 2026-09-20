import SwiftUI
import WidgetKit

@main
struct StickWidgetBundle: WidgetBundle {
  var body: some Widget {
    TodayGoalsWidget()
    DaysHeldWidget()
    CallStickControl()
    CallLiveActivity()
    StickAlarmLiveActivity()
  }
}
