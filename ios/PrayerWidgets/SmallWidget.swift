import SwiftUI
import WidgetKit

/// 5.6 small: the next prayer with the sun on its arc
struct SmallWidget: View {
  let entry: SurfaceEntry

  var body: some View {
    switch entry.state {
    case .ready(let data, let item):
      SmallContent(data: data, entry: item, date: entry.date)
        .widgetURL(SurfaceLinks.home)
        .widgetBackground(SurfaceColors.widgetSky)
    default:
      MessageView(entry: entry)
    }
  }
}

private struct SmallContent: View {
  let data: SurfaceData
  let entry: SurfaceData.Entry
  let date: Date

  var body: some View {
    let fonts = SurfaceFonts(arabic: data.isArabic)
    ZStack {
      SunArc(share: data.sunShare(entry, at: date))
      VStack(alignment: .leading, spacing: 0) {
        Text(data.texts.next)
          .font(fonts.body(11))
          .tracking(11 * 0.12)
          .foregroundColor(SurfaceColors.label)
        Text(entry.name)
          .font(fonts.display(24))
          .foregroundColor(SurfaceColors.text)
          .lineLimit(1)
        Text(data.inDuration(entry, at: date))
          .font(fonts.numbers(15, weight: 600))
          .foregroundColor(SurfaceColors.gold)
          .accentable()
        Spacer(minLength: 0)
        /// a long city is cut, never the time, which comes first
        Text(entry.timeCity)
          .font(fonts.numbers(12))
          .foregroundColor(SurfaceColors.label)
          .lineLimit(1)
          .truncationMode(.tail)
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

/// the 170 x 170 drawing of the tree, scaled to the widget. by night only the dotted arc, as
/// home's. never mirrored
private struct SunArc: View {
  let share: Double?

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        ArcShape(share: 1)
          .stroke(
            SurfaceColors.text.opacity(0.35),
            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 4]))
        Horizon().stroke(SurfaceColors.text.opacity(0.2), lineWidth: 1)
        if let share {
          ArcShape(share: share)
            .stroke(
              SurfaceColors.text.opacity(0.75),
              style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
          Sun()
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
  var body: some View {
    ZStack {
      Circle()
        .fill(SurfaceColors.sun.opacity(0.45))
        .frame(width: 24, height: 24)
        .blur(radius: 7)
      Circle()
        .fill(SurfaceColors.sun)
        .frame(width: 14, height: 14)
    }
  }
}
