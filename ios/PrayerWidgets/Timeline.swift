import WidgetKit

struct SurfaceEntry: TimelineEntry {
  let date: Date
  let file: SurfaceFile

  var state: SurfaceState { SurfaceState(file, at: date) }
}

/// one entry per countdown minute for the next 6 hours, plus every data entry and until, so h:mm,
/// the sun and the ring move with the app closed (research R6)
struct SurfaceTimeline: TimelineProvider {
  private static let span: TimeInterval = 6 * 60 * 60

  func placeholder(in context: Context) -> SurfaceEntry {
    SurfaceEntry(date: Date(), file: SurfaceFile.load())
  }

  func getSnapshot(in context: Context, completion: @escaping (SurfaceEntry) -> Void) {
    completion(SurfaceEntry(date: Date(), file: SurfaceFile.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SurfaceEntry>) -> Void) {
    let file = SurfaceFile.load()
    let now = Date()
    guard let data = file.data, data.place, now.millis < data.until else {
      /// nothing moves until the app writes again, which reloads every timeline
      completion(Timeline(entries: [SurfaceEntry(date: now, file: file)], policy: .never))
      return
    }
    let end = min(now.addingTimeInterval(Self.span), Date(millis: data.until))
    var dates = [now]
    var next = data.nextRedraw(after: now)
    while next < end {
      dates.append(next)
      next = data.nextRedraw(after: next)
    }
    let reachesUntil = end.millis >= data.until
    if reachesUntil { dates.append(end) }
    completion(
      Timeline(
        entries: dates.map { SurfaceEntry(date: $0, file: file) },
        policy: reachesUntil ? .never : .atEnd))
  }
}
