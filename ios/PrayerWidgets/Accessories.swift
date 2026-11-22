import SwiftUI
import WidgetKit

/// 5.7, monochrome: white and its opacities, the system tints them like the clock (FR-010)
@available(iOSApplicationExtension 16.0, *)
struct Accessories: View {
  @Environment(\.widgetFamily) private var family
  let entry: SurfaceEntry

  var body: some View {
    Group {
      switch family {
      case .accessoryCircular: CircularAccessory(entry: entry)
      case .accessoryInline: InlineAccessory(entry: entry)
      default: RectangularAccessory(entry: entry)
      }
    }
    .widgetURL(SurfaceLinks.home)
    .widgetBackground(Color.clear)
  }
}

/// the ring from the period's start to the prayer, the star and h:mm. the star alone without data
@available(iOSApplicationExtension 16.0, *)
private struct CircularAccessory: View {
  let entry: SurfaceEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      if case .ready(let data, let item) = entry.state {
        let fonts = SurfaceFonts(arabic: data.isArabic)
        Circle()
          .stroke(Color.white.opacity(0.28), lineWidth: 5)
          .padding(5)
        /// from 12 o'clock, never mirrored
        Circle()
          .trim(from: 0, to: data.barShare(item, at: entry.date) ?? 0)
          .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .padding(5)
        VStack(spacing: 1) {
          Star(size: 13, stroke: 1.6, color: .white)
          Text(data.hm(item, at: entry.date))
            .font(fonts.numbers(15, weight: 600))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 8)
      } else {
        Star(size: 13, stroke: 1.6, color: .white)
      }
    }
    .environment(\.layoutDirection, .leftToRight)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.spokenLine)
  }
}

/// the prayer and its time, the time left, the hijri date. the message without data
@available(iOSApplicationExtension 16.0, *)
private struct RectangularAccessory: View {
  let entry: SurfaceEntry

  var body: some View {
    if case .ready(let data, let item) = entry.state {
      let fonts = SurfaceFonts(arabic: data.isArabic)
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 5) {
          Star(size: 12, stroke: 1.6, color: .white)
          Text(item.nameTime)
            .font(fonts.numbers(15, weight: 600))
            .foregroundColor(.white)
        }
        Text(data.inDuration(item, at: entry.date))
          .font(fonts.numbers(15))
          .foregroundColor(Color.white.opacity(0.8))
        Text(item.hijri)
          .font(fonts.body(13))
          .foregroundColor(Color.white.opacity(0.66))
      }
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: .leading)
      .surfaceLanguage(data)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(entry.spokenLine)
    } else {
      let arabic = entry.file.data?.isArabic ?? Locale.preferredLanguages.first?.hasPrefix("ar") ?? false
      HStack(spacing: 6) {
        Star(size: 12, stroke: 1.6, color: .white)
        Text(entry.state.message ?? "")
          .font(SurfaceFonts(arabic: arabic).body(13, weight: 500))
          .foregroundColor(.white)
          .lineLimit(3)
          .minimumScaleFactor(0.8)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .environment(\.layoutDirection, arabic ? .rightToLeft : .leftToRight)
    }
  }
}

/// one line above the clock, in the system's font: the star and "Maghrib 17:56"
@available(iOSApplicationExtension 16.0, *)
private struct InlineAccessory: View {
  let entry: SurfaceEntry

  var body: some View {
    Label {
      switch entry.state {
      case .ready(_, let item): Text(item.nameTime)
      default: Text(entry.file.data?.texts.open ?? NSLocalizedString("open", comment: ""))
      }
    } icon: {
      Image("Star")
    }
    .accessibilityLabel(entry.spokenLine)
  }
}

extension SurfaceEntry {
  /// the prayer, the time left, its time and the place, or the message
  var spokenLine: String {
    switch state {
    case .ready(let data, let item): return data.spoken(item, at: date)
    default: return state.message ?? ""
    }
  }
}
