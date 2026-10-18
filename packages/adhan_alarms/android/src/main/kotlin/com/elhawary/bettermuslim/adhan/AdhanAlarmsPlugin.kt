package com.elhawary.bettermuslim.adhan

import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject

// contracts/adhan-channel.md. a plugin, so the background top-up's engine reaches the alarms too
class AdhanAlarmsPlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.NewIntentListener {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var state: EventChannel
    private lateinit var opened: EventChannel
    private var activity: ActivityPluginBinding? = null
    private var openedSink: EventChannel.EventSink? = null

    // read once, a second read after a rebuild must not open the adhan screen again
    private var launchPayload: String? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "better_muslim/adhan")
        methods.setMethodCallHandler(this)
        state = EventChannel(binding.binaryMessenger, "better_muslim/adhan/state")
        state.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                AdhanService.stateSink = events
                AdhanService.publishNow()
            }

            override fun onCancel(arguments: Any?) {
                AdhanService.stateSink = null
            }
        })
        opened = EventChannel(binding.binaryMessenger, "better_muslim/adhan/opened")
        opened.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                openedSink = events
            }

            override fun onCancel(arguments: Any?) {
                openedSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        state.setStreamHandler(null)
        opened.setStreamHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "schedule" -> {
                @Suppress("UNCHECKED_CAST")
                AdhanAlarms.schedule(context, call.arguments as List<Map<String, Any?>>)
                result.success(null)
            }
            "cancelAll" -> {
                AdhanAlarms.cancelAll(context)
                result.success(null)
            }
            "play" -> {
                val entry = JSONObject(call.argument<Map<String, Any?>>("entry")!!)
                val sounds = AdhanAlarms.canSound(context)
                if (sounds) AdhanService.play(context, entry, call.argument<Int>("fromMillis") ?: 0)
                result.success(sounds)
            }
            "pause" -> {
                AdhanService.pause(context)
                result.success(null)
            }
            "resume" -> {
                AdhanService.resume(context)
                result.success(null)
            }
            "stop" -> {
                AdhanService.stop(context)
                result.success(null)
            }
            "markPrayedAction" -> {
                AdhanService.current?.markPrayed(call.arguments as Int)
                result.success(null)
            }
            "length" -> result.success(AdhanService.length(context, call.arguments as String))
            "dismiss" -> {
                NotificationManagerCompat.from(context).cancel(call.arguments as Int)
                result.success(null)
            }
            "launchPayload" -> {
                result.success(launchPayload)
                launchPayload = null
            }
            else -> result.notImplemented()
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addOnNewIntentListener(this)
        launchPayload = payloadOf(binding.activity.intent)
    }

    override fun onDetachedFromActivity() {
        activity?.removeOnNewIntentListener(this)
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onNewIntent(intent: Intent): Boolean {
        val payload = payloadOf(intent) ?: return false
        openedSink?.success(payload)
        return true
    }

    private fun payloadOf(intent: Intent?): String? =
        intent?.takeIf { it.action == AdhanReceiver.ACTION_OPEN }?.getStringExtra(AdhanReceiver.EXTRA_PAYLOAD)
}
