package com.elhawary.bettermuslim.adhan

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.elhawary.bettermuslim.MainActivity
import com.elhawary.bettermuslim.R
import org.json.JSONObject

// the adhan alarm went off, or the phone restarted or the app was updated
class AdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED, Intent.ACTION_MY_PACKAGE_REPLACED -> AdhanAlarms.restore(context)
            AdhanAlarms.ACTION_FIRE -> {
                val entry = AdhanAlarms.entry(context, intent.getIntExtra(AdhanAlarms.EXTRA_ID, -1)) ?: return
                if (AdhanAlarms.canSound(context)) {
                    AdhanService.play(context, entry, 0)
                } else {
                    postPlain(context, entry, markPrayed = true)
                }
            }
        }
    }

    companion object {
        const val ACTION_OPEN = "com.elhawary.bettermuslim.adhan.OPEN"
        const val EXTRA_PAYLOAD = "payload"

        // quiet, the channel's clip is for the path without exact alarms (FR-022, FR-023)
        @SuppressLint("MissingPermission")
        fun postPlain(context: Context, entry: JSONObject, markPrayed: Boolean) {
            val manager = NotificationManagerCompat.from(context)
            if (!manager.areNotificationsEnabled()) return
            val builder = NotificationCompat.Builder(context, entry.getString("channel"))
                .setSmallIcon(R.drawable.ic_notification)
                .setColor(ContextCompat.getColor(context, R.color.notification_accent))
                .setContentTitle(entry.getString("title"))
                .setContentText(entry.getString("body"))
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setSilent(true)
                .setAutoCancel(true)
                .setContentIntent(openIntent(context, entry))
            if (markPrayed) {
                builder.addAction(
                    R.drawable.ic_adhan_check,
                    entry.getJSONObject("actions").getString("markPrayed"),
                    MarkPrayedReceiver.intent(context, entry),
                )
            }
            manager.notify(entry.getInt("id"), builder.build())
        }

        fun openIntent(context: Context, entry: JSONObject): PendingIntent = PendingIntent.getActivity(
            context,
            entry.getInt("id"),
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_OPEN)
                .putExtra(EXTRA_PAYLOAD, entry.getString("payload"))
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
