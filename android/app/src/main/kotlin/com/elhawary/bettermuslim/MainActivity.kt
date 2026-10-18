package com.elhawary.bettermuslim

import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // home's sky pauses its ambient motion in battery saver (MOTION tiers)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/power")
            .setMethodCallHandler { call, result ->
                if (call.method == "isPowerSaving") {
                    result.success(getSystemService(PowerManager::class.java).isPowerSaveMode)
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/compass")
            .setStreamHandler(CompassStreamHandler(this))
    }
}
