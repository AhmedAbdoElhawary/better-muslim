import SwiftUI
import UIKit

/// the app's fonts at the trees' sizes. fixed, so the phone's text size never grows a box
/// (FR-029). arabic takes reem kufi for marcellus and noto sans arabic for schibsted grotesk
struct SurfaceFonts {
  let arabic: Bool

  /// marcellus, reem kufi in arabic
  func display(_ size: CGFloat) -> Font {
    arabic ? Self.font("Reem Kufi", size: size, weight: 400) : Self.font("Marcellus", size: size)
  }

  /// schibsted grotesk, noto sans arabic in arabic. weight on the variable fonts' wght axis
  func body(_ size: CGFloat, weight: CGFloat = 400) -> Font {
    Self.font(arabic ? "Noto Sans Arabic" : "Schibsted Grotesk", size: size, weight: weight)
  }

  /// tabular digits, so the countdown doesn't jump as it changes
  func numbers(_ size: CGFloat, weight: CGFloat = 400) -> Font {
    body(size, weight: weight).monospacedDigit()
  }

  private static let weightAxis = 0x7767_6874

  private static func font(_ family: String, size: CGFloat, weight: CGFloat? = nil) -> Font {
    var descriptor = UIFontDescriptor(fontAttributes: [.family: family])
    if let weight {
      descriptor = descriptor.addingAttributes([
        UIFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): [
          weightAxis: weight
        ]
      ])
    }
    return Font(UIFont(descriptor: descriptor, size: size) as CTFont)
  }
}
