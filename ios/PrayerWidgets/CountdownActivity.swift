import ActivityKit
import SwiftUI
import WidgetKit

/// 5.3 on the lock screen and 5.4 in the dynamic island while the app is off screen, counted by
/// the system with no server (research R7). the bar has no sun on it, ios draws a timer's progress
/// itself and nothing can ride on it
@available(iOS 16.2, *)
struct CountdownActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PrayerCountdownAttributes.self) { context in
      let palette = SurfacePalette(context.state.colors)
      CountdownCard(state: context.state, stale: context.isStale)
        .environment(\.palette, palette)
        .activityBackgroundTint(Color.black.opacity(0.62))
        .activitySystemActionForegroundColor(palette.text)
        .widgetURL(SurfaceLinks.home)
    } dynamicIsland: { context in
      let state = context.state
      let stale = context.isStale
      let palette = SurfacePalette(state.colors)
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          ExpandedHeader(state: state, stale: stale).environment(\.palette, palette)
        }
        DynamicIslandExpandedRegion(.trailing) {
          if !stale {
            CountdownColumn(state: state, stale: stale, size: 26).environment(\.palette, palette)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          ExpandedFooter(state: state, stale: stale).environment(\.palette, palette)
        }
      } compactLeading: {
        Star(size: 18, stroke: 1.3, color: palette.primary)
      } compactTrailing: {
        CountdownText(state: state, stale: stale, size: 15)
          .countdownLocale(state)
          .environment(\.palette, palette)
      } minimal: {
        Star(size: 18, stroke: 1.3, color: palette.primary)
      }
      .widgetURL(SurfaceLinks.home)
    }
  }
}

/// 5.3: the tile, the prayer, the countdown, the bar and its two ends
@available(iOS 16.2, *)
private struct CountdownCard: View {
  @Environment(\.palette) private var palette
  let state: PrayerCountdownAttributes.ContentState
  let stale: Bool

  var body: some View {
    let fonts = SurfaceFonts(arabic: state.language == "ar")
    VStack(spacing: 12) {
      HStack(spacing: 12) {
        StarTile()
        VStack(alignment: .leading, spacing: 0) {
          Text(state.liveNext)
            .font(fonts.body(12.5))
            .foregroundColor(palette.label)
            .lineLimit(1)
            .accessibilitySortPriority(1)
          /// past its time before ios 26 it waits for the app, honest about it
          Text(stale ? state.nameNow : state.name)
            .font(fonts.display(24))
            .foregroundColor(.white)
            .lineLimit(1)
            .accessibilitySortPriority(4)
        }
        Spacer(minLength: 8)
        if !stale { CountdownColumn(state: state, stale: stale, size: 28) }
      }
      BarWithLabels(state: state, stale: stale)
    }
    .padding(EdgeInsets(top: 16, leading: 18, bottom: 14, trailing: 18))
    .countdownLanguage(state)
  }
}

/// 5.4 expanded, the top row's start
@available(iOS 16.2, *)
private struct ExpandedHeader: View {
  @Environment(\.palette) private var palette
  let state: PrayerCountdownAttributes.ContentState
  let stale: Bool

  var body: some View {
    let fonts = SurfaceFonts(arabic: state.language == "ar")
    HStack(spacing: 12) {
      Star(size: 30, stroke: 1)
      VStack(alignment: .leading, spacing: 0) {
        Text(state.nextPrayer)
          .font(fonts.body(12.5))
          .foregroundColor(palette.label)
          .lineLimit(1)
        Text(stale ? state.nameNow : state.name)
          .font(fonts.display(24))
          .foregroundColor(.white)
          .lineLimit(1)
          .accessibilitySortPriority(4)
      }
    }
    .padding(.leading, 6)
    .countdownLanguage(state)
  }
}

/// 5.4 expanded, under the top row: the bar, its ends, the method and the reminder chip
@available(iOS 16.2, *)
private struct ExpandedFooter: View {
  @Environment(\.palette) private var palette
  let state: PrayerCountdownAttributes.ContentState
  let stale: Bool

  var body: some View {
    let fonts = SurfaceFonts(arabic: state.language == "ar")
    VStack(spacing: 12) {
      BarWithLabels(state: state, stale: stale)
      HStack {
        Text(state.methodLine)
          .font(fonts.body(12.5))
          .foregroundColor(palette.label)
          .lineLimit(1)
        Spacer(minLength: 8)
        if let reminder = state.reminder {
          HStack(spacing: 5) {
            BellMark()
              .stroke(
                palette.gold,
                style: StrokeStyle(lineWidth: 1.25 * 15 / 24, lineCap: .round, lineJoin: .round))
              .frame(width: 15, height: 15)
              .accessibilityHidden(true)
            Text(reminder)
              .font(fonts.numbers(13, weight: 500))
              .foregroundColor(palette.gold)
              .lineLimit(1)
          }
          .padding(.horizontal, 12)
          .frame(height: 30)
          .background(Capsule().fill(palette.container))
        }
      }
    }
    .padding(EdgeInsets(top: 4, leading: 6, bottom: 2, trailing: 6))
    .countdownLanguage(state)
  }
}

