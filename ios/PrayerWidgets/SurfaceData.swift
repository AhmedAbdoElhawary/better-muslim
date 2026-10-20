import Foundation

/// surfaces.json as the app writes it (contracts/surface-data.md). every text is final, only the
/// countdown numbers and the shares are worked out here (contracts/native-surfaces.md)
struct SurfaceData: Decodable {
  let version: Int
  let place: Bool
  let language: String
  let eastern: Bool
  let countdown: Bool
  let until: Double
  let texts: Texts
  let entries: [Entry]
  let countdowns: [Window]

  struct Texts: Decodable {
    let noPlace: String
    let outdated: String
    let open: String
    let now: String
    let inDuration: String
    let timeLeft: String
    let next: String
    let nextPrayer: String
    let nextCity: String
    let nextCityShort: String
    let liveNext: String
    let methodLine: String
    let channel: String
  }

  struct Entry: Decodable {
    let from: Double
    let prayer: String
    let day: String
    let at: Double
    let name: String
    let time: String
    let atTime: String
    let timeCity: String
    let nameTime: String
    let barFrom: Double?
    let barFromLabel: String?
    let sunrise: Double?
    let maghrib: Double?
    let hijri: String
    let hijriCity: String
    let dateLine: String
    let prayedLine: String
    let reminder: String?
    let next: Int?
    let strip: [Cell]
  }

  struct Cell: Decodable {
    let prayer: String
    let name: String
    let time: String
    let logged: Bool
    let past: Bool
  }

  struct Window: Decodable {
    let start: Double
    let end: Double
    let entry: Int
  }

  /// the app group container the app writes into
  static var url: URL? {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String else {
      return nil
    }
    return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
      .appendingPathComponent("surfaces.json")
  }

  var isArabic: Bool { language == "ar" }

  func entry(at date: Date) -> Entry? {
    let ms = date.millis
    return entries.last { $0.from <= ms }
  }

  /// the next moment anything shown changes: the h:mm flip, the next entry or until
  func nextRedraw(after date: Date) -> Date {
    let ms = date.millis
    var moments = [until]
    if let entry = entry(at: date) {
      moments.append(entry.at - Double(minutesLeft(entry, at: date)) * 60_000)
    }
    if let next = entries.first(where: { $0.from > ms }) { moments.append(next.from) }
    let soonest = moments.filter { $0 > ms }.min() ?? until
    return Date(millis: soonest)
  }

  func minutesLeft(_ entry: Entry, at date: Date) -> Int {
    max(0, Int(((entry.at - date.millis) / 60_000).rounded(.down)))
  }

  /// "1:23", the countdowns' h:mm
  func hm(_ entry: Entry, at date: Date) -> String {
    let minutes = minutesLeft(entry, at: date)
    return digits("\(minutes / 60):" + String(format: "%02d", minutes % 60))
  }

  func inDuration(_ entry: Entry, at date: Date) -> String {
    texts.inDuration.replacingOccurrences(of: "{duration}", with: hm(entry, at: date))
  }

  /// home's bar share, nil without the period's start
  func barShare(_ entry: Entry, at date: Date) -> Double? {
    guard let from = entry.barFrom, entry.at > from else { return nil }
    return min(1, max(0, (date.millis - from) / (entry.at - from)))
  }

  /// home's sun share, only between sunrise and maghrib
  func sunShare(_ entry: Entry, at date: Date) -> Double? {
    guard let sunrise = entry.sunrise, let maghrib = entry.maghrib, maghrib > sunrise else {
      return nil
    }
    let ms = date.millis
    guard ms >= sunrise, ms <= maghrib else { return nil }
    return ((ms - sunrise) / (maghrib - sunrise) * 1000).rounded() / 1000
  }

  /// the prayer, the time left, its time and the place, as one line for voiceover
  func spoken(_ entry: Entry, at date: Date) -> String {
    let minutes = minutesLeft(entry, at: date)
    let left = texts.timeLeft
      .replacingOccurrences(of: "{hours}", with: digits("\(minutes / 60)"))
      .replacingOccurrences(of: "{minutes}", with: digits("\(minutes % 60)"))
      .replacingOccurrences(of: "{prayer}", with: entry.name)
    return "\(left), \(entry.timeCity)"
  }

  func digits(_ text: String) -> String {
    guard eastern else { return text }
    return String(
      text.map { character in
        guard let value = character.wholeNumberValue, character.isASCII else { return character }
        return Character(UnicodeScalar(0x0660 + value)!)
      })
  }
}

/// the file as read once per timeline
enum SurfaceFile {
  case missing
  /// an app newer than this extension may write a shape it can't read
  case newer
  case data(SurfaceData)

  static func load() -> SurfaceFile {
    struct Header: Decodable { let version: Int }
    guard let url = SurfaceData.url, let raw = try? Data(contentsOf: url),
      let header = try? JSONDecoder().decode(Header.self, from: raw)
    else { return .missing }
    guard header.version <= 1, let data = try? JSONDecoder().decode(SurfaceData.self, from: raw)
    else { return .newer }
    return .data(data)
  }

  var data: SurfaceData? {
    if case .data(let data) = self { return data }
    return nil
  }
}

/// what a surface shows at a moment
enum SurfaceState {
  case noPlace(String)
  case outdated(String)
  case ready(SurfaceData, SurfaceData.Entry)

  /// no file means the app hasn't written yet, so the message comes from Localizable.strings
  init(_ file: SurfaceFile, at date: Date) {
    switch file {
    case .missing:
      self = .noPlace(NSLocalizedString("noPlace", comment: ""))
    case .newer:
      self = .outdated(NSLocalizedString("outdated", comment: ""))
    case .data(let data):
      if !data.place {
        self = .noPlace(data.texts.noPlace)
      } else if date.millis < data.until, let entry = data.entry(at: date) {
        self = .ready(data, entry)
      } else {
        self = .outdated(data.texts.outdated)
      }
    }
  }
}

extension Date {
  init(millis: Double) {
    self.init(timeIntervalSince1970: millis / 1000)
  }

  var millis: Double { timeIntervalSince1970 * 1000 }
}
