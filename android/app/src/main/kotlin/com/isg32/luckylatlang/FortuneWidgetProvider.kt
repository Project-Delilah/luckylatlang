package com.isg32.luckylatlang

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import org.json.JSONArray

private const val ACTION_REFRESH = "com.isg32.luckylatlang.FORTUNE_REFRESH"
private const val PREF_FILE = "FlutterSharedPreferences"
private const val PREF_QUOTES = "flutter.fortune_quotes_v1"
private const val PREF_CHILD_PREFIX = "fortune_widget_child_"
private const val GOTH_DIR = "flutter_assets/assets/goth"

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
        val prefs = ctx.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)

        // Toggle A (0) / B (1) child on every tap so ViewFlipper animates between them
        val current = prefs.getInt("$PREF_CHILD_PREFIX$id", 0)
        val next = 1 - current
        prefs.edit().putInt("$PREF_CHILD_PREFIX$id", next).apply()

        val (body, attr) = pickAndSplit(ctx)
        val views = RemoteViews(ctx.packageName, layoutRes)

        // Put quote content into the incoming child slot
        val (quoteId, attrId) = if (next == 0)
            R.id.quote_a to R.id.attr_a
        else
            R.id.quote_b to R.id.attr_b
        views.setTextViewText(quoteId, body)
        views.setTextViewText(attrId, attr)

        // Put image into the incoming image slot
        val imageId = if (next == 0) R.id.image_a else R.id.image_b
        loadGothImage(ctx)?.let { bmp -> views.setImageViewBitmap(imageId, bmp) }

        // Animate both flippers to the new child
        views.setInt(R.id.image_flipper, "setDisplayedChild", next)
        views.setInt(R.id.quote_flipper, "setDisplayedChild", next)

        // Tap anywhere → next quote + image
        val pi = PendingIntent.getBroadcast(
            ctx, id,
            Intent(ctx, this.javaClass).also { it.action = ACTION_REFRESH },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.fortune_root, pi)

        mgr.updateAppWidget(id, views)
    }

    private fun loadGothImage(ctx: Context) = try {
        val files = ctx.assets.list(GOTH_DIR)?.filter { it.endsWith(".webp") }
        if (files.isNullOrEmpty()) null
        else {
            val opts = BitmapFactory.Options().also { it.inSampleSize = 4 }
            ctx.assets.open("$GOTH_DIR/${files.random()}").use { stream ->
                BitmapFactory.decodeStream(stream, null, opts)
            }
        }
    } catch (e: Exception) { null }

    private fun pickAndSplit(ctx: Context): Pair<String, String> {
        val raw = pickRaw(ctx)
        val lines = raw.trim().split("\n")
        return if (lines.size > 1 && lines.last().trimStart().startsWith("—"))
            lines.dropLast(1).joinToString("\n") to lines.last().trim()
        else
            raw to ""
    }

    private fun pickRaw(ctx: Context): String {
        val prefs = ctx.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
        val json = prefs.getString(PREF_QUOTES, null) ?: return FALLBACK.random()
        return try {
            val arr = JSONArray(json)
            arr.getString((0 until arr.length()).random())
        } catch (e: Exception) { FALLBACK.random() }
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
