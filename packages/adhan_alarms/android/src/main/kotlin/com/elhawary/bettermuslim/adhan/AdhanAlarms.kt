package com.elhawary.bettermuslim.adhan

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

// the adhan alarms dart hands over, kept in private preferences so a restart can set them again
object AdhanAlarms {
    const val ACTION_FIRE = "com.elhawary.bettermuslim.adhan.FIRE"
    const val EXTRA_ID = "id"

    private const val PREFS = "adhan_alarms"
    private const val KEY = "entries"

    fun schedule(context: Context, entries: List<Map<String, Any?>>) {
        cancelAll(context)
        val saved = JSONArray(entries.map { JSONObject(it) })
        prefs(context).edit().putString(KEY, saved.toString()).apply()
        for (i in 0 until saved.length()) set(context, saved.getJSONObject(i))
    }

    fun cancelAll(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        for (entry in load(context)) alarms.cancel(fireIntent(context, entry.getInt("id")))
        prefs(context).edit().remove(KEY).apply()
    }

    // android drops every alarm on restart and on update
    fun restore(context: Context) {
        val now = System.currentTimeMillis()
        for (entry in load(context)) if (entry.getLong("atMillis") > now) set(context, entry)
    }

    fun entry(context: Context, id: Int): JSONObject? = load(context).firstOrNull { it.getInt("id") == id }

    // silent, vibrate and do not disturb keep the adhan quiet, as ios does by itself (FR-022)
    fun canSound(context: Context): Boolean {
        val audio = context.getSystemService(AudioManager::class.java)
        val notifications = context.getSystemService(NotificationManager::class.java)
        return audio.ringerMode == AudioManager.RINGER_MODE_NORMAL &&
            notifications.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALL
    }

    private fun set(context: Context, entry: JSONObject) {
        val alarms = context.getSystemService(AlarmManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarms.canScheduleExactAlarms()) return
        alarms.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            entry.getLong("atMillis"),
            fireIntent(context, entry.getInt("id")),
        )
    }

    private fun fireIntent(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, AdhanReceiver::class.java).setAction(ACTION_FIRE).putExtra(EXTRA_ID, id),
        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
    )

    private fun load(context: Context): List<JSONObject> {
        val saved = JSONArray(prefs(context).getString(KEY, "[]"))
        return List(saved.length()) { saved.getJSONObject(it) }
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
