import ActivityKit
import Foundation

/// the same as packages/prayer_surfaces' copy, field for field. activitykit matches the two by name
@available(iOS 16.2, *)
struct PrayerCountdownAttributes: ActivityAttributes {
  /// contracts/surface-data.md "countdown content", every text final
  struct ContentState: Codable, Hashable {
    var nextPrayer: String
    var liveNext: String
    var name: String
    var atTime: String
    var barFromLabel: String?
    var nameTime: String
    var methodLine: String
    var reminder: String?
    var now: String
    var language: String
    var eastern: Bool
    var barFrom: Date?
    var at: Date
  }

  var prayer: String
  var day: String
}
