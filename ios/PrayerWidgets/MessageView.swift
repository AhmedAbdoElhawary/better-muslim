import SwiftUI
import WidgetKit

enum SurfaceLinks {
  static let home = URL(string: "bettermuslim://open/")!

  /// the prayer tab on the shown day at that prayer, like home's strip
  static func prayer(day: String, prayer: String) -> URL {
    URL(string: "bettermuslim://open/prayer?day=\(day)&prayer=\(prayer)")!
  }
}

extension View {
  /// the tree's background behind the content, edge to edge. ios 17 asks for it as the container's
  func widgetBackground<Background: View>(_ background: Background) -> some View {
    modifier(WidgetBackground(background: background))
  }

  /// the parts a tinted or clear home screen and standby accent
  @ViewBuilder
  func accentable() -> some View {
    if #available(iOSApplicationExtension 16.0, *) {
      widgetAccentable()
    } else {
      self
    }
  }

  /// only the highlighted cell or row, the others follow the system
  @ViewBuilder
  func accentable(_ on: Bool) -> some View {
    if on { accentable() } else { self }
  }

  /// the app's language, whatever the phone's. the arc, bar, ring and clock times opt out
  func surfaceLanguage(_ data: SurfaceData) -> some View {
    environment(\.layoutDirection, data.isArabic ? .rightToLeft : .leftToRight)
      .environment(\.locale, Locale(identifier: data.language))
  }
}

private struct WidgetBackground<Background: View>: ViewModifier {
  @Environment(\.palette) private var palette
  let background: Background

  func body(content: Content) -> some View {
    /// the trees' inset 0.5 pt hairline at 10%
    let framed = ZStack {
      background
      ContainerRelativeShape()
        .inset(by: 0.25)
        .stroke(palette.text.opacity(0.1), lineWidth: 0.5)
    }
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(for: .widget) { framed }
    } else {
      content.frame(maxWidth: .infinity, maxHeight: .infinity).background(framed)
    }
  }
}

/// no place and out of date: the frame, the mark and what to do instead of wrong times (FR-024)
struct MessageView: View {
  @Environment(\.colorScheme) private var scheme
  let entry: SurfaceEntry

  var body: some View {
    let palette = entry.file.palette(scheme)
    let arabic =
      entry.file.data?.isArabic ?? (Locale.preferredLanguages.first?.hasPrefix("ar") ?? false)
    let fonts = SurfaceFonts(arabic: arabic)
    VStack(spacing: 10) {
      Star(size: 23, stroke: 1.1)
      Text(entry.state.message ?? "")
        .font(fonts.body(13, weight: 500))
        .foregroundColor(palette.text)
        .multilineTextAlignment(.center)
        .lineLimit(3)
        .minimumScaleFactor(0.8)
    }
    .padding(16)
    .environment(\.layoutDirection, arabic ? .rightToLeft : .leftToRight)
    .widgetURL(SurfaceLinks.home)
    .widgetBackground(palette.widgetSky)
    .environment(\.palette, palette)
  }
}

extension SurfaceState {
  var message: String? {
    switch self {
    case .noPlace(let message), .outdated(let message): return message
    case .ready: return nil
    }
  }
}
