package com.elhawary.bettermuslim.adhan

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationManagerCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

// mark prayed from the media or the plain adhan notification, without opening the app (FR-018)
class MarkPrayedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val payload = intent.getStringExtra(AdhanReceiver.EXTRA_PAYLOAD) ?: return
        val id = intent.getIntExtra(AdhanAlarms.EXTRA_ID, -1)
        val pending = goAsync()
        val app = context.applicationContext
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(app)
        loader.ensureInitializationComplete(app, null)

        // the same write as the app's, through dart and the encrypted store (research R5)
        val engine = FlutterEngine(app)
        val handler = Handler(Looper.getMainLooper())
        var finished = false
        fun finish() {
            if (finished) return
            finished = true
            handler.removeCallbacksAndMessages(null)
            engine.destroy()
            if (AdhanService.playingId() == id) {
                AdhanService.current?.markPrayed(id)
            } else {
                NotificationManagerCompat.from(app).cancel(id)
            }
            pending.finish()
        }
        MethodChannel(engine.dartExecutor.binaryMessenger, "better_muslim/adhan/background")
            .setMethodCallHandler { call, result ->
                result.success(null)
                if (call.method == "done") handler.post { finish() }
            }
        handler.postDelayed({ finish() }, TIMEOUT_MILLIS)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                loader.findAppBundlePath(),
                "package:better_muslim/features/notifications/data/background.dart",
                "markPrayedInBackground",
            ),
            listOf(payload),
        )
    }

    companion object {
        // a receiver gets about 30 s, the engine is gone well before
        private const val TIMEOUT_MILLIS = 20_000L

        fun intent(context: Context, entry: JSONObject): PendingIntent = PendingIntent.getBroadcast(
            context,
            entry.getInt("id"),
            Intent(context, MarkPrayedReceiver::class.java)
                .putExtra(AdhanReceiver.EXTRA_PAYLOAD, entry.getString("payload"))
                .putExtra(AdhanAlarms.EXTRA_ID, entry.getInt("id")),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
