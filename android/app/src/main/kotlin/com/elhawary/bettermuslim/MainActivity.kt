package com.elhawary.bettermuslim

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// audio_service's activity, so the recitation's engine is this one (research R10)
class MainActivity : AudioServiceActivity() {
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

        // the small calls for More, the app's own channel instead of five packages (R10)
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
                    "mail" -> {
                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
                            .putExtra(Intent.EXTRA_EMAIL, arrayOf(call.argument<String>("to") ?: ""))
                            .putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("subject") ?: "")
                            .putExtra(Intent.EXTRA_TEXT, call.argument<String>("body") ?: "")
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (_: ActivityNotFoundException) {
                            result.success(false)
                        }
                    }
                    "device" -> {
                        val model = if (Build.MODEL.startsWith(Build.MANUFACTURER, ignoreCase = true)) {
                            Build.MODEL
                        } else {
                            "${Build.MANUFACTURER} ${Build.MODEL}"
                        }
                        result.success(mapOf("model" to model, "os" to "Android ${Build.VERSION.RELEASE}"))
                    }
                    "keepScreenOn" -> {
                        if (call.argument<Boolean>("on") == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/compass")
            .setStreamHandler(CompassStreamHandler(this))
    }
}
