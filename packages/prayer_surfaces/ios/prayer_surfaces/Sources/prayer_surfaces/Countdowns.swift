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
    let nameNow: String
    let barFrom: Double?
    let barFromLabel: String?
    let reminder: String?
  }

  struct Colors: Decodable {
    let dark: [String: UInt32]
  }

  let place: Bool
  let reminderMinutes: Int
  let colors: Colors
  let language: String
  let eastern: Bool
  let texts: Texts
  let entries: [Entry]

  static func of(_ json: String) -> CountdownFile? {
    try? JSONDecoder().decode(CountdownFile.self, from: Data(json.utf8))
  }

  static func read() -> CountdownFile? {
    guard let json = try? String(contentsOf: SurfaceFile.url(), encoding: .utf8) else { return nil }
    return of(json)
  }
}

/// the live countdown while the app is off screen (contracts/surfaces-channel.md "Sync"). ios lets
/// it start only as the app leaves, so before ios 26 that has to be inside the reminder time. it
/// ends as the app comes back
@available(iOS 16.2, *)
enum Countdowns {
  /// ios keeps only a few at once, these cover about a day
  private static let ahead = 4

  /// ending takes a moment, a quick leave again must not count these as running
  private static var ending = Set<String>()

  /// the app is still in front while it resigns, the last moment ios lets it start one. ios 26
  /// schedules the next prayers too, each at its own reminder time
  static func start(_ file: CountdownFile) {
    let now = Date()
    let lead = Double(file.reminderMinutes) * 60_000
    guard file.place, lead > 0, ActivityAuthorizationInfo().areActivitiesEnabled,
      let entry = file.entries.last(where: { Date(millis: $0.from) <= now }),
      Date(millis: entry.at) > now
    else { return }
    let running = Set(live.filter { !ending.contains($0.id) }.map { key($0.attributes) })
    let due = Date(millis: entry.at - lead) <= now
    if due, !running.contains(key(entry)) { _ = try? request(file, entry) }
    guard #available(iOS 26.0, *) else { return }

    /// a prayer time is always an entry's start, the next prayer's entry
    func after(_ at: Double) -> CountdownFile.Entry? {
      file.entries.first { $0.from >= at && $0.at > at }
    }
    var upcoming = due ? after(entry.at) : entry
    for score in 1...ahead {
      guard let next = upcoming else { break }
      if !running.contains(key(next)) {
        do {
          _ = try schedule(file, next, at: Date(millis: next.at - lead), relevance: Double(score))
        } catch {
          break
        }
      }
      upcoming = after(next.at)
    }
  }

  /// the app is on screen again
  static func endAll() {
    let activities = live
    ending.formUnion(activities.map(\.id))
    Task { @MainActor in
      for activity in activities { await activity.end(nil, dismissalPolicy: .immediate) }
      ending.subtract(activities.map(\.id))
    }
  }

  /// on every write: a mark, a new theme or text reaches the running ones, the switch or no place
  /// ends them. one past its time stays as "Maghrib · now" until the app opens, or until ios 26's
  /// next one is showing
  static func sync(_ file: CountdownFile) async {
    let now = Date()
    let on = file.place && file.reminderMinutes > 0
    let activities = live
    let nextShowing = activities.contains {
      $0.activityState == .active && $0.content.state.at > now
    }
    for activity in activities {
      guard on else {
        await activity.end(nil, dismissalPolicy: .immediate)
        continue
      }
      if activity.content.state.at <= now {
        if nextShowing { await activity.end(nil, dismissalPolicy: .immediate) }
        continue
      }
      guard let entry = file.entries.first(where: { key($0) == key(activity.attributes) }) else {
        await activity.end(nil, dismissalPolicy: .immediate)
        continue
      }
      /// a mark changes "Asr 15:27" into "Asr 15:27 · prayed"
      let state = content(file, entry)
      if activity.content.state != state {
        await activity.update(ActivityContent(state: state, staleDate: Date(millis: entry.at)))
      }
    }
  }

  private static var live: [Activity<PrayerCountdownAttributes>] {
    Activity<PrayerCountdownAttributes>.activities.filter(\.isLive)
  }

  private static func request(_ file: CountdownFile, _ entry: CountdownFile.Entry) throws
    -> Activity<PrayerCountdownAttributes>
  {
    try Activity.request(
      attributes: PrayerCountdownAttributes(prayer: entry.prayer, day: entry.day),
      content: ActivityContent(state: content(file, entry), staleDate: Date(millis: entry.at)),
      pushType: nil)
  }

  /// ios asks for an alert when a scheduled one starts, the silent file keeps fajr's quiet. the
  /// later one has the higher relevance, so the island shows it over the one now past
  @available(iOS 26.0, *)
  private static func schedule(
    _ file: CountdownFile, _ entry: CountdownFile.Entry, at start: Date, relevance: Double
  ) throws -> Activity<PrayerCountdownAttributes> {
    try Activity.request(
      attributes: PrayerCountdownAttributes(prayer: entry.prayer, day: entry.day),
      content: ActivityContent(
        state: content(file, entry), staleDate: Date(millis: entry.at), relevanceScore: relevance),
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
      nameNow: entry.nameNow,
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
