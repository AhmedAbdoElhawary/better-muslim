package com.elhawary.bettermuslim.surfaces

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// contracts/surfaces-channel.md. a plugin, so the background engines reach the surfaces too
class PrayerSurfacesPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "better_muslim/surfaces")
        methods.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "update" -> {
                    if (SurfaceData.update(context, call.argument<String>("json")!!, call.argument<Boolean>("force") ?: false)) {
                        PrayerWidget.refresh(context)
                    }
                    CountdownNotification.sync(context)
                    SurfaceTicks.arm(context)
                    result.success(null)
                }
                "startNow" -> result.success(CountdownNotification.startNow(context))
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            // only the class name, a message can hold the path
            result.error("surfaces_failed", error.javaClass.simpleName, null)
        }
    }
}
