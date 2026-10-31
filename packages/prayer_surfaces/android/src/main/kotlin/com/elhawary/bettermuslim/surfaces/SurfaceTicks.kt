package com.elhawary.bettermuslim.surfaces

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

// the minute tick at the next moment anything shown changes (contracts/native-surfaces.md), and
// the alarm at the shown countdown's prayer time, where it rolls to the next
object SurfaceTicks {
    const val ACTION_TICK = "com.elhawary.bettermuslim.surfaces.TICK"
    const val ACTION_ROLL = "com.elhawary.bettermuslim.surfaces.ROLL"

    fun arm(context: Context) {
        val data = SurfaceData.load(context)
        val now = System.currentTimeMillis()
        val alarms = context.getSystemService(AlarmManager::class.java)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()

        val shown = data?.let { CountdownNotification.shown(context, it, now) }
        if (data == null || now >= data.until || (PrayerWidget.ids(context).isEmpty() && shown == null)) {
            alarms.cancel(intent(context, ACTION_TICK))
        } else if (exact) {
            // not wakeup: a sleeping screen shows nothing, the tick waits for it to turn on
            alarms.setExact(AlarmManager.RTC, data.nextRedraw(now), intent(context, ACTION_TICK))
        } else {
            alarms.set(AlarmManager.RTC, data.nextRedraw(now), intent(context, ACTION_TICK))
        }

        // wakeup, so a sleeping phone's lock screen shows the next prayer right away
        val roll = shown?.getLong("at")
        if (roll == null) {
            alarms.cancel(intent(context, ACTION_ROLL))
        } else if (exact) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, roll, intent(context, ACTION_ROLL))
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, roll, intent(context, ACTION_ROLL))
        }
    }

    private fun intent(context: Context, action: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, SurfacesReceiver::class.java).setAction(action),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}
