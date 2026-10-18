package com.elhawary.bettermuslim

import android.content.Intent
import android.os.PowerManager
import androidx.core.app.NotificationManagerCompat
import com.elhawary.bettermuslim.adhan.AdhanAlarms
import com.elhawary.bettermuslim.adhan.AdhanReceiver
import com.elhawary.bettermuslim.adhan.AdhanService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private var openedSink: EventChannel.EventSink? = null

    // read once, a second read after a rebuild must not open the adhan screen again
    private var launchPayload: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        launchPayload = payloadOf(intent)

        // home's sky pauses its ambient motion in battery saver (MOTION tiers)
        MethodChannel(messenger, "better_muslim/power")
            .setMethodCallHandler { call, result ->
                if (call.method == "isPowerSaving") {
                    result.success(getSystemService(PowerManager::class.java).isPowerSaveMode)
                } else {
                    result.notImplemented()
                }
            }

        // contracts/adhan-channel.md
        MethodChannel(messenger, "better_muslim/adhan").setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    @Suppress("UNCHECKED_CAST")
                    AdhanAlarms.schedule(this, call.arguments as List<Map<String, Any?>>)
                    result.success(null)
                }
                "cancelAll" -> {
                    AdhanAlarms.cancelAll(this)
                    result.success(null)
                }
                "play" -> {
                    val entry = JSONObject(call.argument<Map<String, Any?>>("entry")!!)
                    val sounds = AdhanAlarms.canSound(this)
                    if (sounds) AdhanService.play(this, entry, call.argument<Int>("fromMillis") ?: 0)
                    result.success(sounds)
                }
                "pause" -> {
                    AdhanService.pause(this)
                    result.success(null)
                }
                "resume" -> {
                    AdhanService.resume(this)
                    result.success(null)
                }
                "stop" -> {
                    AdhanService.stop(this)
                    result.success(null)
                }
                "markPrayedAction" -> {
                    AdhanService.current?.markPrayed(call.arguments as Int)
                    result.success(null)
                }
                "length" -> result.success(AdhanService.length(this, call.arguments as String))
                "dismiss" -> {
                    NotificationManagerCompat.from(this).cancel(call.arguments as Int)
                    result.success(null)
                }
                "launchPayload" -> {
                    result.success(launchPayload)
                    launchPayload = null
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "better_muslim/adhan/state").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                AdhanService.stateSink = events
                AdhanService.publishNow()
            }

            override fun onCancel(arguments: Any?) {
                AdhanService.stateSink = null
            }
        })

        EventChannel(messenger, "better_muslim/adhan/opened").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                openedSink = events
            }

            override fun onCancel(arguments: Any?) {
                openedSink = null
            }
        })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        payloadOf(intent)?.let { openedSink?.success(it) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        AdhanService.stateSink = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun payloadOf(intent: Intent?): String? =
        intent?.takeIf { it.action == AdhanReceiver.ACTION_OPEN }?.getStringExtra(AdhanReceiver.EXTRA_PAYLOAD)
}
