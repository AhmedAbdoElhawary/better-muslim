package com.elhawary.bettermuslim.surfaces

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import org.json.JSONObject
import kotlin.math.ceil
import kotlin.math.max

// the 5.8 tree drawn in the app's own fonts, which widget layouts can't load (research R8, Q1).
// sizes are the tree's in dp, never scaled by the phone's font size (FR-029)
class WidgetPainter(private val context: Context, widthDp: Float, heightDp: Float) {
    enum class Size { FULL, BAND, ROW }

    // 2 x 2 under 3 cells wide, 4 x 1 under 2 cells high, else 4 x 2 (FR-011)
    val size = when {
        widthDp < NARROW_DP -> Size.BAND
        heightDp < SHORT_DP -> Size.ROW
        else -> Size.FULL
    }

    private val density = context.resources.displayMetrics.density
    private val width = max(1, (widthDp * density).toInt())
    private val height = max(1, (heightDp * density).toInt())

    // where the five click cells start, the band above them opens home
    val rowTop: Int = when (size) {
        Size.FULL -> dp(BAND_DP).toInt()
        Size.ROW -> 0
        Size.BAND -> height
    }
    val rowSide: Int = dp(10f).toInt()

    class Countdown(val bitmap: Bitmap, val left: Int, val top: Int)

