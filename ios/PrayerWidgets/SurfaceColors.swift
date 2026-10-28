import SwiftUI

/// the dark qiyam emerald values (TOKENS.md) and the trees' own, whatever theme the app shows.
/// the always dark exception, the only place the extension holds colors
enum SurfaceColors {
  static let text = Color(hex: 0xD9D3C2)
  static let label = Color(hex: 0xB9B3A2)
  static let dim = Color(hex: 0x878C82)
  static let gold = Color(hex: 0xD9C08A)
  static let liveGold = Color(hex: 0xE9D7AE)
  static let primary = Color(hex: 0xA88A52)
  static let primaryContainer = Color(hex: 0x221C10)
  static let success = Color(hex: 0x5FB389)
  static let ring = Color(hex: 0x5A5F58)
  static let sun = Color(hex: 0xCDB27A)
  static let sky = Color(hex: 0x173328)
  static let night = Color(hex: 0x04100C)
  static let deepNight = Color(hex: 0x0B1E17)

  /// the small and medium widgets
  static let widgetSky = LinearGradient(
    stops: [
      .init(color: .black, location: 0), .init(color: night, location: 0.45),
      .init(color: sky, location: 1),
    ], startPoint: .top, endPoint: .bottom)

  /// the large widget
  static let largeSky = LinearGradient(
    stops: [
      .init(color: .black, location: 0), .init(color: night, location: 0.3),
      .init(color: deepNight, location: 1),
    ], startPoint: .top, endPoint: .bottom)

  /// the live activity's star tile
  static let tile = RadialGradient(
    colors: [sky, .black], center: .bottom, startRadius: 0, endRadius: 34)

  static let bar = LinearGradient(colors: [primary, gold], startPoint: .leading, endPoint: .trailing)
}

extension Color {
  init(hex: UInt32, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: opacity)
  }
}
