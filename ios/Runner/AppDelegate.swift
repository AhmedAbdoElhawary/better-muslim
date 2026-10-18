import CoreLocation
import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // the plugin shows notifications in front and hands taps to dart through this delegate
    UNUserNotificationCenter.current().delegate = self
    // ios only runs a task registered before launch ends, the name is topUpTask in background.dart
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "better_muslim.topup", earliestBeginInSeconds: NSNumber(value: 6 * 60 * 60))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // mark prayed from a notification runs dart in a background engine, it needs the plugins too
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupExclusion") {
      registerBackupExclusion(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PowerSaving") {
      registerPowerSaving(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "Compass") {
      registerCompass(messenger: registrar.messenger())
    }
  }

  /// iCloud backs Application Support up, the store has to stay on this phone (FR-023)
  private func registerBackupExclusion(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "better_muslim/backup", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "exclude", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        // only the error code, the description can hold the path
        let code = (error as NSError).code
        result(FlutterError(code: "exclude_failed", message: "\(code)", details: nil))
      }
    }
  }

  /// home's sky pauses its ambient motion in low power mode (MOTION tiers)
  private func registerPowerSaving(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "better_muslim/power", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "isPowerSaving" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(ProcessInfo.processInfo.isLowPowerModeEnabled)
    }
  }

  /// the qibla's magnetic heading, dart adds the declination (contracts/compass-channel.md)
  private func registerCompass(messenger: FlutterBinaryMessenger) {
    let channel = FlutterEventChannel(name: "better_muslim/compass", binaryMessenger: messenger)
    channel.setStreamHandler(CompassStreamHandler())
  }
}

/// never asks for location: magnetic heading needs no permission, true heading would
class CompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private var events: FlutterEventSink?
  private var orientationObserver: NSObjectProtocol?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    guard CLLocationManager.headingAvailable() else {
      events(nil)
      return nil
    }
    self.events = events
    manager.delegate = self
    manager.headingFilter = 0.5
    updateOrientation()
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    orientationObserver = NotificationCenter.default.addObserver(
      forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
    ) { [weak self] _ in
      self?.updateOrientation()
    }
    manager.startUpdatingHeading()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager.stopUpdatingHeading()
    if let observer = orientationObserver {
      NotificationCenter.default.removeObserver(observer)
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    orientationObserver = nil
    events = nil
    return nil
  }

  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    let accuracy = newHeading.headingAccuracy < 0 ? -1 : newHeading.headingAccuracy
    events?(["heading": newHeading.magneticHeading, "accuracy": accuracy])
  }

  // the low accuracy hint asks for the figure 8 in the app's own words
  func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
    false
  }

  /// the heading of the top of the screen as shown, landscape included (R8)
  private func updateOrientation() {
    let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    switch scene?.interfaceOrientation {
    case .portraitUpsideDown: manager.headingOrientation = .portraitUpsideDown
    // interface landscape left is the device turned right
    case .landscapeLeft: manager.headingOrientation = .landscapeRight
    case .landscapeRight: manager.headingOrientation = .landscapeLeft
    default: manager.headingOrientation = .portrait
    }
  }
}
