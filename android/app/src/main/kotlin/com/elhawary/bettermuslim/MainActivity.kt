package com.elhawary.bettermuslim

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
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

        // three small calls for More, the app's own channel instead of three packages (R10)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    }
                    "openUrl" -> {
                        val uri = call.argument<String>("url")?.let(Uri::parse)
                        if (uri?.scheme != "https") {
                            result.success(false)
                        } else {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, uri))
                                result.success(true)
                            } catch (_: ActivityNotFoundException) {
                                result.success(false)
                            }
                        }
                    }
                    "version" -> {
                        val info = packageManager.getPackageInfo(packageName, 0)
                        val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            info.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            info.versionCode.toLong()
                        }
                        result.success("${info.versionName} ($build)")
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/compass")
            .setStreamHandler(CompassStreamHandler(this))
    }
}
