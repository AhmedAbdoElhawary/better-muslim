import SwiftUI
import WidgetKit

/// 5.6 large: the day at a glance, with what was prayed
struct LargeWidget: View {
  @Environment(\.colorScheme) private var scheme
  let entry: SurfaceEntry

  var body: some View {
    switch entry.state {
    case .ready(let data, let item):
      LargeContent(data: data, entry: item, date: entry.date)
        .widgetURL(SurfaceLinks.home)
        .widgetBackground(data.palette(item, scheme).largeSky)
        .environment(\.palette, data.palette(item, scheme))
    default:
      MessageView(entry: entry)
    }
  }
}

private struct LargeContent: View {
  @Environment(\.palette) private var palette
  let data: SurfaceData
  let entry: SurfaceData.Entry
  let date: Date

  var body: some View {
    let fonts = SurfaceFonts(arabic: data.isArabic)
    VStack(spacing: 10) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 0) {
          Text(data.texts.nextCity)
            .font(fonts.body(11))
            .tracking(11 * 0.12)
            .foregroundColor(palette.label)
            .lineLimit(1)
            .truncationMode(.tail)
            .line(11)
          Text(entry.name)
            .font(fonts.display(28))
            .foregroundColor(palette.text)
            .lineLimit(1)
            .line(28, 1.15)
        }
        Spacer(minLength: 8)
        VStack(alignment: .trailing, spacing: 0) {
          Text(data.hm(entry, at: date))
            .font(fonts.numbers(24, weight: 600))
            .foregroundColor(palette.gold)
            .environment(\.layoutDirection, .leftToRight)
            .accentable()
            .line(24)
          Text(entry.atTime)
            .font(fonts.body(12))
            .foregroundColor(palette.label)
            .line(12)
        }
      }
      .padding(.horizontal, 2)

      /// each row's tap takes in the 2 pt gaps around it, 42 pt (the spec's approved break)
      VStack(spacing: 0) {
        ForEach(Array(entry.strip.enumerated()), id: \.offset) { index, cell in
          Link(destination: SurfaceLinks.prayer(day: entry.day, prayer: cell.prayer)) {
            PrayerRow(cell: cell, current: entry.next == index, fonts: fonts)
              .padding(.vertical, 1)
              .contentShape(Rectangle())
          }
        }
      }
      .padding(.vertical, -1)

      Spacer(minLength: 0)
      HStack {
        Text(entry.prayedLine)
        Spacer(minLength: 8)
        Text(entry.dateLine).lineLimit(1)
      }
      .font(fonts.body(12.5))
      .foregroundColor(palette.label)
      .line(12.5)
      .padding(EdgeInsets(top: 10, leading: 4, bottom: 0, trailing: 4))
      .overlay(alignment: .top) {
        Rectangle().fill(palette.text.opacity(0.08)).frame(height: 1)
      }
    }
    .padding(EdgeInsets(top: 16, leading: 16, bottom: 14, trailing: 16))
    .surfaceLanguage(data)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(data.spoken(entry, at: date))
  }
}

private struct PrayerRow: View {
  @Environment(\.palette) private var palette
  let cell: SurfaceData.Cell
  let current: Bool
  let fonts: SurfaceFonts

  var body: some View {
    HStack(spacing: 12) {
      Text(cell.name)
        .font(fonts.display(17))
        .foregroundColor(current ? palette.gold : palette.text)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(cell.time)
        .font(fonts.numbers(15, weight: 500))
        .foregroundColor(palette.text)
      ZStack {
        if cell.logged {
          Check(size: 16)
        } else {
          Circle()
            .strokeBorder(palette.ring, lineWidth: 1.2)
            .frame(width: 12, height: 12)
        }
      }
      .frame(width: 22, alignment: .trailing)
    }
    .padding(.horizontal, 12)
    .frame(height: 40)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(current ? palette.primary.opacity(0.2) : .clear)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(current ? palette.primary.opacity(0.45) : .clear, lineWidth: 1)
    )
    .accentable(current)
  }
}
