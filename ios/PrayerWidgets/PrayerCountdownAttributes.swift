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
    /// "Maghrib · now", once the prayer time is past and ios before 26 can't start the next
    var nameNow: String
    var methodLine: String
    var reminder: String?
    var now: String
    var language: String
    var eastern: Bool
    var barFrom: Date?
    var at: Date
    /// the theme's dark palette, the lock screen's own colors
    var colors: [String: UInt32]
  }

  var prayer: String
  var day: String
}
