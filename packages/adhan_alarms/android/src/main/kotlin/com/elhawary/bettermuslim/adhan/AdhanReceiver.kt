package com.elhawary.bettermuslim.adhan

import android.annotation.SuppressLint
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

// a prayer's, a reminder's or a nudge's alarm went off, a prayer's notification was swiped, or the
// phone restarted or the app was updated
class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> AdhanAlarms.restore(context)
            AdhanAlarms.ACTION_FIRE -> {
                val entry = AdhanAlarms.entry(context, intent.getIntExtra(AdhanAlarms.EXTRA_ID, -1)) ?: return
                when (entry.optString("kind")) {
                    // prayer_surfaces posts the countdown, this is only its sound
                    "reminder" -> {}
                    "azkar" -> postAzkar(context, entry)
                    else -> {
                        clearPrayer(context)
                        if (entry.optBoolean("full") && AdhanAlarms.canSound(context)) {
                            AdhanService.play(context, entry, 0)
                        } else {
                            // an adhan that can't play is quiet
                            postPrayer(context, entry, quiet = entry.optBoolean("adhan"))
                        }
                    }
                }
                playClip(context, entry)
            }
            ACTION_SWIPED -> postPrayer(context, JSONObject(intent.getStringExtra(EXTRA_ENTRY)!!), quiet = true)
        }
    }

    // nothing when its notification can't show or the phone is silent, vibrate or do not disturb
    private fun playClip(context: Context, entry: JSONObject) {
        val clip = entry.optString("clip")
        val manager = context.getSystemService(NotificationManager::class.java)
        val channel = manager.getNotificationChannel(entry.getString("channel"))
        if (clip.isEmpty() || !AdhanAlarms.canSound(context) || !manager.areNotificationsEnabled()) return
        if (channel == null || channel.importance == NotificationManager.IMPORTANCE_NONE) return
        val pending = goAsync()
        ClipPlayer.play(context, clip) { pending.finish() }
    }

    // the nudge after fajr and asr, it goes when the next one comes
    @SuppressLint("MissingPermission")
    private fun postAzkar(context: Context, entry: JSONObject) {
        val manager = NotificationManagerCompat.from(context)
        if (!manager.areNotificationsEnabled()) return
        val builder = NotificationCompat.Builder(context, entry.getString("channel"))
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.notification_accent))
            .setContentTitle(entry.getString("title"))
            .setContentText(entry.getString("body"))
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(openIntent(context, entry))
        if (entry.has("lasts")) builder.setTimeoutAfter(entry.getLong("lasts"))
        manager.notify(entry.getInt("id"), builder.build())
    }

    companion object {
        const val ACTION_OPEN = "com.elhawary.bettermuslim.adhan.OPEN"
        const val EXTRA_PAYLOAD = "payload"
        private const val ACTION_SWIPED = "com.elhawary.bettermuslim.adhan.SWIPED"
        private const val EXTRA_ENTRY = "entry"
        private const val CHANNELS = "adhan_"

        // one prayer notification at a time, whichever prayer it was
        fun clearPrayer(context: Context) {
            val manager = context.getSystemService(NotificationManager::class.java)
            for (shown in manager.activeNotifications) {
                if (shown.notification.channelId.startsWith(CHANNELS)) manager.cancel(shown.id)
            }
        }

        // stays until it is answered or the next prayer takes its place. quiet after the full adhan,
        // on a silent phone or without exact alarms, its tap has no adhan left to open
        @SuppressLint("MissingPermission")
        fun postPrayer(context: Context, entry: JSONObject, quiet: Boolean) {
            val manager = NotificationManagerCompat.from(context)
            if (!manager.areNotificationsEnabled()) return
            if (quiet) entry.put("payload", entry.getString("quietPayload"))
            val actions = entry.getJSONObject("actions")
            val builder = NotificationCompat.Builder(context, entry.getString("channel"))
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(ContextCompat.getColor(context, R.color.notification_accent))
                .setContentTitle(entry.getString("title"))
                .setContentText(entry.getString("body"))
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setSilent(quiet)
                .setOngoing(true)
                .setContentIntent(openIntent(context, entry))
                .setDeleteIntent(swipedIntent(context, entry))
                .addAction(
                    R.drawable.ic_adhan_check,
                    actions.getString("markPrayed"),
                    MarkPrayedReceiver.intent(context, entry),
                )
                .addAction(
                    R.drawable.ic_adhan_check,
                    actions.getString("addToQada"),
                    MarkPrayedReceiver.qadaIntent(context, entry),
                )
            manager.notify(entry.getInt("id"), builder.build())
        }

        // android 14 lets an unlocked phone swipe an ongoing notification away, so it comes back.
        // the entry goes with it, the alarms' list drops a prayer once its time has passed
        private fun swipedIntent(context: Context, entry: JSONObject): PendingIntent = PendingIntent.getBroadcast(
            context,
            entry.getInt("id"),
            Intent(context, AdhanReceiver::class.java)
                .setAction(ACTION_SWIPED)
                .putExtra(EXTRA_ENTRY, entry.toString()),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        // the app's own activity, this package doesn't know its class
        fun openIntent(context: Context, entry: JSONObject): PendingIntent = PendingIntent.getActivity(
            context,
            entry.getInt("id"),
            context.packageManager.getLaunchIntentForPackage(context.packageName)!!
                .setAction(ACTION_OPEN)
                .putExtra(EXTRA_PAYLOAD, entry.getString("payload"))
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
