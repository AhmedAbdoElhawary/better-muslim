package com.elhawary.bettermuslim.surfaces

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import org.json.JSONObject

// the ongoing countdown to the next prayer while the app is off screen, counted by the system to
// the second (research R9). it rolls to the next one at each prayer time
object CountdownNotification {
    private const val CHANNEL = "prayer_countdown"
    private const val ID = 7300
    private const val PREFS = "prayer_surfaces"
    private const val ON_SCREEN = "on_screen"

    // the app's activity started or stopped. a reboot or an update leaves it off screen
    fun onScreen(context: Context, on: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putBoolean(ON_SCREEN, on).apply()
        sync(context)
        SurfaceTicks.arm(context)
    }

    // with notifications or the channel off there's no countdown, the widget still works (FR-021)
    fun sync(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val data = SurfaceData.load(context)
        val now = System.currentTimeMillis()
        val entry = data?.let { shown(context, it, now) }
        if (data == null || entry == null || !allowed(context, data)) {
            manager.cancel(ID)
            return
        }
        manager.notify(ID, build(context, data, entry, now))
    }

    // the entry in force names the next prayer, none while the app is on screen
    fun shown(context: Context, data: SurfaceData, now: Long): JSONObject? {
        if (!data.place || !data.countdown) return null
        if (context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(ON_SCREEN, false)) return null
        if (now >= data.until) return null
        return data.entryAt(now)
    }

    // made or renamed each time, so the app's language reaches the phone's settings
    private fun allowed(context: Context, data: SurfaceData): Boolean {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false
        val channel = NotificationChannel(CHANNEL, data.text("channel"), NotificationManager.IMPORTANCE_LOW).apply {
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
        return manager.getNotificationChannel(CHANNEL).importance != NotificationManager.IMPORTANCE_NONE
    }

    private fun build(context: Context, data: SurfaceData, entry: JSONObject, now: Long): Notification {
        val at = entry.getLong("at")
        val builder = Notification.Builder(context, CHANNEL)
            .setSmallIcon(smallIcon(context))
            // the theme's dark palette, as the ios lock screen
            .setColor(data.palette(false).color(context, "gold"))
            .setContentTitle(entry.getString("nameTime"))
            .setContentText(data.text("liveNext"))
            .setWhen(at)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setTimeoutAfter(at - now)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(PrayerWidget.open(context, PrayerWidget.HOME))
        val share = data.barShare(entry, now)?.let { (it * BAR).toInt() }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.BAKLAVA) {
            // a live update: the status bar chip and the lock screen. its setter and constant are api 37
            builder.addExtras(Bundle().apply { putBoolean(PROMOTED, true) })
            if (share != null) {
                builder.setStyle(
                    Notification.ProgressStyle()
                        .setProgressSegments(listOf(Notification.ProgressStyle.Segment(BAR)))
                        .setProgress(share)
                        .setProgressTrackerIcon(Icon.createWithResource(context, R.drawable.surfaces_sun).setTint(data.palette(false).color(context, "live"))),
                )
            }
        } else if (share != null) {
            builder.setProgress(BAR, share, false)
        }
        return builder.build()
    }

    // milestone 5's icon, it lives in packages/adhan_alarms
    private fun smallIcon(context: Context): Int =
        context.resources.getIdentifier("ic_notification", "drawable", context.packageName)
            .takeIf { it != 0 } ?: context.applicationInfo.icon

    private const val BAR = 1000
    private const val PROMOTED = "android.requestPromotedOngoing"
}
