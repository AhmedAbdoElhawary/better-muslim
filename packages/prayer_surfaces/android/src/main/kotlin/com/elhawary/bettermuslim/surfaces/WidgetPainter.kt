package com.elhawary.bettermuslim.surfaces

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BlurMaskFilter
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.os.Build
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import org.json.JSONObject
import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin

// the ios 5.6 trees drawn in the app's own fonts, which widget layouts can't load (research R8, Q1).
// sizes are the tree's in dp, never scaled by the phone's font size (FR-029). only the sky stretches
// to the box, a launcher can report a height far from it (oppo says 151 for a box of 78)
class WidgetPainter(
    private val context: Context,
    val kind: Kind,
    widthDp: Float,
    heightDp: Float,
    private val palette: Palette,
) {
    enum class Kind { SMALL, MEDIUM, LARGE }

    private val density = context.resources.displayMetrics.density
    private val width = max(1, (widthDp * density).toInt())
    private val height = max(1, (heightDp * density).toInt())

    class Countdown(val bitmap: Bitmap, val left: Int, val top: Int)

    val hairline: Int get() = color("text")

    // the reported height, for a launcher before android 12 that can't pick by its real box
    val short: Boolean get() = kind == Kind.MEDIUM && height < dp(MEDIUM_HEIGHT)

    // android 12 clips the root to its outline, before it the corners are in the sky itself
    fun sky(state: SurfaceState): Bitmap {
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val frame = RectF(0f, 0f, width.toFloat(), height.toFloat())
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            canvas.clipPath(Path().apply { addRoundRect(frame, dp(24f), dp(24f), Path.Direction.CW) })
        }
        drawSky(canvas, frame, deep = kind == Kind.LARGE && state is SurfaceState.Ready)
        return bitmap
    }

    // what hangs from the top, the countdown is on its own. the small widget is one square, its sun
    // moves so it is drawn on every tick. never pinned to the bottom, oppo cuts a 2 x 2 at 142 of 172
    fun top(state: SurfaceState.Ready, now: Long): Bitmap = when (kind) {
        Kind.SMALL -> layer(width.toFloat()) { drawSmall(it, state.data, state.entry, now) }
        Kind.MEDIUM -> layer(dp(MEDIUM_TOP)) { drawMediumTop(it, state.data, state.entry) }
        Kind.LARGE -> layer(dp(LARGE_ROWS_TOP + 5 * ROW)) { drawLargeTop(it, state.data, state.entry) }
    }

    // what sits on the bottom edge of the medium and the large
    fun bottom(state: SurfaceState.Ready): Bitmap =
        if (kind == Kind.MEDIUM) layer(dp(12f + CELL)) { drawStrip(it, state.data, state.entry) }
        else layer(dp(LARGE_BOTTOM)) { drawLargeBottom(it, state.data, state.entry) }

    // 5.8's 4 x 1, the times row only
    fun strip(state: SurfaceState.Ready): Bitmap = layer(dp(CELL)) { drawStrip(it, state.data, state.entry) }

    fun messagePicture(state: SurfaceState): Bitmap = layer(dp(MESSAGE)) {
        drawMessage(it, RectF(0f, 0f, width.toFloat(), dp(MESSAGE)), message(state)!!)
    }

    private fun layer(height: Float, draw: (Canvas) -> Unit): Bitmap {
        val bitmap = Bitmap.createBitmap(width, max(1, ceil(height).toInt()), Bitmap.Config.ARGB_8888)
        draw(Canvas(bitmap))
        return bitmap
    }

    // what to do, for no place and out of date
    fun message(state: SurfaceState): String? = when (state) {
        is SurfaceState.NoPlace -> state.message ?: context.getString(R.string.surfaces_no_place)
        is SurfaceState.Outdated -> state.message ?: context.getString(R.string.surfaces_outdated)
        is SurfaceState.Ready -> null
    }

    // the h:mm alone, at the end of the header. null for the small widget, its picture has it
    fun countdown(data: SurfaceData, entry: JSONObject, now: Long): Countdown? {
        if (kind == Kind.SMALL) return null
        val size = if (kind == Kind.MEDIUM) 22f else 24f
        val paint = text(size, body(data, 600), color("gold"), tabular = true)
        val text = data.hm(entry, now)
        val lineHeight = dp(size * NORMAL)
        val textWidth = ceil(paint.measureText(text)).toInt() + 1
        val bitmap = Bitmap.createBitmap(textWidth, ceil(lineHeight).toInt(), Bitmap.Config.ARGB_8888)
        drawLine(Canvas(bitmap), text, paint, 0f, 0f, lineHeight, Paint.Align.LEFT)
        val side = dp(if (kind == Kind.MEDIUM) 16f else 18f)
        val top = dp(if (kind == Kind.MEDIUM) 14f else 16f)
        val left = if (data.isArabic) side else width - side - textWidth
        return Countdown(bitmap, left.toInt(), top.toInt())
    }

    private fun drawSky(canvas: Canvas, frame: RectF, deep: Boolean) {
        val colors = if (deep) intArrayOf(color("top"), color("middle"), color("deep")) else intArrayOf(color("top"), color("middle"), color("bottom"))
        val stops = if (deep) floatArrayOf(0f, 0.3f, 1f) else floatArrayOf(0f, 0.45f, 1f)
        canvas.drawPaint(Paint().apply { shader = LinearGradient(0f, 0f, 0f, frame.bottom, colors, stops, Shader.TileMode.CLAMP) })
    }

    // widget3: the next prayer with the sun on its arc, padding 14 16
    private fun drawSmall(canvas: Canvas, data: SurfaceData, entry: JSONObject, now: Long) {
        val night = data.nightShare(entry, now)
        drawArc(canvas, night ?: data.sunShare(entry, now), night != null)
        val side = dp(16f)
        val arabic = data.isArabic
        val x = if (arabic) width - side else side
        val align = if (arabic) Paint.Align.RIGHT else Paint.Align.LEFT
        val inner = width - 2 * side

        var top = dp(14f)
        val next = text(11f, body(data, 400), color("label")).apply { letterSpacing = 0.12f }
        drawLine(canvas, data.text("next"), next, x, top, dp(11f * NORMAL), align)
        top += dp(11f * NORMAL)
        val name = text(24f, display(data), color("text"))
        drawLine(canvas, ellipsize(entry.getString("name"), name, inner), name, x, top, dp(24f * MARCELLUS), align)
        top += dp(24f * MARCELLUS)
        val duration = text(15f, body(data, 600), color("gold"), tabular = true)
        drawLine(canvas, data.inDuration(entry, now), duration, x, top, dp(15f * NORMAL), align)

        // a long city is cut, never the time, which comes first
        val city = text(12f, body(data, 400), color("label"), tabular = true)
        val bottom = canvas.height - dp(14f) - dp(12f * NORMAL)
        drawLine(canvas, ellipsize(entry.getString("timeCity"), city, inner), city, x, bottom, dp(12f * NORMAL), align)
    }

    // the 170 box's arc, centre 85 128 and radius 65, scaled evenly to the widget. never mirrored
    private fun drawArc(canvas: Canvas, share: Float?, night: Boolean) {
        val scale = width / 170f
        fun point(at: Float): Pair<Float, Float> {
            val angle = PI * (1 - at)
            return (85 + 65 * cos(angle)).toFloat() * scale to (128 - 65 * sin(angle)).toFloat() * scale
        }
        fun arc(to: Float) = Path().apply {
            val (startX, startY) = point(0f)
            moveTo(startX, startY)
            for (step in 1..60) {
                val (px, py) = point(to * step / 60)
                lineTo(px, py)
            }
        }
        val text = color("text")
        canvas.drawPath(
            arc(1f),
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(1f)
                strokeCap = Paint.Cap.ROUND
                pathEffect = DashPathEffect(floatArrayOf(dp(1f), dp(4f)), 0f)
                color = alpha(text, 0.35f)
            },
        )
        val horizon = 128 * scale
        canvas.drawLine(0f, horizon, width.toFloat(), horizon, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            strokeWidth = dp(1f)
            color = alpha(text, 0.2f)
        })
        if (share == null) return
        canvas.drawPath(
            arc(share),
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(1.2f)
                strokeCap = Paint.Cap.ROUND
                color = alpha(text, 0.75f)
            },
        )
        val (sunX, sunY) = point(share)
        val sun = color("sun")
        if (night) {
            // home's three, 7 and 5 from their middle, the first on top
            val star = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = sun }
            for (index in 0 until 3) {
                val angle = -PI / 2 + index * 2 * PI / 3
                val x = sunX + dp(5f) * cos(angle).toFloat()
                val y = sunY + dp(5f) * sin(angle).toFloat()
                canvas.drawPath(starPath(x, y, dp(7f)), star)
            }
            return
        }
        // 14 with its glow, 0 0 14px 5px at 45%
        canvas.drawCircle(sunX, sunY, dp(12f), Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = alpha(sun, 0.45f)
            maskFilter = BlurMaskFilter(dp(7f), BlurMaskFilter.Blur.NORMAL)
        })
        canvas.drawCircle(sunX, sunY, dp(7f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = sun })
    }

    // widget1: the prayer and the hijri line over all five, padding 14 14 12
    private fun drawMediumTop(canvas: Canvas, data: SurfaceData, entry: JSONObject) {
        val side = dp(16f)
        val arabic = data.isArabic
        val x = if (arabic) width - side else side
        val align = if (arabic) Paint.Align.RIGHT else Paint.Align.LEFT
        val countdown = text(22f, body(data, 600), 0, tabular = true)
        // the widest h:mm, so the line's cut doesn't move with the minutes
        val inner = width - 2 * side - countdown.measureText(data.digits("00:00")) - dp(8f)

        var top = dp(14f)
        val name = text(24f, display(data), color("text"))
        drawLine(canvas, ellipsize(entry.getString("name"), name, inner), name, x, top, dp(24f * MARCELLUS), align)
        top += dp(24f * MARCELLUS)
        val hijri = text(12f, body(data, 400), color("label"))
        drawLine(canvas, ellipsize(entry.getString("hijriCity"), hijri, inner), hijri, x, top, dp(12f * NORMAL), align)
    }

    // grid of 5, gap 4, the text in the middle of each with a gap of 3
    private fun drawStrip(canvas: Canvas, data: SurfaceData, entry: JSONObject) {
        val arabic = data.isArabic
        val row = RectF(dp(14f), 0f, width - dp(14f), dp(CELL))
        val gap = dp(4f)
        val cellWidth = (row.width() - 4 * gap) / 5
        val strip = entry.getJSONArray("strip")
        val next = if (entry.isNull("next")) -1 else entry.getInt("next")
        for (index in 0 until 5) {
            val cell = strip.getJSONObject(index)
            // the five run as home's strip does, from the right in arabic
            val column = if (arabic) 4 - index else index
            val left = row.left + column * (cellWidth + gap)
            val box = RectF(left, row.top, left + cellWidth, row.bottom)
            val current = index == next
            drawHighlight(canvas, box, current, plain = alpha(color("text"), 0.05f))
            val label = text(10f, body(data, if (current) 600 else 400), color(if (current) "gold" else "label"))
            val time = text(12f, body(data, 500), color("text"), tabular = true)
            var y = box.centerY() - dp(CELL_TEXT) / 2
            drawLine(canvas, ellipsize(cell.getString("name"), label, cellWidth), label, box.centerX(), y, dp(10f * NORMAL), Paint.Align.CENTER)
            y += dp(10f * NORMAL) + dp(3f)
            drawLine(canvas, cell.getString("time"), time, box.centerX(), y, dp(12f * NORMAL), Paint.Align.CENTER)
            y += dp(12f * NORMAL) + dp(3f)
            if (cell.getBoolean("logged")) drawCheck(canvas, box.centerX(), y + dp(5f), dp(10f))
        }
    }

    // widget2: the day at a glance with what was prayed, padding 16 16 14, gap 10
    private fun drawLargeTop(canvas: Canvas, data: SurfaceData, entry: JSONObject) {
        val side = dp(18f)
        val arabic = data.isArabic
        val start = if (arabic) width - side else side
        val end = if (arabic) side else width - side
        val startAlign = if (arabic) Paint.Align.RIGHT else Paint.Align.LEFT
        val endAlign = if (arabic) Paint.Align.LEFT else Paint.Align.RIGHT
        val countdown = text(24f, body(data, 600), 0, tabular = true)
        val at = text(12f, body(data, 400), color("label"), tabular = true)
        val endColumn = max(countdown.measureText(data.digits("00:00")), at.measureText(entry.getString("atTime")))
        val inner = width - 2 * side - endColumn - dp(8f)

        var top = dp(16f)
        val label = text(11f, body(data, 400), color("label")).apply { letterSpacing = 0.12f }
        drawLine(canvas, ellipsize(data.text("nextCity"), label, inner), label, start, top, dp(11f * NORMAL), startAlign)
        top += dp(11f * NORMAL)
        val name = text(28f, display(data), color("text"))
        drawLine(canvas, ellipsize(entry.getString("name"), name, inner), name, start, top, dp(28f * MARCELLUS), startAlign)
        drawLine(canvas, entry.getString("atTime"), at, end, dp(16f) + dp(24f * NORMAL), dp(12f * NORMAL), endAlign)

        // rows of 40 with a gap of 2, each 0 12
        val strip = entry.getJSONArray("strip")
        val next = if (entry.isNull("next")) -1 else entry.getInt("next")
        val left = dp(16f)
        val right = width - dp(16f)
        for (index in 0 until 5) {
            val cell = strip.getJSONObject(index)
            val rowTop = dp(LARGE_ROWS_TOP) + index * dp(ROW) + dp(1f)
            val box = RectF(left, rowTop, right, rowTop + dp(40f))
            val current = index == next
            drawHighlight(canvas, box, current, plain = null)
            val rowStart = if (arabic) box.right - dp(12f) else box.left + dp(12f)
            val rowEnd = if (arabic) box.left + dp(12f) else box.right - dp(12f)
            val mark = dp(22f)
            val cellName = text(17f, display(data), color(if (current) "gold" else "text"))
            val time = text(15f, body(data, 500), color("text"), tabular = true)
            val timeEnd = if (arabic) rowEnd + mark + dp(12f) else rowEnd - mark - dp(12f)
            val nameWidth = box.width() - dp(24f) - mark - dp(12f) - time.measureText(cell.getString("time")) - dp(12f)
            drawLine(canvas, ellipsize(cell.getString("name"), cellName, nameWidth), cellName, rowStart, box.top, dp(40f), startAlign)
            drawLine(canvas, cell.getString("time"), time, timeEnd, box.top, dp(40f), endAlign)
            // the mark sits at the slot's end, the 16 check or the 12 ring
            val half = dp(if (cell.getBoolean("logged")) 8f else 6f)
            val markX = if (arabic) rowEnd + half else rowEnd - half
            if (cell.getBoolean("logged")) {
                drawCheck(canvas, markX, box.centerY(), dp(16f))
            } else {
                canvas.drawCircle(markX, box.centerY(), dp(5.4f), Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    style = Paint.Style.STROKE
                    strokeWidth = dp(1.2f)
                    color = color("ring")
                })
            }
        }
    }

    // the footer at the bottom, a hairline over it, padding 10 4 0
    private fun drawLargeBottom(canvas: Canvas, data: SurfaceData, entry: JSONObject) {
        val arabic = data.isArabic
        val startAlign = if (arabic) Paint.Align.RIGHT else Paint.Align.LEFT
        val endAlign = if (arabic) Paint.Align.LEFT else Paint.Align.RIGHT
        val left = dp(16f)
        val right = width - dp(16f)
        val footer = text(12.5f, body(data, 400), color("label"))
        val footerTop = canvas.height - dp(14f) - dp(12.5f * NORMAL)
        val lineY = footerTop - dp(10f)
        canvas.drawLine(left, lineY, right, lineY, Paint().apply {
            strokeWidth = dp(1f)
            color = alpha(color("text"), 0.08f)
        })
        val footerStart = if (arabic) right - dp(4f) else left + dp(4f)
        val footerEnd = if (arabic) left + dp(4f) else right - dp(4f)
        val prayed = entry.getString("prayedLine")
        drawLine(canvas, prayed, footer, footerStart, footerTop, dp(12.5f * NORMAL), startAlign)
        val dateWidth = right - left - dp(8f) - footer.measureText(prayed) - dp(8f)
        drawLine(canvas, ellipsize(entry.getString("dateLine"), footer, dateWidth), footer, footerEnd, footerTop, dp(12.5f * NORMAL), endAlign)
    }

    // the current one on primary at 20% with a 1 inset ring at 45%
    private fun drawHighlight(canvas: Canvas, box: RectF, current: Boolean, plain: Int?) {
        val radius = dp(12f)
        val fill = if (current) alpha(color("primary"), 0.2f) else plain ?: return
        canvas.drawRoundRect(box, radius, radius, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = fill })
        if (!current) return
        val inset = dp(0.5f)
        canvas.drawRoundRect(
            RectF(box.left + inset, box.top + inset, box.right - inset, box.bottom - inset),
            radius - inset,
            radius - inset,
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = dp(1f)
                color = alpha(color("primary"), 0.45f)
            },
        )
    }

    // assets/icons/ui/check.svg in its 24 box, centred
    private fun drawCheck(canvas: Canvas, centerX: Float, centerY: Float, size: Float) {
        val scale = size / 24f
        val left = centerX - size / 2
        val top = centerY - size / 2
        val path = Path().apply {
            moveTo(left + 5 * scale, top + 12.5f * scale)
            lineTo(left + 9.5f * scale, top + 17 * scale)
            lineTo(left + 19 * scale, top + 7.5f * scale)
        }
        canvas.drawPath(path, Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 1.25f * scale
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
            color = color("success")
        })
    }

    // no place and out of date: the sky, the mark and what to do (FR-024)
    private fun drawMessage(canvas: Canvas, frame: RectF, message: String) {
        val arabic = message.any { Character.UnicodeBlock.of(it) == Character.UnicodeBlock.ARABIC }
        val paint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Fonts.body(context, arabic, 500)
            textSize = dp(13f)
            color = color("text")
        }
        val textWidth = (frame.width() - dp(32f)).toInt().coerceAtLeast(1)
        val layout = StaticLayout.Builder.obtain(message, 0, message.length, paint, textWidth)
            .setAlignment(Layout.Alignment.ALIGN_CENTER)
            .setMaxLines(3)
            .setEllipsize(TextUtils.TruncateAt.END)
            .build()
        val star = dp(23f)
        val gap = dp(10f)
        val top = frame.centerY() - (star + gap + layout.height) / 2
        drawStar(canvas, frame.centerX(), top + star / 2, star)
        canvas.save()
        canvas.translate(frame.centerX() - textWidth / 2f, top + star + gap)
        layout.draw(canvas)
        canvas.restore()
    }

    // the trees' 8 point star, viewBox -11 -11 22 22, stroke 1.1 at 23
    private fun drawStar(canvas: Canvas, centerX: Float, centerY: Float, size: Float) {
        canvas.drawPath(
            starPath(centerX, centerY, size),
            Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 1.1f * size / 22f
                strokeJoin = Paint.Join.ROUND
                color = color("primary")
            },
        )
    }

    private fun text(sizeDp: Float, face: Typeface, color: Int, tabular: Boolean = false) = textPaint(dp(sizeDp), face, color, tabular)

    private fun body(data: SurfaceData, weight: Int) = Fonts.body(context, data.isArabic, weight)

    private fun display(data: SurfaceData) = Fonts.display(context, data.isArabic)

    private fun color(role: String) = palette.color(context, role)

    private fun dp(value: Float) = value * density

    companion object {
        // css's normal line height, and the trees' 1.15 for marcellus
        const val NORMAL = 1.2f
        const val MARCELLUS = 1.15f

        // a medium cell: 8, the name, 3, the time, 3, the 10 mark, 7. the tree's height, only the
        // text went smaller to fit the width
        private const val CELL = 8f + 11f * NORMAL + 3f + 14f * NORMAL + 3f + 10f + 7f
        private const val CELL_TEXT = 10f * NORMAL + 3f + 12f * NORMAL + 3f + 10f

        private const val MEDIUM_TOP = 14f + 24f * MARCELLUS + 12f * NORMAL

        // under this the header and the row don't both fit
        const val MEDIUM_HEIGHT = MEDIUM_TOP + 12f + CELL

        private const val LARGE_BOTTOM = 14f + 12.5f * NORMAL + 10f + 1f

        // the star, its gap and three lines
        private const val MESSAGE = 100f

        // a large row with its 2 gap, under the header and the 10 gap
        private const val ROW = 42f
        private const val LARGE_ROWS_TOP = 16f + 11f * NORMAL + 28f * MARCELLUS + 10f - 1f
    }
}