/// the countdown over "at 17:56", at the end of the top row
@available(iOS 16.2, *)
private struct CountdownColumn: View {
  @Environment(\.palette) private var palette
  let state: PrayerCountdownAttributes.ContentState
  let stale: Bool
  let size: CGFloat

  var body: some View {
    let fonts = SurfaceFonts(arabic: state.language == "ar")
    VStack(alignment: .trailing, spacing: 0) {
      CountdownText(state: state, stale: stale, size: size)
        .accessibilitySortPriority(3)
      Text(state.atTime)
        .font(fonts.numbers(12.5))
        .foregroundColor(palette.label)
        .lineLimit(1)
        .accessibilitySortPriority(2)
    }
    .countdownLocale(state)
  }
}

/// h:mm:ss drawn by the system to the second, "Now" once the prayer time is past (FR-016, FR-019)
@available(iOS 16.2, *)
private struct CountdownText: View {
  @Environment(\.palette) private var palette
  let state: PrayerCountdownAttributes.ContentState
  let stale: Bool
  let size: CGFloat

  var body: some View {
    let fonts = SurfaceFonts(arabic: state.language == "ar")
    Group {
      if stale {
        Text(state.now)
      } else {
        /// a timer text takes all the width it gets, the widest value sizes it instead
        Text("0:00:00")
          .hidden()
          .overlay(alignment: .trailing) {
            Text(timerInterval: Date.distantPast...state.at, countsDown: true)
              .multilineTextAlignment(.trailing)
          }
      }
    }
    .font(fonts.numbers(size, weight: 600))
    .foregroundColor(palette.live)
    .lineLimit(1)
    .environment(\.layoutDirection, .leftToRight)
  }
}

/// the system's progress from the period's start to the prayer, so it moves with the app closed.
/// the sun can't follow it (Q2). no bar without the start, as home
@available(iOS 16.2, *)
private struct BarWithLabels: View {
  @Environment(\.palette) private var palette
  let state: PrayerCountdownAttributes.ContentState
  let stale: Bool

  var body: some View {
    let fonts = SurfaceFonts(arabic: state.language == "ar")
    if let barFrom = state.barFrom, barFrom < state.at {
      VStack(spacing: 12) {
        Group {
          if stale {
            ProgressView(value: 1)
          } else {
            ProgressView(timerInterval: barFrom...state.at, countsDown: false) {
              EmptyView()
            } currentValueLabel: {
              EmptyView()
            }
          }
        }
        .progressViewStyle(.linear)
        .tint(palette.gold)
        .background(Capsule().fill(Color.white.opacity(0.2)).frame(height: 4))
        .frame(height: 16)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
        HStack {
          Text(state.barFromLabel ?? "")
          Spacer(minLength: 8)
          Text(state.nameTime)
        }
        .font(fonts.numbers(12))
        .foregroundColor(palette.label)
        .lineLimit(1)
      }
    }
  }
}

/// 40 pt, the trees' radial sky behind the 23 pt star
private struct StarTile: View {
  @Environment(\.palette) private var palette
  var body: some View {
    RoundedRectangle(cornerRadius: 11)
      .fill(palette.tile)
      .overlay(
        RoundedRectangle(cornerRadius: 11).strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
      .overlay(Star(size: 23, stroke: 1.1))
      .frame(width: 40, height: 40)
      .accessibilityHidden(true)
  }
}

@available(iOS 16.2, *)
extension View {
  /// the app's language, whatever the phone's. the bar and the timer opt out
  fileprivate func countdownLanguage(_ state: PrayerCountdownAttributes.ContentState) -> some View {
    environment(\.layoutDirection, state.language == "ar" ? .rightToLeft : .leftToRight)
      .countdownLocale(state)
  }

  /// the system draws the timer's digits in the view's locale (Q4)
  fileprivate func countdownLocale(_ state: PrayerCountdownAttributes.ContentState) -> some View {
    let identifier = state.language != "ar" ? "en" : state.eastern ? "ar" : "ar@numbers=latn"
    return environment(\.locale, Locale(identifier: identifier))
  }
}
