package com.elhawary.bettermuslim.surfaces

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// the minute tick, a reminder's time, or the phone restarted, the app was updated or the clock or
// zone changed
class SurfacesReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            SurfaceTicks.ACTION_TICK -> PrayerWidget.tick(context)
            SurfaceTicks.ACTION_START -> CountdownNotification.clearPrayer(context)
            else -> PrayerWidget.refresh(context)
        }
        CountdownNotification.sync(context, alert = intent.action == SurfaceTicks.ACTION_START)
        SurfaceTicks.arm(context)
    }
}