    // everything but the countdown, so it stays the same for a whole entry
    fun picture(state: SurfaceState): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val frame = RectF(0f, 0f, width.toFloat(), height.toFloat())
        val radius = dp(28f)
        canvas.save()
        canvas.clipPath(Path().apply { addRoundRect(frame, radius, radius, Path.Direction.CW) })
        canvas.drawColor(color(R.color.surfaces_surface))
        when (state) {
            is SurfaceState.Ready -> {
                val band = when (size) {
                    Size.FULL -> RectF(0f, 0f, width.toFloat(), dp(BAND_DP))
                    Size.BAND -> frame
                    Size.ROW -> null
                }
                band?.let { drawBand(canvas, it, state.data, state.entry) }
                if (size != Size.BAND) drawRow(canvas, RectF(0f, band?.bottom ?: 0f, width.toFloat(), height.toFloat()), state.data, state.entry)
            }
            else -> drawMessage(canvas, frame, message(state)!!)
        }
        canvas.restore()
        val outline = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = dp(1f)
            color = color(R.color.surfaces_outline)
        }
        val inset = dp(0.5f)
        canvas.drawRoundRect(RectF(inset, inset, width - inset, height - inset), radius - inset, radius - inset, outline)
        return bitmap
    }

    // what to do, for no place and out of date
    fun message(state: SurfaceState): String? = when (state) {
        is SurfaceState.NoPlace -> state.message ?: context.getString(R.string.surfaces_no_place)
        is SurfaceState.Outdated -> state.message ?: context.getString(R.string.surfaces_outdated)
        is SurfaceState.Ready -> null
    }

    // the h:mm alone, at the spot the band leaves for it. null when this size shows none
    fun countdown(data: SurfaceData, entry: JSONObject, now: Long): Countdown? {
        if (size == Size.ROW) return null
        val paint = text(24f, body(data, 600), color(R.color.surfaces_gold), tabular = true)
        val text = data.hm(entry, now)
        val lineHeight = dp(24f * NORMAL)
        val textWidth = ceil(paint.measureText(text)).toInt() + 1
        val bitmap = Bitmap.createBitmap(textWidth, ceil(lineHeight).toInt(), Bitmap.Config.ARGB_8888)
        drawLine(Canvas(bitmap), text, paint, 0f, 0f, lineHeight, Paint.Align.LEFT)
        val (left, top) = countdownSpot(data, entry, textWidth)
        return Countdown(bitmap, left, top)
    }

    private fun countdownSpot(data: SurfaceData, entry: JSONObject, textWidth: Int): Pair<Int, Int> {
        val side = dp(18f)
        val top = dp(14f)
        if (stacked(data, entry)) {
            // the band's left column is under the countdown when the two don't fit side by side
            val below = top + dp(12f * NORMAL) + dp(26f * MARCELLUS)
            val left = if (data.isArabic) width - side - textWidth else side
            return left.toInt() to below.toInt()
        }
        val left = if (data.isArabic) side else width - side - textWidth
        return left.toInt() to top.toInt()
    }

    private fun drawBand(canvas: Canvas, band: RectF, data: SurfaceData, entry: JSONObject) {
        val sky = Paint().apply {
            shader = LinearGradient(
                0f, band.top, 0f, band.bottom,
                intArrayOf(color(R.color.surfaces_sky_top), color(R.color.surfaces_sky_middle), color(R.color.surfaces_sky_bottom)),
                floatArrayOf(0f, 0.45f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(band, sky)

        val side = dp(18f)
        val arabic = data.isArabic
        val start = if (arabic) band.right - side else band.left + side
        val end = if (arabic) band.left + side else band.right - side
        val startAlign = if (arabic) Paint.Align.RIGHT else Paint.Align.LEFT
        val endAlign = if (arabic) Paint.Align.LEFT else Paint.Align.RIGHT

        val countdown = text(24f, body(data, 600), color(R.color.surfaces_gold), tabular = true)
        val at = text(12f, body(data, 400), color(R.color.surfaces_label), tabular = true)
        // the widest h:mm, so the city's cut doesn't move with the minutes
        val countdownWidth = countdown.measureText(data.digits("00:00"))
        val stacked = stacked(data, entry)
        val endColumn = max(countdownWidth, at.measureText(entry.getString("atTime")))
        val startWidth = (band.width() - 2 * side - if (stacked) 0f else endColumn + dp(8f)).coerceAtLeast(0f)

        var top = band.top + dp(14f)
        val label = text(12f, body(data, 400), color(R.color.surfaces_label))
        // a long city is cut with an ellipsis, never the time
        drawLine(canvas, ellipsize(data.text("nextCityShort"), label, startWidth), label, start, top, dp(12f * NORMAL), startAlign)
        top += dp(12f * NORMAL)
        val name = text(26f, display(data), color(R.color.surfaces_text))
        drawLine(canvas, entry.getString("name"), name, start, top, dp(26f * MARCELLUS), startAlign)
        top += dp(26f * MARCELLUS)

        if (stacked) {
            // the countdown's own bitmap goes here, then the time under it
            drawLine(canvas, entry.getString("atTime"), at, start, top + dp(24f * NORMAL), dp(12f * NORMAL), startAlign)
        } else {
            drawLine(canvas, entry.getString("atTime"), at, end, band.top + dp(14f) + dp(24f * NORMAL), dp(12f * NORMAL), endAlign)
        }
    }

    // grid of 5, gap 4, padding 8 10 10. past cells dimmed, the next one on its gold tint
    private fun drawRow(canvas: Canvas, area: RectF, data: SurfaceData, entry: JSONObject) {
        val row = RectF(area.left + dp(10f), area.top + if (size == Size.FULL) dp(8f) else dp(6f), area.right - dp(10f), area.bottom - if (size == Size.FULL) dp(10f) else dp(6f))
        val gap = dp(4f)
        val cellWidth = (row.width() - 4 * gap) / 5
        val strip = entry.getJSONArray("strip")
        val next = if (entry.isNull("next")) -1 else entry.getInt("next")
        val highlight = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = color(R.color.surfaces_highlight) }
        for (index in 0 until 5) {
            val cell = strip.getJSONObject(index)
            // the five run as home's strip does, from the right in arabic
            val column = if (data.isArabic) 4 - index else index
            val left = row.left + column * (cellWidth + gap)
            val box = RectF(left, row.top, left + cellWidth, row.bottom)
            val current = index == next
            if (current) canvas.drawRoundRect(box, dp(16f), dp(16f), highlight)
            val past = cell.getBoolean("past")
            val name = text(11f, body(data, if (current) 600 else 400), color(if (current) R.color.surfaces_gold else R.color.surfaces_dim))
            val time = text(14f, body(data, 500), color(if (past && !current) R.color.surfaces_dim else R.color.surfaces_text), tabular = true)
            val contentHeight = dp(11f * NORMAL) + dp(2f) + dp(14f * NORMAL)
            val top = box.centerY() - contentHeight / 2
            drawLine(canvas, ellipsize(cell.getString("name"), name, cellWidth), name, box.centerX(), top, dp(11f * NORMAL), Paint.Align.CENTER)
            drawLine(canvas, cell.getString("time"), time, box.centerX(), top + dp(11f * NORMAL) + dp(2f), dp(14f * NORMAL), Paint.Align.CENTER)
        }
    }

    // no place and out of date: the frame, the band, the mark and what to do (FR-024)
    private fun drawMessage(canvas: Canvas, frame: RectF, message: String) {
        val arabic = message.any { Character.UnicodeBlock.of(it) == Character.UnicodeBlock.ARABIC }
        if (size != Size.ROW) {
            canvas.drawPaint(
                Paint().apply {
                    shader = LinearGradient(
                        0f, 0f, 0f, frame.bottom,
                        intArrayOf(color(R.color.surfaces_sky_top), color(R.color.surfaces_sky_middle), color(R.color.surfaces_sky_bottom)),
                        floatArrayOf(0f, 0.45f, 1f),
                        Shader.TileMode.CLAMP,
                    )
                },
            )
        }
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Fonts.body(context, arabic, 500)
            textSize = dp(13f)
            color = color(R.color.surfaces_text)
        }
        val textWidth = (frame.width() - dp(32f)).toInt().coerceAtLeast(1)
        val layout = StaticLayout.Builder.obtain(message, 0, message.length, paint, textWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setMaxLines(3)
            .setEllipsize(TextUtils.TruncateAt.END)
            .build()
        val star = if (size == Size.ROW) 0f else dp(23f)
        val gap = if (size == Size.ROW) 0f else dp(10f)
        val top = frame.centerY() - (star + gap + layout.height) / 2
        if (size != Size.ROW) drawStar(canvas, frame.centerX(), top + star / 2, star)
        canvas.save()
        canvas.translate(frame.centerX() - textWidth / 2f, top + star + gap)
        layout.draw(canvas)
        canvas.restore()
    }

    // the trees' 8 point star, viewBox -11 -11 22 22, stroke 1.1 at 23
    private fun drawStar(canvas: Canvas, centerX: Float, centerY: Float, size: Float) {
        val scale = size / 22f
        val path = Path()
        STAR.forEachIndexed { index, (x, y) ->
            val px = centerX + x * scale
            val py = centerY + y * scale
            if (index == 0) path.moveTo(px, py) else path.lineTo(px, py)
        }
        path.close()
        canvas.drawPath(
            path,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.1f * scale
                strokeJoin = Paint.Join.ROUND
                color = color(R.color.surfaces_primary)
            },
        )
    }

    // the 2 x 2 band is too narrow for the name and the countdown side by side
    private fun stacked(data: SurfaceData, entry: JSONObject): Boolean {
        val name = text(26f, display(data), 0)
        val countdown = text(24f, body(data, 600), 0, tabular = true)
        val needed = name.measureText(entry.getString("name")) + dp(8f) + countdown.measureText(data.digits("00:00"))
        return needed > width - 2 * dp(18f)
    }

    // css's line box: the text centred in it, as the trees lay their spans out
    private fun drawLine(canvas: Canvas, text: String, paint: TextPaint, x: Float, top: Float, lineHeight: Float, align: Paint.Align) {
        paint.textAlign = align
        val metrics = paint.fontMetrics
        val baseline = top + (lineHeight - (metrics.descent - metrics.ascent)) / 2 - metrics.ascent
        canvas.drawText(text, x, baseline, paint)
    }

    private fun ellipsize(text: String, paint: TextPaint, width: Float): String =
        TextUtils.ellipsize(text, paint, width, TextUtils.TruncateAt.END).toString()

    private fun text(sizeDp: Float, face: Typeface, color: Int, tabular: Boolean = false) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
        typeface = face
        textSize = dp(sizeDp)
        this.color = color
        if (tabular) fontFeatureSettings = "'tnum'"
    }

    private fun body(data: SurfaceData, weight: Int) = Fonts.body(context, data.isArabic, weight)

    private fun display(data: SurfaceData) = Fonts.display(context, data.isArabic)

    private fun color(id: Int) = context.getColor(id)

    private fun dp(value: Float) = value * density

    companion object {
        private const val BAND_DP = 84f
        private const val NARROW_DP = 180f
        private const val SHORT_DP = 100f

        // css's normal line height, and the trees' 1.15 for marcellus
        private const val NORMAL = 1.2f
        private const val MARCELLUS = 1.15f

        private val STAR = listOf(
            0f to -10f, 2.93f to -7.07f, 7.07f to -7.07f, 7.07f to -2.93f, 10f to 0f, 7.07f to 2.93f,
            7.07f to 7.07f, 2.93f to 7.07f, 0f to 10f, -2.93f to 7.07f, -7.07f to 7.07f, -7.07f to 2.93f,
            -10f to 0f, -7.07f to -2.93f, -7.07f to -7.07f, -2.93f to -7.07f,
        )
    }
}

// the flutter font assets inside the apk, loaded once. the variable ones take their weight on wght
private object Fonts {
    private val cache = mutableMapOf<String, Typeface>()

    fun body(context: Context, arabic: Boolean, weight: Int): Typeface =
        load(context, if (arabic) "NotoSansArabic-Variable.ttf" else "SchibstedGrotesk-Variable.ttf", weight)

    // marcellus has one weight, reem kufi is variable
    fun display(context: Context, arabic: Boolean): Typeface =
        if (arabic) load(context, "ReemKufi-Variable.ttf", 400) else load(context, "Marcellus-Regular.ttf", null)

    private fun load(context: Context, file: String, weight: Int?): Typeface = synchronized(cache) {
        cache.getOrPut("$file$weight") {
            val builder = Typeface.Builder(context.assets, "flutter_assets/assets/fonts/$file")
            if (weight != null) builder.setFontVariationSettings("'wght' $weight")
            builder.build() ?: Typeface.DEFAULT
        }
    }
}
