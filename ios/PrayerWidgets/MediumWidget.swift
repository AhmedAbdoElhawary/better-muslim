import SwiftUI
import WidgetKit

/// 5.6 medium: all five, the next highlighted, a tick under each one prayed
struct MediumWidget: View {
  @Environment(\.colorScheme) private var scheme
  let entry: SurfaceEntry

  var body: some View {
    switch entry.state {
    case .ready(let data, let item):
      MediumContent(data: data, entry: item, date: entry.date)
        .widgetURL(SurfaceLinks.home)
        .widgetBackground(data.palette(item, scheme).widgetSky)
        .environment(\.palette, data.palette(item, scheme))
    default:
      MessageView(entry: entry)
    }
  }
}

private struct MediumContent: View {
  @Environment(\.palette) private var palette
  let data: SurfaceData
  let entry: SurfaceData.Entry
  let date: Date

  var body: some View {
    let fonts = SurfaceFonts(arabic: data.isArabic)
    VStack(spacing: 0) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 0) {
          Text(entry.name)
            .font(fonts.display(24))
            .foregroundColor(palette.text)
            .lineLimit(1)
            .line(24, 1.15)
          Text(entry.hijriCity)
            .font(fonts.body(12))
            .foregroundColor(palette.label)
            .lineLimit(1)
            .truncationMode(.tail)
            .line(12)
        }
        Spacer(minLength: 8)
        Text(data.hm(entry, at: date))
          .font(fonts.numbers(22, weight: 600))
          .foregroundColor(palette.gold)
          .environment(\.layoutDirection, .leftToRight)
          .accentable()
      }
      .padding(.horizontal, 2)
      Spacer(minLength: 0)
      HStack(spacing: 4) {
        ForEach(Array(entry.strip.enumerated()), id: \.offset) { index, cell in
          Link(destination: SurfaceLinks.prayer(day: entry.day, prayer: cell.prayer)) {
            StripCell(cell: cell, current: entry.next == index, fonts: fonts)
          }
        }
      }
    }
    .padding(EdgeInsets(top: 14, leading: 14, bottom: 12, trailing: 14))
    .surfaceLanguage(data)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(data.spoken(entry, at: date))
  }
}

private struct StripCell: View {
  @Environment(\.palette) private var palette
  let cell: SurfaceData.Cell
  let current: Bool
  let fonts: SurfaceFonts

  var body: some View {
    VStack(spacing: 3) {
      Text(cell.name)
        .font(fonts.body(10, weight: current ? 600 : 400))
        .foregroundColor(current ? palette.gold : palette.label)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .line(10)
      Text(cell.time)
        .font(fonts.numbers(12, weight: 500))
        .foregroundColor(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .line(12)
      ZStack {
        if cell.logged { Check(size: 10) }
      }
      .frame(height: 10)
    }
    .frame(maxWidth: .infinity)
    /// the tree's height, only the text went smaller to fit the width
    .frame(height: 61)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(current ? palette.primary.opacity(0.2) : palette.text.opacity(0.05))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(current ? palette.primary.opacity(0.45) : .clear, lineWidth: 1)
    )
    .accentable(current)
  }
}
