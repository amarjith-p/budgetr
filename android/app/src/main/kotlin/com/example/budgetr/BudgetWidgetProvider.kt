package com.example.budgetr

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class BudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.budget_widget).apply {
                val month = widgetData.getString("budget_month", "NO BUDGET")
                val spent = widgetData.getString("budget_spent", "₹0")
                val total = widgetData.getString("budget_total", "0")
                val remaining = widgetData.getString("budget_remaining", "₹0 left")
                val progressInt = widgetData.getInt("budget_progress_int", 0)
                val bucketsJson = widgetData.getString("buckets_json", "[]")

                setTextViewText(R.id.widget_month_text, month)
                setTextViewText(R.id.widget_spent_text, spent)
                setTextViewText(R.id.widget_total_text, "of ₹$total")
                setTextViewText(R.id.widget_remaining_text, remaining)
                setProgressBar(R.id.widget_progress_bar, 100, progressInt, false)

                // DYNAMIC BUCKETS ATTACHMENT
                removeAllViews(R.id.buckets_container)
                try {
                    val array = JSONArray(bucketsJson)
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        val bucketView = RemoteViews(context.packageName, R.layout.widget_bucket_item)
                        
                        bucketView.setTextViewText(R.id.bucket_name, obj.getString("name").uppercase())
                        bucketView.setTextViewText(R.id.bucket_spent, obj.getString("spent"))
                        bucketView.setTextViewText(R.id.bucket_allocated, " / " + obj.getString("allocated"))
                        bucketView.setProgressBar(R.id.bucket_progress, 100, obj.getInt("progress"), false)
                        
                        addView(R.id.buckets_container, bucketView)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                // Attach Deep Link
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("budgetr://add_transaction")
                )
                setOnClickPendingIntent(R.id.widget_add_button, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}