private val STAR = listOf(
    0f to -10f, 2.93f to -7.07f, 7.07f to -7.07f, 7.07f to -2.93f, 10f to 0f, 7.07f to 2.93f,
    7.07f to 7.07f, 2.93f to 7.07f, 0f to 10f, -2.93f to 7.07f, -7.07f to 7.07f, -7.07f to 2.93f,
    -10f to 0f, -7.07f to -2.93f, -7.07f to -7.07f, -2.93f to -7.07f,
)

// the trees' 8 point star, viewBox -11 -11 22 22
fun starPath(centerX: Float, centerY: Float, size: Float): Path {
    val scale = size / 22f
    val path = Path()
    STAR.forEachIndexed { index, (x, y) ->
        val px = centerX + x * scale
        val py = centerY + y * scale
        if (index == 0) path.moveTo(px, py) else path.lineTo(px, py)
    }
    path.close()
    return path
}

// css's line box: the text centred in it, as the trees lay their spans out
fun drawLine(canvas: Canvas, text: String, paint: TextPaint, x: Float, top: Float, lineHeight: Float, align: Paint.Align) {
    paint.textAlign = align
    val metrics = paint.fontMetrics
    val baseline = top + (lineHeight - (metrics.descent - metrics.ascent)) / 2 - metrics.ascent
    canvas.drawText(text, x, baseline, paint)
}

fun ellipsize(text: String, paint: TextPaint, width: Float): String =
    TextUtils.ellipsize(text, paint, width.coerceAtLeast(0f), TextUtils.TruncateAt.END).toString()

fun textPaint(size: Float, face: Typeface, color: Int, tabular: Boolean = false) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
    typeface = face
    textSize = size
    this.color = color
    if (tabular) fontFeatureSettings = "'tnum'"
}

fun alpha(color: Int, share: Float) =
    Color.argb((Color.alpha(color) * share).toInt(), Color.red(color), Color.green(color), Color.blue(color))

// the flutter font assets inside the apk, loaded once. the variable ones take their weight on wght
object Fonts {
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
