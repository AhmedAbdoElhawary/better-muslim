import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupExclusion") {
      registerBackupExclusion(messenger: registrar.messenger())
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
}
