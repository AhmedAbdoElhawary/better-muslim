package com.elhawary.bettermuslim.surfaces

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import org.json.JSONObject

// the reminder before a prayer: an ongoing countdown, counted by the system to the second (research
// R9). it shows with the app open too, and the system takes it away at the prayer time. it posts on
// its prayer's silent channel, adhan_alarms plays its takbir or tone at the same moment
object CountdownNotification {
    private const val PRAYER_CHANNELS = "adhan_"
    private const val ID = 7300
    private const val QUIET_GROUP = "countdown_quiet"

    // with notifications or the channel off there's no countdown, the widget still works (FR-021)
    fun sync(context: Context, alert: Boolean = false) {
        val manager = context.getSystemService(NotificationManager::class.java)
        val data = SurfaceData.load(context)
        val now = System.currentTimeMillis()
        val entry = data?.let { shown(it, now) }
        val channel = entry?.let { channelOf(context, it.getString("prayer")) }
        if (data == null || entry == null || channel == null || !manager.areNotificationsEnabled()) {
            manager.cancel(ID)
            return
        }
        manager.notify(ID, build(context, data, entry, channel.id, now, alert))
    }

    // the entry in force names the next prayer, none before its reminder or with the reminder off
    fun shown(data: SurfaceData, now: Long): JSONObject? {
        if (!data.place) return null
        if (now >= data.until) return null
        return data.entryAt(now)?.takeIf { entry -> data.startOf(entry)?.let { now >= it } == true }
    }

    // the dev page's check on the next reminder's prayer, a phone's settings can turn a channel down
    fun importance(context: Context): Int? {
        val data = SurfaceData.load(context) ?: return null
        val now = System.currentTimeMillis()
        val entry = data.entries.firstOrNull { data.startOf(it)?.let { start -> start > now } == true }
            ?: return null
        return channelOf(context, entry.getString("prayer"))?.importance
    }

    // one prayer notification at a time, the unanswered one gives way to the next reminder
    fun clearPrayer(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        for (shown in manager.activeNotifications) {
            if (shown.id != ID && shown.notification.channelId.startsWith(PRAYER_CHANNELS)) manager.cancel(shown.id)
        }
    }

    // dart keeps one channel per prayer and deletes the others, before its first schedule there's none
    private fun channelOf(context: Context, prayer: String): NotificationChannel? =
        context.getSystemService(NotificationManager::class.java).notificationChannels
            .firstOrNull { it.id.startsWith("$PRAYER_CHANNELS${prayer}_") }
            ?.takeIf { it.importance != NotificationManager.IMPORTANCE_NONE }

    private fun build(context: Context, data: SurfaceData, entry: JSONObject, channel: String, now: Long, alert: Boolean): Notification {
        val at = entry.getLong("at")
        val builder = Notification.Builder(context, channel)
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
        // only its alarm makes a sound, not a swiped one coming back with the next tick. the platform
        // builder has no setSilent, a child of a group with no summary never alerts
        if (!alert) builder.setGroup(QUIET_GROUP).setGroupAlertBehavior(Notification.GROUP_ALERT_SUMMARY)
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
