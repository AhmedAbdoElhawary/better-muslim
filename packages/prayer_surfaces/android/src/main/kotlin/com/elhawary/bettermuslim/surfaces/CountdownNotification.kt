package com.elhawary.bettermuslim.surfaces

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject

// the reminder before a prayer: an ongoing countdown as 5.3's card, counted by the system to the
// second (research R9). it shows with the app open too, and the system takes it away at the prayer
// time. it posts on its prayer's silent channel, adhan_alarms plays its takbir or tone at the same
// moment. no android 16 live update, a promoted one can't have its own layout (specs/028)
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
        // it sits on the shade's own background, so the phone's mode picks, the next tick follows a switch
        val palette = data.palette(!isNight(context))
        val painter = CountdownPainter(context, data, entry, palette)
        val builder = Notification.Builder(context, channel)
            .setSmallIcon(smallIcon(context))
            .setColor(palette.color(context, "gold"))
            // the lock screen reads these when it hides what notifications say
            .setContentTitle(entry.getString("nameTime"))
            .setContentText(data.text("liveNext"))
            .setShowWhen(false)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(views(context, R.layout.surfaces_countdown_row, painter.row(), data, entry, palette, now))
            .setCustomBigContentView(views(context, R.layout.surfaces_countdown_card, painter.card(), data, entry, palette, now))
            .setTimeoutAfter(at - now)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(PrayerWidget.open(context, PrayerWidget.HOME))
        // only its alarm makes a sound, not a swiped one coming back with the next tick. the platform
        // builder has no setSilent, a child of a group with no summary never alerts
        if (!alert) builder.setGroup(QUIET_GROUP).setGroupAlertBehavior(Notification.GROUP_ALERT_SUMMARY)
        return builder.build()
    }

    // the picture and the chronometer over its end, the right one in english, the left in arabic
    private fun views(context: Context, layout: Int, picture: Bitmap, data: SurfaceData, entry: JSONObject, palette: Palette, now: Long): RemoteViews {
        val views = RemoteViews(context.packageName, layout)
        views.setImageViewBitmap(R.id.surfaces_countdown_picture, picture)
        views.setContentDescription(R.id.surfaces_countdown_picture, data.spoken(entry, now))
        val timer = if (data.isArabic) R.id.surfaces_timer_left else R.id.surfaces_timer_right
        views.setViewVisibility(timer, View.VISIBLE)
        views.setChronometer(timer, SystemClock.elapsedRealtime() + entry.getLong("at") - now, null, true)
        views.setChronometerCountDown(timer, true)
        views.setTextColor(timer, palette.color(context, "live"))
        return views
    }

    // milestone 5's icon, it lives in packages/adhan_alarms
    private fun smallIcon(context: Context): Int =
        context.resources.getIdentifier("ic_notification", "drawable", context.packageName)
            .takeIf { it != 0 } ?: context.applicationInfo.icon
}
