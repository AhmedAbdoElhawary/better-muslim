import SwiftUI
import WidgetKit

/// 5.6 small: the next prayer with the sun on its arc
struct SmallWidget: View {
  @Environment(\.colorScheme) private var scheme
  let entry: SurfaceEntry

  var body: some View {
    switch entry.state {
    case .ready(let data, let item):
      SmallContent(data: data, entry: item, date: entry.date)
        .widgetURL(SurfaceLinks.home)
        .widgetBackground(data.palette(item, scheme).widgetSky)
        .environment(\.palette, data.palette(item, scheme))
    default:
      MessageView(entry: entry)
    }
  }
}

private struct SmallContent: View {
  @Environment(\.palette) private var palette
  let data: SurfaceData
  let entry: SurfaceData.Entry
  let date: Date

  var body: some View {
    let fonts = SurfaceFonts(arabic: data.isArabic)
    let night = data.nightShare(entry, at: date)
    ZStack {
      SunArc(share: night ?? data.sunShare(entry, at: date), night: night != nil)
      VStack(alignment: .leading, spacing: 0) {
        Text(data.texts.next)
          .font(fonts.body(11))
          .tracking(11 * 0.12)
          .foregroundColor(palette.label)
          .line(11)
        Text(entry.name)
          .font(fonts.display(24))
          .foregroundColor(palette.text)
          .lineLimit(1)
          .line(24, 1.15)
        Text(data.inDuration(entry, at: date))
          .font(fonts.numbers(15, weight: 600))
          .foregroundColor(palette.gold)
          .accentable()
          .line(15)
        Spacer(minLength: 0)
        /// a long city is cut, never the time, which comes first
        Text(entry.timeCity)
          .font(fonts.numbers(12))
          .foregroundColor(palette.label)
          .lineLimit(1)
          .truncationMode(.tail)
          .line(12)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .padding(.vertical, 14)
      .padding(.horizontal, 16)
    }
    .surfaceLanguage(data)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(data.spoken(entry, at: date))
  }
}

/// the 170 x 170 drawing of the tree, scaled to the widget. by night the three stars, as home's.
/// never mirrored
private struct SunArc: View {
  @Environment(\.palette) private var palette
  let share: Double?
  let night: Bool

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        ArcShape(share: 1)
          .stroke(
            palette.text.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 4]))
        Horizon().stroke(palette.text.opacity(0.2), lineWidth: 1)
        if let share {
          ArcShape(share: share)
            .stroke(
              palette.text.opacity(0.75),
              style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
          Group {
            if night { NightStars() } else { Sun() }
          }
          .position(ArcGeometry(size: geometry.size).point(share))
          .accentable()
        }
      }
    }
    .environment(\.layoutDirection, .leftToRight)
    .accessibilityHidden(true)
  }
}

/// the tree's arc, centre 85 128 and radius 65 in its 170 box
private struct ArcGeometry {
  let size: CGSize

  func point(_ share: Double) -> CGPoint {
    let angle = Double.pi * (1 - share)
    return CGPoint(
      x: (85 + 65 * cos(angle)) * size.width / 170,
      y: (128 - 65 * sin(angle)) * size.height / 170)
  }
}

private struct ArcShape: Shape {
  let share: Double

  func path(in rect: CGRect) -> Path {
    let arc = ArcGeometry(size: rect.size)
    var path = Path()
    path.move(to: arc.point(0))
    for step in 1...60 { path.addLine(to: arc.point(share * Double(step) / 60)) }
    return path
  }
}

private struct Horizon: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let y = 128 * rect.height / 170
    path.move(to: CGPoint(x: 0, y: y))
    path.addLine(to: CGPoint(x: rect.width, y: y))
    return path
  }
}

/// 14 pt with its glow, 0 0 14px 5px at 45%
struct Sun: View {
  @Environment(\.palette) private var palette
  var body: some View {
    ZStack {
      Circle()
        .fill(palette.sun.opacity(0.45))
        .frame(width: 24, height: 24)
        .blur(radius: 7)
      Circle()
        .fill(palette.sun)
        .frame(width: 14, height: 14)
    }
  }
}

/// home's three, 7 pt and 5 from their middle, the first on top
private struct NightStars: View {
  @Environment(\.palette) private var palette
  var body: some View {
    ZStack {
      ForEach(0..<3, id: \.self) { index in
        let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / 3
        StarMark()
          .fill(palette.sun)
          .frame(width: 7, height: 7)
          .offset(x: 5 * cos(angle), y: 5 * sin(angle))
      }
    }
  }
}
