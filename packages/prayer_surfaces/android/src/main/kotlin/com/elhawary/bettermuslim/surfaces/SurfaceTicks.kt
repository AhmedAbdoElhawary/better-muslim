package com.elhawary.bettermuslim.surfaces

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

// the minute tick at the next moment anything shown changes (contracts/native-surfaces.md), and
// the alarm at the next reminder, where its countdown appears
object SurfaceTicks {
    const val ACTION_TICK = "com.elhawary.bettermuslim.surfaces.TICK"
    const val ACTION_START = "com.elhawary.bettermuslim.surfaces.START"

    fun arm(context: Context) {
        val data = SurfaceData.load(context)
        val now = System.currentTimeMillis()
        val alarms = context.getSystemService(AlarmManager::class.java)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()

        val shown = data?.let { CountdownNotification.shown(it, now) }
        if (data == null || now >= data.until || (PrayerWidget.ids(context).isEmpty() && shown == null)) {
            alarms.cancel(intent(context, ACTION_TICK))
        } else if (exact) {
            // not wakeup: a sleeping screen shows nothing, the tick waits for it to turn on
            alarms.setExact(AlarmManager.RTC, data.nextRedraw(now), intent(context, ACTION_TICK))
        } else {
            alarms.set(AlarmManager.RTC, data.nextRedraw(now), intent(context, ACTION_TICK))
        }

        // an alarm clock, oppo gives exact alarms a window of up to an hour
        val start = data?.nextStart(now)
        if (start == null) {
            alarms.cancel(intent(context, ACTION_START))
        } else if (exact) {
            alarms.setAlarmClock(
                AlarmManager.AlarmClockInfo(start, PrayerWidget.open(context, PrayerWidget.HOME)),
                intent(context, ACTION_START),
            )
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, start, intent(context, ACTION_START))
        }
    }

    private fun intent(context: Context, action: String): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, SurfacesReceiver::class.java).setAction(action),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )
}
