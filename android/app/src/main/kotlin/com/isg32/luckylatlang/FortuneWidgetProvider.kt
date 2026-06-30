package com.isg32.luckylatlang

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

private const val ACTION_REFRESH = "com.isg32.luckylatlang.FORTUNE_REFRESH"
private const val PREF_FILE = "FlutterSharedPreferences"
private const val PREF_QUOTES = "flutter.fortune_quotes_v1"

// Built-in fallback — shown before the app is ever opened.
private val FALLBACK = arrayOf(
    "The cosmos is within us.\nWe are made of star-stuff.\n— Carl Sagan",
    "Not all those who wander are lost.\n— J.R.R. Tolkien",
    "Time is an illusion. Lunchtime doubly so.\n— Douglas Adams",
    "42.\n— Deep Thought",
    "The journey of a thousand miles begins with a single step.\n— Lao Tzu",
    "Life is either a daring adventure or nothing.\n— Helen Keller",
    "The best way to predict the future is to invent it.\n— Alan Kay",
    "Look up at the stars and not down at your feet.\n— Stephen Hawking",
    "We are all star stuff.\n— Carl Sagan",
    "In theory, there is no difference between theory and practice.\nIn practice, there is.",
)

abstract class FortuneWidgetProvider : AppWidgetProvider() {
    abstract val layoutRes: Int

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) =
        ids.forEach { updateWidget(ctx, mgr, it) }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == ACTION_REFRESH) {
            val mgr = AppWidgetManager.getInstance(ctx)
            mgr.getAppWidgetIds(ComponentName(ctx, this.javaClass))
                .forEach { updateWidget(ctx, mgr, it) }
        }
    }

    private fun updateWidget(ctx: Context, mgr: AppWidgetManager, id: Int) {
        val (body, attr) = pickAndSplit(ctx)
        val views = RemoteViews(ctx.packageName, layoutRes)

        views.setTextViewText(R.id.fortune_quote, body)
        views.setTextViewText(R.id.fortune_attr, attr)

        // Tap anywhere on the widget → pick new quote (no app launch)
        val refreshPi = PendingIntent.getBroadcast(
            ctx, id,
            Intent(ctx, this.javaClass).also { it.action = ACTION_REFRESH },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.fortune_root, refreshPi)

        mgr.updateAppWidget(id, views)
    }

    private fun pickAndSplit(ctx: Context): Pair<String, String> {
        val raw = pickRaw(ctx)
        val lines = raw.trim().split("\n")
        return if (lines.size > 1 && lines.last().trimStart().startsWith("—")) {
            lines.dropLast(1).joinToString("\n") to lines.last().trim()
        } else {
            raw to ""
        }
    }

    private fun pickRaw(ctx: Context): String {
        val prefs = ctx.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
        val json = prefs.getString(PREF_QUOTES, null) ?: return FALLBACK.random()
        return try {
            val arr = JSONArray(json)
            arr.getString((0 until arr.length()).random())
        } catch (e: Exception) {
            FALLBACK.random()
        }
    }
}

class FortuneWidgetDark : FortuneWidgetProvider() {
    override val layoutRes = R.layout.fortune_widget_dark
}

class FortuneWidgetCoral : FortuneWidgetProvider() {
    override val layoutRes = R.layout.fortune_widget_coral
}

class FortuneWidgetMaterial : FortuneWidgetProvider() {
    override val layoutRes = R.layout.fortune_widget_material
}
