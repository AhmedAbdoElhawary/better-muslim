package com.elhawary.bettermuslim.surfaces

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

// the home screen widget, 4 x 2 with the band and the five times, 2 x 2 and 4 x 1 when resized
class PrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
        SurfaceTicks.arm(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        draw(context, manager, intArrayOf(id))
    }

    // the tick stays only while a countdown shows
    override fun onDisabled(context: Context) = SurfaceTicks.arm(context)

    companion object {
        private const val PREFS = "prayer_surfaces"
        private const val DRAWN = "drawn"
        const val HOME = "bettermuslim://open/"
        private val CELLS = intArrayOf(
            R.id.surfaces_cell_0, R.id.surfaces_cell_1, R.id.surfaces_cell_2, R.id.surfaces_cell_3, R.id.surfaces_cell_4,
        )

        fun ids(context: Context): IntArray =
            AppWidgetManager.getInstance(context).getAppWidgetIds(ComponentName(context, PrayerWidget::class.java))

        fun refresh(context: Context) = draw(context, AppWidgetManager.getInstance(context), ids(context))

        // a minute flip redraws the countdown alone, a new entry or state the whole picture
        fun tick(context: Context) {
            val now = System.currentTimeMillis()
            val state = SurfaceState.of(SurfaceData.load(context), now)
            if (state !is SurfaceState.Ready || drawn(state) != prefs(context).getLong(DRAWN, -1)) {
                refresh(context)
                return
            }
            val manager = AppWidgetManager.getInstance(context)
            for (id in ids(context)) {
                val views = RemoteViews(context.packageName, R.layout.prayer_widget)
                countdown(views, painter(context, manager, id), state, now)
                views.setContentDescription(R.id.surfaces_root, state.data.spoken(state.entry, now))
                manager.partiallyUpdateAppWidget(id, views)
            }
        }

        private fun draw(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val now = System.currentTimeMillis()
            val state = SurfaceState.of(SurfaceData.load(context), now)
            for (id in ids) manager.updateAppWidget(id, views(context, painter(context, manager, id), state, now))
            prefs(context).edit().putLong(DRAWN, drawn(state)).apply()
        }

        private fun views(context: Context, painter: WidgetPainter, state: SurfaceState, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            views.setImageViewBitmap(R.id.surfaces_picture, painter.picture(state))
            views.setOnClickPendingIntent(R.id.surfaces_root, open(context, HOME))
            if (state !is SurfaceState.Ready) {
                views.setViewVisibility(R.id.surfaces_countdown, View.GONE)
                views.setViewVisibility(R.id.surfaces_cells, View.GONE)
                views.setContentDescription(R.id.surfaces_root, painter.message(state))
                return views
            }
            countdown(views, painter, state, now)
            views.setContentDescription(R.id.surfaces_root, state.data.spoken(state.entry, now))
            if (painter.size == WidgetPainter.Size.BAND) {
                views.setViewVisibility(R.id.surfaces_cells, View.GONE)
                return views
            }
            views.setViewVisibility(R.id.surfaces_cells, View.VISIBLE)
            views.setViewPadding(R.id.surfaces_cells, painter.rowSide, painter.rowTop, painter.rowSide, 0)
            val strip = state.entry.getJSONArray("strip")
            val day = state.entry.getString("day")
            CELLS.forEachIndexed { column, id ->
                // the cells stay left to right, arabic's strip runs from the right
                val cell = strip.getJSONObject(if (state.data.isArabic) 4 - column else column)
                views.setOnClickPendingIntent(id, open(context, "bettermuslim://open/prayer?day=$day&prayer=${cell.getString("prayer")}"))
                views.setContentDescription(id, "${cell.getString("name")} ${cell.getString("time")}")
            }
            return views
        }

        private fun countdown(views: RemoteViews, painter: WidgetPainter, state: SurfaceState.Ready, now: Long) {
            val countdown = painter.countdown(state.data, state.entry, now)
            if (countdown == null) {
                views.setViewVisibility(R.id.surfaces_countdown, View.GONE)
                return
            }
            views.setViewVisibility(R.id.surfaces_countdown, View.VISIBLE)
            views.setImageViewBitmap(R.id.surfaces_countdown, countdown.bitmap)
            views.setViewPadding(R.id.surfaces_countdown_box, countdown.left, countdown.top, 0, 0)
        }

        // the portrait size: the launcher reports the narrowest width and the tallest height
        private fun painter(context: Context, manager: AppWidgetManager, id: Int): WidgetPainter {
            val options = manager.getAppWidgetOptions(id)
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 } ?: 250
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 } ?: 110
            return WidgetPainter(context, width.toFloat(), height.toFloat())
        }

        // the entry the picture shows, -1 for a message
        private fun drawn(state: SurfaceState) = (state as? SurfaceState.Ready)?.entry?.getLong("from") ?: -1

        // the app's own activity with the link as data, flutter's deep linking hands it to the router
        fun open(context: Context, link: String): PendingIntent = PendingIntent.getActivity(
            context,
            0,
            context.packageManager.getLaunchIntentForPackage(context.packageName)!!
                .setAction(Intent.ACTION_VIEW)
                .setData(Uri.parse(link))
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    }
}
