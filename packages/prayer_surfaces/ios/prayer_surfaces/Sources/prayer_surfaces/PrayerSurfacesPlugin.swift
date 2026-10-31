import Flutter
import UIKit
import WidgetKit

/// contracts/surfaces-channel.md. a plugin, so the background engines reach the surfaces too
public class PrayerSurfacesPlugin: NSObject, FlutterPlugin {
  /// every engine registers the plugin, the app's leaving and coming back is watched once
  private static var watching = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "better_muslim/surfaces", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(PrayerSurfacesPlugin(), channel: channel)
    guard #available(iOS 16.2, *), !watching else { return }
    watching = true
    let center = NotificationCenter.default
    center.addObserver(
      forName: UIApplication.willResignActiveNotification, object: nil, queue: .main
    ) { _ in
      if let file = CountdownFile.read() { Countdowns.start(file) }
    }
    center.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      Task { await Countdowns.endAll() }
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "update":
      guard let arguments = call.arguments as? [String: Any],
        let json = arguments["json"] as? String
      else {
        result(FlutterError(code: "surfaces_failed", message: "arguments", details: nil))
        return
      }
      var failure: FlutterError?
      do {
        if try SurfaceFile.write(json, force: arguments["force"] as? Bool ?? false) {
          WidgetCenter.shared.reloadAllTimelines()
        }
      } catch {
        /// only the error code, the description can hold the path
        failure = FlutterError(
          code: "surfaces_failed", message: "\((error as NSError).code)", details: nil)
      }
      /// whether or not the file changed, a running one may need the new marks or colors
      guard #available(iOS 16.2, *), let file = CountdownFile.of(json) else {
        result(failure)
        return
      }
      Task { @MainActor in
        await Countdowns.sync(file)
        result(failure)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

/// surfaces.json in the app group, where the widget extension reads it
enum SurfaceFile {
  static func url() throws -> URL {
    guard let group = Bundle.main.object(forInfoDictionaryKey: "AppGroup") as? String,
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: group)
    else { throw CocoaError(.fileNoSuchFile) }
    return container.appendingPathComponent("surfaces.json")
  }

  /// false when the file already holds the same, so no widget reloads for nothing (R5)
  static func write(_ json: String, force: Bool) throws -> Bool {
    var url = try url()
    let data = Data(json.utf8)
    if !force, let old = try? Data(contentsOf: url), old == data { return false }

    /// the lock screen reads it while the phone is locked, so not complete protection
    try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])

    /// the app group is backed up to icloud, and an atomic write replaces the flag with the file
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try url.setResourceValues(values)
    return true
  }
}
