package com.elhawary.bettermuslim

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.os.Build
import android.os.IBinder
import io.flutter.plugin.common.MethodChannel

// keeps a download going with the app in the background, its notification is the bar with pause
// and cancel (spec 026). the dart side runs the download, this only shows it
class DownloadService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // android wants startForeground soon after the start, even when the download already ended
        val (id, notification) = running.entries.firstOrNull()?.toPair() ?: (lastId to lastNotification)
        if (notification != null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(id, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            } else {
                startForeground(id, notification)
            }
            foregroundId = id
        }
        if (running.isEmpty()) {
            stopForeground(Service.STOP_FOREGROUND_DETACH)
            stopSelf()
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        service = null
        super.onDestroy()
    }

    override fun onCreate() {
        super.onCreate()
        service = this
    }

    companion object {
        private const val CHANNEL = "downloads"

        // past the download ids, so a failure is never taken down with the service's notification
        private const val FAILED_OFFSET = 0x10000

        var channel: MethodChannel? = null

        private val running = linkedMapOf<Int, Notification>()
        private var lastId = 0
        private var lastNotification: Notification? = null
        private var foregroundId: Int? = null
        private var service: DownloadService? = null

        fun show(context: Context, arguments: Map<String, Any?>) {
            val id = arguments["id"] as Int
            val paused = arguments["paused"] as Boolean
            (arguments["channel"] as String?)?.let { channelName = it }
            val notification = build(context, id, arguments, paused)
            val manager = context.getSystemService(NotificationManager::class.java)
            manager.cancel(id + FAILED_OFFSET)
            if (paused) {
                running.remove(id)
                manager.notify(id, notification)
                handOver(context, manager, id)
                return
            }
            val started = running.isNotEmpty()
            running[id] = notification
            lastId = id
            lastNotification = notification
            manager.notify(id, notification)
            if (!started && service == null) {
                try {
                    context.startForegroundService(Intent(context, DownloadService::class.java))
                } catch (_: Exception) {
                    // a start from the background can be refused, the notification still shows
                }
            }
        }

        fun end(context: Context, id: Int, failed: String?) {
            val manager = context.getSystemService(NotificationManager::class.java)
            running.remove(id)
            handOver(context, manager, id)
            manager.cancel(id)
            if (failed != null) {
                manager.notify(
                    id + FAILED_OFFSET,
                    Notification.Builder(context, channelOf(context))
                        .setSmallIcon(icon(context))
                        .setContentTitle(failed)
                        .setContentIntent(openApp(context))
                        .setAutoCancel(true)
                        .build(),
                )
            }
        }

        // the service's notification goes to the next running download, or the service stops
        private fun handOver(context: Context, manager: NotificationManager, id: Int) {
            val current = service ?: return
            if (foregroundId != id) return
            val next = running.entries.firstOrNull()
            if (next == null) {
                current.stopForeground(Service.STOP_FOREGROUND_DETACH)
                current.stopSelf()
                foregroundId = null
                return
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                current.startForeground(next.key, next.value, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            } else {
                current.startForeground(next.key, next.value)
            }
            foregroundId = next.key
        }

        private fun build(context: Context, id: Int, arguments: Map<String, Any?>, paused: Boolean): Notification {
            val progress = arguments["progress"] as Int?
            val builder = Notification.Builder(context, channelOf(context))
                .setSmallIcon(icon(context))
                .setContentTitle(arguments["title"] as String?)
                .setContentText(arguments["text"] as String?)
                .setSubText(arguments["percent"] as String?)
                .setContentIntent(openApp(context))
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setCategory(Notification.CATEGORY_PROGRESS)
                .setShowWhen(false)
                .setProgress(1000, progress ?: 0, progress == null && !paused)
                .addAction(action(context, id, if (paused) "resume" else "pause", arguments))
                .addAction(action(context, id, "cancel", arguments))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            return builder.build()
        }

        private fun action(context: Context, id: Int, name: String, arguments: Map<String, Any?>) =
            Notification.Action.Builder(
                Icon.createWithResource(context, icon(context)),
                arguments[name] as String?,
                PendingIntent.getBroadcast(
                    context,
                    // one per download and button, or the extras of one would replace another's
                    id * 4 + listOf("pause", "resume", "cancel").indexOf(name),
                    Intent(context, DownloadActionReceiver::class.java)
                        .putExtra("id", id)
                        .putExtra("action", name),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            ).build()

        private fun openApp(context: Context): PendingIntent? =
            context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
                PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE)
            }

        // dart sends its name in the app's language on each show
        private var channelName = "Downloads"

        // high so it pops up once when it starts, the updates after it are quiet
        private fun channelOf(context: Context): String {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(CHANNEL)?.name != channelName) {
                manager.createNotificationChannel(
                    NotificationChannel(CHANNEL, channelName, NotificationManager.IMPORTANCE_HIGH).apply {
                        setSound(null, null)
                        enableVibration(false)
                    },
                )
            }
            return CHANNEL
        }

        // the icon lives in packages/adhan_alarms, the app's R doesn't carry a library's resources
        private fun icon(context: Context): Int =
            context.resources.getIdentifier("ic_notification", "drawable", context.packageName)
    }
}

class DownloadActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra("id", 0)
        val action = intent.getStringExtra("action") ?: return
        val channel = DownloadService.channel
        // the app is gone and its download with it
        if (channel == null) {
            DownloadService.end(context, id, null)
            return
        }
        channel.invokeMethod("action", mapOf("id" to id, "action" to action))
    }
}
