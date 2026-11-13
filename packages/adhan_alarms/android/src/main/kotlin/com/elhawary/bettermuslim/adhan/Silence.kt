package com.elhawary.bettermuslim.adhan

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

// do not disturb after a prayer's sound until its minutes are over. it ends with its own alarm, so a
// new schedule from dart never leaves the phone silent, and only a do not disturb the app turned on
object Silence {
    const val ACTION_END = "com.elhawary.bettermuslim.adhan.SILENCE_END"

    private const val PREFS = "adhan_silence"
    private const val KEY_UNTIL = "until"

    fun canSilence(context: Context): Boolean =
        context.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted

    fun openAccess(context: Context) {
        context.startActivity(
            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    fun start(context: Context, until: Long) {
        if (until <= System.currentTimeMillis() || !canSilence(context)) return
        val notifications = context.getSystemService(NotificationManager::class.java)
        val ours = prefs(context).getLong(KEY_UNTIL, 0) > 0

        // turned on by hand, it stays as it is
        if (!ours && notifications.currentInterruptionFilter != NotificationManager.INTERRUPTION_FILTER_ALL) return
        notifications.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
        prefs(context).edit().putLong(KEY_UNTIL, until).apply()
        setEnd(context, until)
    }

    fun end(context: Context) {
        if (prefs(context).getLong(KEY_UNTIL, 0) == 0L) return
        prefs(context).edit().remove(KEY_UNTIL).apply()
        context.getSystemService(AlarmManager::class.java).cancel(endIntent(context))
        val notifications = context.getSystemService(NotificationManager::class.java)
        if (canSilence(context) &&
            notifications.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_PRIORITY
        ) {
            notifications.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
        }
    }

    // a restart drops the end's alarm, a clock moved by hand can put the end behind
    fun restore(context: Context) {
        val until = prefs(context).getLong(KEY_UNTIL, 0)
        if (until == 0L) return
        if (until <= System.currentTimeMillis()) end(context) else setEnd(context, until)
    }

    private fun setEnd(context: Context, until: Long) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarms.canScheduleExactAlarms()) {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, until, endIntent(context))
        } else {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, until, endIntent(context))
        }
    }

    private fun endIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent(context, AdhanReceiver::class.java).setAction(ACTION_END),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
