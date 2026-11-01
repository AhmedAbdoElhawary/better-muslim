import SwiftUI

/// the theme's colors the app writes into surfaces.json, one set for light and one for dark. the
/// extension holds no colors of its own
struct SurfacePalette: Decodable {
  let top: Color
  let middle: Color
  let bottom: Color
  let deep: Color
  let text: Color
  let label: Color
  let dim: Color
  let gold: Color
  let live: Color
  let primary: Color
  let container: Color
  let success: Color
  let ring: Color
  let sun: Color
  let outline: Color

  init(_ roles: [String: UInt32]) {
    /// no file yet, the system's own colors until the app writes
    func role(_ key: String, _ system: Color) -> Color { roles[key].map(Color.init(argb:)) ?? system }
    top = role("top", Color(.systemBackground))
    middle = role("middle", Color(.systemBackground))
    bottom = role("bottom", Color(.secondarySystemBackground))
    deep = role("deep", Color(.secondarySystemBackground))
    text = role("text", .primary)
    label = role("label", .secondary)
    dim = role("dim", .secondary)
    gold = role("gold", .accentColor)
    live = role("live", .accentColor)
    primary = role("primary", .accentColor)
    container = role("container", Color(.tertiarySystemFill))
    success = role("success", .green)
    ring = role("ring", .secondary)
    sun = role("sun", .accentColor)
    outline = role("outline", Color(.separator))
  }

  init(from decoder: Decoder) throws {
    self.init(try decoder.singleValueContainer().decode([String: UInt32].self))
  }

  static let system = SurfacePalette([:])

  /// the small and medium widgets
  var widgetSky: LinearGradient {
    LinearGradient(
      stops: [
        .init(color: top, location: 0), .init(color: middle, location: 0.45),
        .init(color: bottom, location: 1),
      ], startPoint: .top, endPoint: .bottom)
  }

  /// the large widget
  var largeSky: LinearGradient {
    LinearGradient(
      stops: [
        .init(color: top, location: 0), .init(color: middle, location: 0.3),
        .init(color: deep, location: 1),
      ], startPoint: .top, endPoint: .bottom)
  }

  /// the live activity's star tile
  var tile: RadialGradient {
    RadialGradient(colors: [bottom, top], center: .bottom, startRadius: 0, endRadius: 34)
  }

  var bar: LinearGradient {
    LinearGradient(colors: [primary, gold], startPoint: .leading, endPoint: .trailing)
  }
}

struct SurfaceColors: Decodable {
  let light: SurfacePalette
  let dark: SurfacePalette
}

private struct PaletteKey: EnvironmentKey {
  static let defaultValue = SurfacePalette.system
}

extension EnvironmentValues {
  var palette: SurfacePalette {
    get { self[PaletteKey.self] }
    set { self[PaletteKey.self] = newValue }
  }
}

extension Color {
  init(argb: UInt32) {
    self.init(
      .sRGB,
      red: Double((argb >> 16) & 0xFF) / 255,
      green: Double((argb >> 8) & 0xFF) / 255,
      blue: Double(argb & 0xFF) / 255,
      opacity: Double((argb >> 24) & 0xFF) / 255)
  }
}
