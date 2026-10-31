import ActivityKit
import Foundation

/// the parts of surfaces.json a countdown needs (contracts/surface-data.md)
struct CountdownFile: Decodable {
  struct Texts: Decodable {
    let nextPrayer: String
    let liveNext: String
    let methodLine: String
    let now: String
  }

  struct Entry: Decodable {
    let from: Double
    let prayer: String
    let day: String
    let at: Double
    let name: String
    let atTime: String
    let nameTime: String
    let barFrom: Double?
    let barFromLabel: String?
    let reminder: String?
  }

  struct Window: Decodable {
    let start: Double
    let end: Double
    let entry: Int
  }

  struct Colors: Decodable {
    let dark: [String: UInt32]
  }

  let place: Bool
  let countdown: Bool
  let colors: Colors
  let language: String
  let eastern: Bool
  let texts: Texts
  let entries: [Entry]
  let countdowns: [Window]

  static func of(_ json: String) -> CountdownFile? {
    try? JSONDecoder().decode(CountdownFile.self, from: Data(json.utf8))
  }
}

/// the live activities kept in step with the file on every update (contracts/surfaces-channel.md
/// "Sync", research R7)
@available(iOS 16.2, *)
enum Countdowns {
  /// "Start countdown now"'s prayer, kept until its time whatever the 2 hours
  private static let startedKey = "prayer_surfaces.started"

  static func sync(_ file: CountdownFile, appActive: Bool) async {
    let now = Date()
    let on = file.place && file.countdown
    let started = UserDefaults.standard.string(forKey: startedKey)
    let windows = file.countdowns.filter { Date(millis: $0.end) > now }
    let wanted = Set(windows.map { key(file.entries[$0.entry]) } + [started].compactMap { $0 })

    for activity in Activity<PrayerCountdownAttributes>.activities where activity.isLive {
      let id = key(activity.attributes)
      guard on, wanted.contains(id), let entry = file.entries.first(where: { key($0) == id }),
        Date(millis: entry.at) > now
      else {
        await activity.end(nil, dismissalPolicy: .immediate)
        continue
      }
      /// a mark changes "Asr 15:27" into "Asr 15:27 · prayed"
      let state = content(file, entry)
      if activity.content.state != state {
        await activity.update(ActivityContent(state: state, staleDate: Date(millis: entry.at)))
      }
    }
    guard on else { return }

    let running = Set(
      Activity<PrayerCountdownAttributes>.activities.filter(\.isLive).map { key($0.attributes) })
    for window in windows {
      let entry = file.entries[window.entry]
      if running.contains(key(entry)) { continue }
      let start = Date(millis: window.start)
      if start <= now {
        /// before ios 26 a live activity starts only from the app in front
        guard appActive, ActivityAuthorizationInfo().areActivitiesEnabled else { continue }
        _ = try? request(file, entry)
      } else if #available(iOS 26.0, *) {
        do {
          _ = try schedule(file, entry, at: start)
        } catch {
          /// the queue is full or ios said no, the next launch, top-up or mark tries again
          break
        }
      } else {
        break
      }
    }
  }

  /// the next prayer's countdown from now, for the dev page. false when they're off or ios says no
  static func startNow(_ file: CountdownFile) -> Bool {
    let now = Date()
    guard file.place, file.countdown, ActivityAuthorizationInfo().areActivitiesEnabled,
      let entry = file.entries.last(where: { Date(millis: $0.from) <= now })
    else { return false }
    UserDefaults.standard.set(key(entry), forKey: startedKey)
    let running = Activity<PrayerCountdownAttributes>.activities.filter(\.isLive)
    if running.contains(where: { key($0.attributes) == key(entry) }) { return true }
    return (try? request(file, entry)) != nil
  }

  private static func request(_ file: CountdownFile, _ entry: CountdownFile.Entry) throws
    -> Activity<PrayerCountdownAttributes>
  {
    try Activity.request(
      attributes: PrayerCountdownAttributes(prayer: entry.prayer, day: entry.day),
      content: ActivityContent(state: content(file, entry), staleDate: Date(millis: entry.at)),
      pushType: nil)
  }

  /// ios asks for an alert when a scheduled one starts, the silent file keeps fajr's quiet
  @available(iOS 26.0, *)
  private static func schedule(_ file: CountdownFile, _ entry: CountdownFile.Entry, at start: Date)
    throws -> Activity<PrayerCountdownAttributes>
  {
    try Activity.request(
      attributes: PrayerCountdownAttributes(prayer: entry.prayer, day: entry.day),
      content: ActivityContent(state: content(file, entry), staleDate: Date(millis: entry.at)),
      pushType: nil,
      style: .standard,
      alertConfiguration: AlertConfiguration(
        title: "\(entry.name)", body: "\(file.texts.liveNext)", sound: .named("silence.caf")),
      start: start)
  }

  private static func content(_ file: CountdownFile, _ entry: CountdownFile.Entry)
    -> PrayerCountdownAttributes.ContentState
  {
    PrayerCountdownAttributes.ContentState(
      nextPrayer: file.texts.nextPrayer,
      liveNext: file.texts.liveNext,
      name: entry.name,
      atTime: entry.atTime,
      barFromLabel: entry.barFromLabel,
      nameTime: entry.nameTime,
      methodLine: file.texts.methodLine,
      reminder: entry.reminder,
      now: file.texts.now,
      language: file.language,
      eastern: file.eastern,
      barFrom: entry.barFrom.map(Date.init(millis:)),
      at: Date(millis: entry.at),
      colors: file.colors.dark)
  }

  private static func key(_ entry: CountdownFile.Entry) -> String { "\(entry.prayer)|\(entry.day)" }

  private static func key(_ attributes: PrayerCountdownAttributes) -> String {
    "\(attributes.prayer)|\(attributes.day)"
  }
}

@available(iOS 16.2, *)
extension Activity {
  /// shown, stale or waiting for its start (ios 26), not ended
  fileprivate var isLive: Bool {
    switch activityState {
    case .ended, .dismissed: return false
    default: return true
    }
  }
}

extension Date {
  fileprivate init(millis: Double) { self.init(timeIntervalSince1970: millis / 1000) }
}
