package com.elhawary.bettermuslim

import android.app.NotificationManager
import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// audio_service's activity, so the recitation's engine is this one (research R10)
class MainActivity : AudioServiceActivity() {
    private var tone: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
                    "playTone" -> {
                        // the channel's own sound, I may have changed it in the phone's settings
                        val channel = call.argument<String>("channel")
                            ?.let { getSystemService(NotificationManager::class.java).getNotificationChannel(it) }
                        val uri = channel?.sound ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                        tone?.stop()
                        tone = RingtoneManager.getRingtone(this, uri)?.apply {
                            audioAttributes = AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                                .build()
                            play()
                        }
                        result.success(null)
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

        // audio_service keeps this engine after the activity is gone, a download goes on in it
        DownloadService.channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/downloads")
            .apply {
                setMethodCallHandler { call, result ->
                    @Suppress("UNCHECKED_CAST")
                    val arguments = call.arguments as Map<String, Any?>
                    when (call.method) {
                        "show" -> DownloadService.show(applicationContext, arguments)
                        "end" -> DownloadService.end(applicationContext, arguments["id"] as Int, arguments["failed"] as String?)
                        else -> return@setMethodCallHandler result.notImplemented()
                    }
                    result.success(null)
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "better_muslim/compass")
            .setStreamHandler(CompassStreamHandler(this))
    }
}
