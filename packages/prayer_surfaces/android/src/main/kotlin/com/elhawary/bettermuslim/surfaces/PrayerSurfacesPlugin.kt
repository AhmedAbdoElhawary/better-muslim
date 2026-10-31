package com.elhawary.bettermuslim.surfaces

import android.app.Activity
import android.app.Application
import android.content.Context
import android.os.Bundle
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// contracts/surfaces-channel.md. a plugin, so the background engines reach the surfaces too. only
// the app's engine has an activity, its start and stop move the live countdown
class PrayerSurfacesPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private var activity: Activity? = null

    private val lifecycle = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityStarted(started: Activity) {
            if (started == activity) CountdownNotification.onScreen(context, true)
        }

        // a rotation stops and starts it again, nothing left the screen
        override fun onActivityStopped(stopped: Activity) {
            if (stopped == activity && !stopped.isChangingConfigurations) CountdownNotification.onScreen(context, false)
        }

        override fun onActivityCreated(created: Activity, state: Bundle?) {}

        override fun onActivityResumed(resumed: Activity) {}

        override fun onActivityPaused(paused: Activity) {}

        override fun onActivitySaveInstanceState(saved: Activity, state: Bundle) {}

        override fun onActivityDestroyed(destroyed: Activity) {}
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "better_muslim/surfaces")
        methods.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.activity.application.registerActivityLifecycleCallbacks(lifecycle)
        // attached while it is being created, before its start
        CountdownNotification.onScreen(context, true)
    }

    override fun onDetachedFromActivity() {
        activity?.application?.unregisterActivityLifecycleCallbacks(lifecycle)
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

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
                else -> result.notImplemented()
            }
        } catch (error: Exception) {
            // only the class name, a message can hold the path
            result.error("surfaces_failed", error.javaClass.simpleName, null)
        }
    }
}
