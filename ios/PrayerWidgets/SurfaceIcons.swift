import SwiftUI

/// the 8 point star of the trees, viewBox -11 -11 22 22. a shape, so each surface strokes it at
/// its own width
struct StarMark: Shape {
  private static let points: [(CGFloat, CGFloat)] = [
    (0, -10), (2.93, -7.07), (7.07, -7.07), (7.07, -2.93), (10, 0), (7.07, 2.93), (7.07, 7.07),
    (2.93, 7.07), (0, 10), (-2.93, 7.07), (-7.07, 7.07), (-7.07, 2.93), (-10, 0), (-7.07, -2.93),
    (-7.07, -7.07), (-2.93, -7.07),
  ]

  func path(in rect: CGRect) -> Path {
    let scale = min(rect.width, rect.height) / 22
    var path = Path()
    for (index, (x, y)) in Self.points.enumerated() {
      let point = CGPoint(x: rect.midX + x * scale, y: rect.midY + y * scale)
      if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}

/// the star at a size with the stroke the tree gives it there
struct Star: View {
  let size: CGFloat
  let stroke: CGFloat
  var color: Color?
  @Environment(\.palette) private var palette

  var body: some View {
    StarMark()
      .stroke(color ?? palette.primary, style: StrokeStyle(lineWidth: stroke * size / 22, lineJoin: .round))
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}

/// assets/icons/ui/check.svg
struct CheckMark: Shape {
  func path(in rect: CGRect) -> Path {
    let scale = rect.width / 24
    var path = Path()
    path.move(to: CGPoint(x: 5 * scale, y: 12.5 * scale))
    path.addLine(to: CGPoint(x: 9.5 * scale, y: 17 * scale))
    path.addLine(to: CGPoint(x: 19 * scale, y: 7.5 * scale))
    return path
  }
}

struct Check: View {
  @Environment(\.palette) private var palette
  let size: CGFloat

  var body: some View {
    CheckMark()
      .stroke(
        palette.success,
        style: StrokeStyle(lineWidth: 1.25 * size / 24, lineCap: .round, lineJoin: .round)
      )
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}

/// assets/icons/outline/adhan.svg
struct BellMark: Shape {
  func path(in rect: CGRect) -> Path {
    let scale = rect.width / 24
    func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }
    var path = Path()
    path.move(to: point(6.5, 16.5))
    path.addLine(to: point(6.5, 11))
    path.addArc(
      center: point(12, 11), radius: 5.5 * scale, startAngle: .degrees(180),
      endAngle: .degrees(0), clockwise: false)
    path.addLine(to: point(17.5, 16.5))
    path.addLine(to: point(19, 18.5))
    path.addLine(to: point(5, 18.5))
    path.closeSubpath()
    path.move(to: point(10, 20.5))
    path.addArc(
      center: point(12, 20.5), radius: 2 * scale, startAngle: .degrees(180),
      endAngle: .degrees(0), clockwise: true)
    return path
  }
}
