import SwiftUI
import WidgetKit

@main
struct PrayerWidgetsBundle: WidgetBundle {
  var body: some Widget {
    NextPrayerWidget()
    TodaysPrayersWidget()
    if #available(iOS 16.0, *) {
      LockScreenWidget()
    }
    if #available(iOS 16.2, *) {
      CountdownActivity()
    }
  }
}

/// 5.6 small
struct NextPrayerWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NextPrayer", provider: SurfaceTimeline()) { entry in
      SmallWidget(entry: entry)
    }
    .configurationDisplayName(NSLocalizedString("nextPrayerName", comment: ""))
    .description(NSLocalizedString("nextPrayerDescription", comment: ""))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

/// 5.6 medium and large
struct TodaysPrayersWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "TodaysPrayers", provider: SurfaceTimeline()) { entry in
      TodaysPrayersView(entry: entry)
    }
    .configurationDisplayName(NSLocalizedString("todaysPrayersName", comment: ""))
    .description(NSLocalizedString("todaysPrayersDescription", comment: ""))
    .supportedFamilies([.systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

/// 5.7, its own kind because the lock screen has its own gallery text (research R6)
@available(iOS 16.0, *)
struct LockScreenWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "LockScreen", provider: SurfaceTimeline()) { entry in
      Accessories(entry: entry)
    }
    .configurationDisplayName(NSLocalizedString("lockScreenName", comment: ""))
    .description(NSLocalizedString("lockScreenDescription", comment: ""))
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

private struct TodaysPrayersView: View {
  @Environment(\.widgetFamily) private var family
  let entry: SurfaceEntry

  var body: some View {
    if family == .systemLarge {
      LargeWidget(entry: entry)
    } else {
      MediumWidget(entry: entry)
    }
  }
}
