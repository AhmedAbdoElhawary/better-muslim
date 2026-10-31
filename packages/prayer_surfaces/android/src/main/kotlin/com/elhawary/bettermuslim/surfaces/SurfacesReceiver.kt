package com.elhawary.bettermuslim.surfaces

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// the minute tick, a prayer time the countdown rolls at, or the phone restarted, the app was
// updated or the clock or zone changed
class SurfacesReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            SurfaceTicks.ACTION_TICK -> PrayerWidget.tick(context)
            SurfaceTicks.ACTION_ROLL -> {}
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> {
                // the app isn't on screen after either, so the countdown comes back like the adhan alarms
                PrayerWidget.refresh(context)
                CountdownNotification.onScreen(context, false)
                return
            }
            else -> PrayerWidget.refresh(context)
        }
        CountdownNotification.sync(context)
        SurfaceTicks.arm(context)
    }
}
