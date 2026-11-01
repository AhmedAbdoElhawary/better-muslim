package com.elhawary.bettermuslim.surfaces

import android.content.Context
import android.content.res.Configuration
import org.json.JSONObject
import java.io.File
import java.io.IOException
import kotlin.math.roundToLong

// surfaces.json as the app writes it (contracts/surface-data.md). every text is final, only the
// countdown numbers and the shares are worked out here, as the ios extension does
class SurfaceData(private val json: JSONObject) {
    val version get() = json.optInt("version")
    val place get() = json.optBoolean("place")
    val isArabic get() = json.optString("language") == "ar"
    val eastern get() = json.optBoolean("eastern")
    val countdown get() = json.optBoolean("countdown")
    val mode get() = json.optString("mode")
    val until get() = json.optLong("until")
    val texts: JSONObject get() = json.getJSONObject("texts")
    val entries: List<JSONObject> = json.optJSONArray("entries").let { array ->
        List(array?.length() ?: 0) { array!!.getJSONObject(it) }
    }

    fun text(key: String): String = texts.optString(key)

    // the entry's light or dark, follow sky already worked out per entry by the app
    fun palette(entry: JSONObject): Palette = palette(entry.optBoolean("light"))

    fun palette(light: Boolean) = Palette(json.optJSONObject("colors")?.optJSONObject(if (light) "light" else "dark"))

    fun entryAt(now: Long): JSONObject? = entries.lastOrNull { it.getLong("from") <= now }

    fun minutesLeft(entry: JSONObject, now: Long): Long =
        Math.floorDiv(entry.getLong("at") - now, MINUTE).coerceAtLeast(0)

    // "1:23", the countdowns' h:mm
    fun hm(entry: JSONObject, now: Long): String {
        val minutes = minutesLeft(entry, now)
        return digits("${minutes / 60}:${(minutes % 60).toString().padStart(2, '0')}")
    }

    fun inDuration(entry: JSONObject, now: Long): String = text("inDuration").replace("{duration}", hm(entry, now))

    // home's bar share, null without the period's start
    fun barShare(entry: JSONObject, now: Long): Float? {
        if (entry.isNull("barFrom")) return null
        val from = entry.getLong("barFrom")
        val at = entry.getLong("at")
        if (at <= from) return null
        return ((now - from).toFloat() / (at - from)).coerceIn(0f, 1f)
    }

    // home's sun share, only between sunrise and maghrib
    fun sunShare(entry: JSONObject, now: Long): Float? {
        if (entry.isNull("sunrise") || entry.isNull("maghrib")) return null
        val sunrise = entry.getLong("sunrise")
        val maghrib = entry.getLong("maghrib")
        if (maghrib <= sunrise || now < sunrise || now > maghrib) return null
        return ((now - sunrise).toDouble() / (maghrib - sunrise) * 1000).roundToLong() / 1000f
    }

    // the prayer, the time left, its time and the place, as one line for talkback
    fun spoken(entry: JSONObject, now: Long): String {
        val minutes = minutesLeft(entry, now)
        val left = text("timeLeft")
            .replace("{hours}", digits("${minutes / 60}"))
            .replace("{minutes}", digits("${minutes % 60}"))
            .replace("{prayer}", entry.getString("name"))
        return "$left, ${entry.getString("timeCity")}"
    }

    // the next moment anything shown changes: the h:mm flip, the next entry or until
    fun nextRedraw(now: Long): Long {
        val moments = mutableListOf(until)
        entryAt(now)?.let { moments += it.getLong("at") - minutesLeft(it, now) * MINUTE }
        entries.firstOrNull { it.getLong("from") > now }?.let { moments += it.getLong("from") }
        return moments.filter { it > now }.minOrNull() ?: until
    }

    fun digits(text: String): String {
        if (!eastern) return text
        return text.map { if (it in '0'..'9') '٠' + (it - '0') else it }.joinToString("")
    }

    companion object {
        private const val NAME = "surfaces.json"
        private const val MINUTE = 60_000L

        // filesDir, which allowBackup and data_extraction_rules keep out of every backup
        private fun file(context: Context) = File(context.filesDir, NAME)

        fun load(context: Context): SurfaceData? {
            val file = file(context)
            if (!file.exists()) return null
            return runCatching { SurfaceData(JSONObject(file.readText())) }.getOrNull()
        }

        // false when the file already holds the same, so no widget redraws for nothing (R5)
        fun update(context: Context, json: String, force: Boolean): Boolean {
            val file = file(context)
            if (!force && file.exists() && file.readText() == json) return false
            val temp = File(context.filesDir, "$NAME.tmp")
            temp.writeText(json)
            // a rename is atomic, a reader never sees half a file
            if (!temp.renameTo(file)) throw IOException("rename")
            return true
        }
    }
}

// what a surface shows at a moment. a null message means no file yet, the string resource then
sealed interface SurfaceState {
    data class NoPlace(val message: String?) : SurfaceState

    data class Outdated(val message: String?) : SurfaceState

    data class Ready(val data: SurfaceData, val entry: JSONObject) : SurfaceState

    companion object {
        fun of(data: SurfaceData?, now: Long): SurfaceState {
            if (data == null) return NoPlace(null)
            // an app newer than this code may write a shape it can't read
            if (data.version > 2) return Outdated(null)
            if (!data.place) return NoPlace(data.text("noPlace"))
            val entry = data.entryAt(now)
            if (now >= data.until || entry == null) return Outdated(data.text("outdated"))
            return Ready(data, entry)
        }
    }
}

// the theme's colors as the app wrote them. no file yet, the phone's own until the app writes
class Palette(private val roles: JSONObject?) {
    fun color(context: Context, role: String): Int {
        if (roles != null && roles.has(role)) return roles.getLong(role).toInt()
        val night = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        val surface = if (night) android.R.color.black else android.R.color.white
        val ink = if (night) android.R.color.white else android.R.color.black
        return context.getColor(if (role in SURFACES) surface else ink)
    }

    companion object {
        private val SURFACES = setOf("top", "middle", "bottom", "deep", "container", "outline")

        // a message has no entry: the app's mode, or the phone's when following a sky it hasn't got
        fun of(context: Context, data: SurfaceData?): Palette {
            if (data == null) return Palette(null)
            val light = when (data.mode) {
                "light" -> true
                "dark" -> false
                else -> context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK != Configuration.UI_MODE_NIGHT_YES
            }
            return data.palette(light)
        }
    }
}
