package com.elhawary.bettermuslim.surfaces

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import com.elhawary.bettermuslim.surfaces.WidgetPainter.Companion.MARCELLUS
import com.elhawary.bettermuslim.surfaces.WidgetPainter.Companion.NORMAL
import org.json.JSONObject
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min

// the 5.3 tree for the countdown notification, in the app's fonts like the widget. no background,
// it sits on the shade's own. the countdown is left out, the chronometer counts it over the end
class CountdownPainter(
    private val context: Context,
    private val data: SurfaceData,
    private val entry: JSONObject,
    private val palette: Palette,
) {
    private val density = context.resources.displayMetrics.density
    private val arabic = data.isArabic

    // the shade never says its width, the picture stretches evenly to it. from android 12 the
    // system's icon column takes the start too
    private val width = with(context.resources.displayMetrics) {
        val side = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) 112f else 48f
        ((min(widthPixels, heightPixels) / density - side) * density).toInt().coerceAtLeast(1)
    }

    // beside the tile "next prayer" over the name, the countdown over the city at the end, then the
    // period's start and the next prayer's time. no bar
    fun card(): Bitmap = layer(TOP_ROW + GAP + 12f * NORMAL) { canvas ->
        drawTile(canvas, TILE, 11f, 23f, 1.1f, (TOP_ROW - TILE) / 2)
        val label = text(12.5f, body(400), color("label"))
        val city = ellipsize(data.text("city"), label, width / 2f)
        drawLine(canvas, city, label, end(), dp(COUNTDOWN_LINE), dp(12.5f * NORMAL), endAlign)

        // the name's line runs under the countdown's too
        val inner = width - dp(TILE + 12f + 8f) - max(timer(COUNTDOWN).measureText(WIDEST), label.measureText(city))
        var top = dp((TOP_ROW - 12.5f * NORMAL - NAME_LINE) / 2)
        drawLine(canvas, ellipsize(data.text("nextPrayer"), label, inner), label, start(TILE + 12f), top, dp(12.5f * NORMAL), startAlign)
        top += dp(12.5f * NORMAL)
        drawName(canvas, 24f, inner, start(TILE + 12f), top, dp(NAME_LINE))

        val ends = text(12f, body(400), color("label"), tabular = true)
        val endsTop = dp(TOP_ROW + GAP)
        val nameTime = entry.getString("nameTime")
        drawLine(canvas, nameTime, ends, end(), endsTop, dp(12f * NORMAL), endAlign)
        if (entry.isNull("barFromLabel")) return@layer
        val fromWidth = width - dp(8f) - ends.measureText(nameTime)
        drawLine(canvas, ellipsize(entry.getString("barFromLabel"), ends, fromWidth), ends, start(0f), endsTop, dp(12f * NORMAL), startAlign)
    }

    // collapsed: the small tile and the name, the countdown at the end
    fun row(): Bitmap = layer(ROW) { canvas ->
        drawTile(canvas, ROW, 9f, 18f, 1.3f, 0f)
        val inner = width - dp(ROW + 12f + 8f) - timer(ROW_COUNTDOWN).measureText(WIDEST)
        drawName(canvas, 22f, inner, start(ROW + 12f), 0f, dp(ROW))
    }

    // smaller until the whole name fits, the ellipsis only past the smallest
    private fun drawName(canvas: Canvas, size: Float, inner: Float, x: Float, top: Float, lineHeight: Float) {
        val text = entry.getString("name")
        var fit = size
        while (fit > MIN_NAME && text(fit, display(), 0).measureText(text) > inner) fit -= 1f
        val name = text(fit, display(), color("text"))
        drawLine(canvas, ellipsize(text, name, inner), name, x, top, lineHeight, startAlign)
    }

    // the trees' radial sky from the bottom, a 0.5 hairline at 18% and the star
    private fun drawTile(canvas: Canvas, size: Float, radius: Float, star: Float, stroke: Float, top: Float) {
        val left = if (arabic) width - dp(size) else 0f
        val box = RectF(left, dp(top), left + dp(size), dp(top + size))
        val sky = RadialGradient(box.centerX(), box.bottom, dp(34f * size / TILE), color("bottom"), color("top"), Shader.TileMode.CLAMP)
        canvas.drawRoundRect(box, dp(radius), dp(radius), Paint(Paint.ANTI_ALIAS_FLAG).apply { shader = sky })
        val inset = dp(0.25f)
        canvas.drawRoundRect(
            RectF(box.left + inset, box.top + inset, box.right - inset, box.bottom - inset),
            dp(radius) - inset,
            dp(radius) - inset,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(0.5f)
                color = alpha(color("text"), 0.18f)
            },
        )
        canvas.drawPath(
            starPath(box.centerX(), box.centerY(), dp(star)),
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(stroke * star / 22f)
                strokeJoin = Paint.Join.ROUND
                color = color("primary")
            },
        )
    }

    private fun layer(height: Float, draw: (Canvas) -> Unit): Bitmap {
        val bitmap = Bitmap.createBitmap(width, max(1, ceil(dp(height)).toInt()), Bitmap.Config.ARGB_8888)
        draw(Canvas(bitmap))
        return bitmap
    }

    private fun start(fromStart: Float) = if (arabic) width - dp(fromStart) else dp(fromStart)

    private fun end() = if (arabic) 0f else width.toFloat()

    private val startAlign get() = if (arabic) Paint.Align.RIGHT else Paint.Align.LEFT

    private val endAlign get() = if (arabic) Paint.Align.LEFT else Paint.Align.RIGHT

    // the chronometer's own font, in every language
    private fun timer(size: Float) = text(size, Fonts.body(context, false, 600), 0, tabular = true)

    private fun text(sizeDp: Float, face: Typeface, color: Int, tabular: Boolean = false) = textPaint(dp(sizeDp), face, color, tabular)

    private fun body(weight: Int) = Fonts.body(context, arabic, weight)

    private fun display() = Fonts.display(context, arabic)

    private fun color(role: String) = palette.color(context, role)

    private fun dp(value: Float) = value * density

    companion object {
        private const val TILE = 40f
        private const val COUNTDOWN = 28f
        private const val COUNTDOWN_LINE = COUNTDOWN * 1.1f
        private const val TOP_ROW = COUNTDOWN_LINE + 12.5f * NORMAL
        private const val NAME_LINE = 24f * MARCELLUS
        private const val GAP = 12f
        private const val ROW = 32f
        private const val ROW_COUNTDOWN = 22f
        private const val MIN_NAME = 18f

        // the reminder is 30 minutes at most, the countdown never shows hours
        private const val WIDEST = "00:00"
    }
}
