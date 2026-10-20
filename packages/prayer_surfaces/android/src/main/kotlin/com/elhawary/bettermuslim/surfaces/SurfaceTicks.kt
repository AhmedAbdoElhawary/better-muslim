package com.elhawary.bettermuslim.surfaces

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

// the minute tick at the next moment anything shown changes (contracts/native-surfaces.md), and
// the alarm at the next countdown window's start
object SurfaceTicks {
    const val ACTION_TICK = "com.elhawary.bettermuslim.surfaces.TICK"
    const val ACTION_WINDOW = "com.elhawary.bettermuslim.surfaces.WINDOW"

    fun arm(context: Context) {
        val data = SurfaceData.load(context)
        val now = System.currentTimeMillis()
        val alarms = context.getSystemService(AlarmManager::class.java)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()

        val showing = data != null && CountdownNotification.shown(context, data, now) != null
        if (data == null || now >= data.until || (PrayerWidget.ids(context).isEmpty() && !showing)) {
            alarms.cancel(intent(context, ACTION_TICK))
        } else if (exact) {
            // not wakeup: a sleeping screen shows nothing, the tick waits for it to turn on
            alarms.setExact(AlarmManager.RTC, data.nextRedraw(now), intent(context, ACTION_TICK))
        } else {
            alarms.set(AlarmManager.RTC, data.nextRedraw(now), intent(context, ACTION_TICK))
        }

        // wakeup, the countdown shows on a sleeping phone too. isha's starts at maghrib's second
        val start = data?.countdowns?.map { it.getLong("start") }?.filter { it > now }?.minOrNull()
        if (start == null) {
            alarms.cancel(intent(context, ACTION_WINDOW))
        } else if (exact) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, start, intent(context, ACTION_WINDOW))
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, start, intent(context, ACTION_WINDOW))
        }
    }

    private fun intent(context: Context, action: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, SurfacesReceiver::class.java).setAction(action),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}
