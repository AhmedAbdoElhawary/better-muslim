package com.elhawary.bettermuslim.surfaces

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.appwidget.AppWidgetProviderInfo
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.elhawary.bettermuslim.surfaces.WidgetPainter.Kind

// the ios three on the home screen: small 2 x 2, medium 4 x 2 and large 4 x 4, each its own picker
// entry. this one is the medium, the two below the small and the large
open class PrayerWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        draw(context, manager, ids)
        SurfaceTicks.arm(context)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        draw(context, manager, intArrayOf(id))
    }

    // the tick stays only while a countdown shows
    override fun onDisabled(context: Context) = SurfaceTicks.arm(context)

    private class Provider(val type: Class<out PrayerWidget>, val kind: Kind, val width: Float, val height: Float)

    companion object {
        private const val PREFS = "prayer_surfaces"
        private const val DRAWN = "drawn"
        const val HOME = "bettermuslim://open/"
        private val CELLS = intArrayOf(
            R.id.surfaces_cell_0, R.id.surfaces_cell_1, R.id.surfaces_cell_2, R.id.surfaces_cell_3, R.id.surfaces_cell_4,
        )

        // each picker entry with the 5.6 size its preview is drawn at
        private val PROVIDERS = listOf(
            Provider(NextPrayerWidget::class.java, Kind.SMALL, 170f, 170f),
            Provider(PrayerWidget::class.java, Kind.MEDIUM, 364f, 170f),
            Provider(TodaysPrayersWidget::class.java, Kind.LARGE, 364f, 382f),
        )

        private fun placed(context: Context): List<Pair<Int, Provider>> {
            val manager = AppWidgetManager.getInstance(context)
            return PROVIDERS.flatMap { provider ->
                manager.getAppWidgetIds(ComponentName(context, provider.type)).map { it to provider }
            }
        }

        fun ids(context: Context): IntArray = placed(context).map { it.first }.toIntArray()

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            draw(context, manager, ids(context))
        }

        // a minute flip redraws the countdown alone, a new entry or state the whole picture. the
        // small one's sun moves, so it is drawn whole each time
        fun tick(context: Context) {
            val now = System.currentTimeMillis()
            val data = SurfaceData.load(context)
            val state = SurfaceState.of(data, now)
            if (state !is SurfaceState.Ready || drawn(state) != prefs(context).getLong(DRAWN, -1)) {
                refresh(context)
                return
            }
            val manager = AppWidgetManager.getInstance(context)
            for ((id, provider) in placed(context)) {
                val painter = painter(context, manager, id, provider.kind, data, state)
                if (provider.kind == Kind.SMALL) {
                    manager.updateAppWidget(id, views(context, painter, state, now))
                    continue
                }
                val views = RemoteViews(context.packageName, layout(provider.kind))
                countdown(views, painter, state, now)
                views.setContentDescription(R.id.surfaces_root, state.data.spoken(state.entry, now))
                manager.partiallyUpdateAppWidget(id, views)
            }
        }

        private fun draw(context: Context, manager: AppWidgetManager, ids: IntArray) {
            val now = System.currentTimeMillis()
            val data = SurfaceData.load(context)
            val state = SurfaceState.of(data, now)
            val kinds = placed(context).toMap()
            for (id in ids) {
                val kind = kinds[id]?.kind ?: continue
                manager.updateAppWidget(id, views(context, painter(context, manager, id, kind, data, state), state, now))
            }
            if (drawn(state) != prefs(context).getLong(DRAWN, -1)) preview(context, manager, data, state, now)
            prefs(context).edit().putLong(DRAWN, drawn(state)).apply()
        }

        // android 15 shows this in the picker, before only the app icon. the launcher allows a few
        // an hour, so only a new entry sends them
        private fun preview(context: Context, manager: AppWidgetManager, data: SurfaceData?, state: SurfaceState, now: Long) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.VANILLA_ICE_CREAM) return
            for (provider in PROVIDERS) {
                manager.setWidgetPreview(
                    ComponentName(context, provider.type),
                    AppWidgetProviderInfo.WIDGET_CATEGORY_HOME_SCREEN,
                    views(context, WidgetPainter(context, provider.kind, provider.width, provider.height, palette(context, data, state)), state, now),
                )
            }
        }

        private fun views(context: Context, painter: WidgetPainter, state: SurfaceState, now: Long): RemoteViews {
            val views = RemoteViews(context.packageName, layout(painter.kind))
            views.setImageViewBitmap(R.id.surfaces_picture, painter.picture(state, now))
            views.setOnClickPendingIntent(R.id.surfaces_root, open(context, HOME))
            if (state !is SurfaceState.Ready) {
                views.setViewVisibility(R.id.surfaces_countdown, View.GONE)
                views.setViewVisibility(R.id.surfaces_cells, View.GONE)
                views.setContentDescription(R.id.surfaces_root, painter.message(state))
                return views
            }
            countdown(views, painter, state, now)
            views.setContentDescription(R.id.surfaces_root, state.data.spoken(state.entry, now))
            if (painter.kind == Kind.SMALL) {
                views.setViewVisibility(R.id.surfaces_cells, View.GONE)
                return views
            }
            views.setViewVisibility(R.id.surfaces_cells, View.VISIBLE)
            views.setViewPadding(R.id.surfaces_cells, painter.cellsLeft, painter.cellsTop, painter.cellsLeft, painter.cellsBottom)
            val strip = state.entry.getJSONArray("strip")
            val day = state.entry.getString("day")
            CELLS.forEachIndexed { index, id ->
                // the medium's cells stay left to right, arabic's strip runs from the right
                val cell = strip.getJSONObject(if (state.data.isArabic && painter.kind == Kind.MEDIUM) 4 - index else index)
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

        private fun layout(kind: Kind) = if (kind == Kind.LARGE) R.layout.prayer_widget_large else R.layout.prayer_widget

        // the portrait size: the launcher reports the narrowest width and the tallest height
        private fun painter(context: Context, manager: AppWidgetManager, id: Int, kind: Kind, data: SurfaceData?, state: SurfaceState): WidgetPainter {
            val options = manager.getAppWidgetOptions(id)
            val provider = PROVIDERS.first { it.kind == kind }
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 }?.toFloat() ?: provider.width
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 }?.toFloat() ?: provider.height
            return WidgetPainter(context, kind, width, height, palette(context, data, state))
        }

        private fun palette(context: Context, data: SurfaceData?, state: SurfaceState): Palette =
            if (state is SurfaceState.Ready) state.data.palette(state.entry) else Palette.of(context, data)

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

class NextPrayerWidget : PrayerWidget()

class TodaysPrayersWidget : PrayerWidget()
