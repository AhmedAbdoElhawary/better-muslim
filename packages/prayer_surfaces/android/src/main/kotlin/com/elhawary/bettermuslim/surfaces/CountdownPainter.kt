package com.elhawary.bettermuslim.surfaces

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.LinearGradient
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

    // the top row, the bar with its sun, and the two ends under it. no period start, no bar
    fun card(now: Long): Bitmap {
        val share = data.barShare(entry, now)
        val height = TOP_ROW + if (share == null) 0f else GAP + BAR + GAP + 12f * NORMAL
        return layer(height) { canvas ->
            val at = text(12.5f, body(400), color("label"), tabular = true)
            val atTime = entry.getString("atTime")
            val endColumn = max(timer(COUNTDOWN).measureText(WIDEST), at.measureText(atTime))
            drawTile(canvas, TILE, 11f, 23f, 1.1f, (TOP_ROW - TILE) / 2)

            val inner = width - dp(TILE + 12f + 12f) - endColumn
            var top = dp((TOP_ROW - 12.5f * NORMAL - 24f * MARCELLUS) / 2)
            val label = text(12.5f, body(400), color("label"))
            drawLine(canvas, ellipsize(data.text("liveNext"), label, inner), label, start(TILE + 12f), top, dp(12.5f * NORMAL), startAlign)
            top += dp(12.5f * NORMAL)
            val name = text(24f, display(), color("text"))
            drawLine(canvas, ellipsize(entry.getString("name"), name, inner), name, start(TILE + 12f), top, dp(24f * MARCELLUS), startAlign)
            drawLine(canvas, atTime, at, end(), dp(COUNTDOWN_LINE), dp(12.5f * NORMAL), endAlign)

            if (share == null) return@layer
            drawBar(canvas, share, dp(TOP_ROW + GAP + BAR / 2))
            val ends = text(12f, body(400), color("label"), tabular = true)
            val endsTop = dp(TOP_ROW + GAP + BAR + GAP)
            val nameTime = entry.getString("nameTime")
            val fromWidth = width - dp(8f) - ends.measureText(nameTime)
            drawLine(canvas, ellipsize(entry.optString("barFromLabel"), ends, fromWidth), ends, start(0f), endsTop, dp(12f * NORMAL), startAlign)
            drawLine(canvas, nameTime, ends, end(), endsTop, dp(12f * NORMAL), endAlign)
        }
    }

    // collapsed: the small tile and the name, the countdown at the end
    fun row(): Bitmap = layer(ROW) { canvas ->
        drawTile(canvas, ROW, 9f, 18f, 1.3f, 0f)
        val name = text(22f, display(), color("text"))
        val inner = width - dp(ROW + 12f + 8f) - timer(ROW_COUNTDOWN).measureText(WIDEST)
        drawLine(canvas, ellipsize(entry.getString("name"), name, inner), name, start(ROW + 12f), 0f, dp(ROW), startAlign)
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

    // 4 high at 20%, primary to gold up to the sun, never mirrored
    private fun drawBar(canvas: Canvas, share: Float, centerY: Float) {
        val track = RectF(0f, centerY - dp(2f), width.toFloat(), centerY + dp(2f))
        canvas.drawRoundRect(track, dp(2f), dp(2f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = alpha(color("text"), 0.2f) })
        val sunX = (width * share).coerceIn(dp(SUN), width - dp(SUN))
        val fill = RectF(0f, track.top, sunX, track.bottom)
        canvas.drawRoundRect(fill, dp(2f), dp(2f), Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(0f, 0f, sunX, 0f, color("primary"), color("gold"), Shader.TileMode.CLAMP)
        })
        // 14 with its glow, 0 0 10px 3px at 45%
        val sun = color("sun")
        canvas.drawCircle(sunX, centerY, dp(SUN + 3f), Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = alpha(sun, 0.45f)
            maskFilter = BlurMaskFilter(dp(5f), BlurMaskFilter.Blur.NORMAL)
        })
        canvas.drawCircle(sunX, centerY, dp(SUN), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = sun })
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
        private const val GAP = 12f
        private const val BAR = 16f
        private const val SUN = 7f
        private const val ROW = 32f
        private const val ROW_COUNTDOWN = 22f
        private const val WIDEST = "0:00:00"
    }
}
