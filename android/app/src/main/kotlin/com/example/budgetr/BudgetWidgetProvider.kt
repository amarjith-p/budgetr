package com.example.budgetr

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
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
                val month = widgetData.getString("budget_month", "NO BUDGET") ?: "NO BUDGET"
                val spent = widgetData.getString("budget_spent", "₹0") ?: "₹0"
                val total = widgetData.getString("budget_total", "0") ?: "0"
                val remaining = widgetData.getString("budget_remaining", "₹0 left") ?: "₹0 left"
                val isGlobalOver = widgetData.getString("is_global_over_budget", "false") == "true"
                val progressInt = widgetData.getInt("budget_progress_int", 0)
                val bucketsJson = widgetData.getString("buckets_json", "[]") ?: "[]"

                setTextViewText(R.id.widget_month_text, month)
                setTextViewText(R.id.widget_spent_text, spent)
                setTextViewText(R.id.widget_total_text, "of ₹$total")
                setTextViewText(R.id.widget_remaining_text, remaining)

                // GLOBAL PROGRESS BAR & TEXT COLOR TOGGLE
                if (isGlobalOver) {
                    setTextColor(R.id.widget_remaining_text, android.graphics.Color.parseColor("#E71D36"))
                    setViewVisibility(R.id.widget_progress_bar, View.GONE)
                    setViewVisibility(R.id.widget_progress_bar_over, View.VISIBLE)
                    setProgressBar(R.id.widget_progress_bar_over, 100, 100, false) // 100% full red bar
                } else {
                    setTextColor(R.id.widget_remaining_text, android.graphics.Color.parseColor("#2EC4B6"))
                    setViewVisibility(R.id.widget_progress_bar, View.VISIBLE)
                    setViewVisibility(R.id.widget_progress_bar_over, View.GONE)
                    setProgressBar(R.id.widget_progress_bar, 100, progressInt, false)
                }

                // DYNAMIC BUCKETS ATTACHMENT
                removeAllViews(R.id.buckets_container)
                try {
                    val array = JSONArray(bucketsJson)
                    for (i in 0 until array.length()) {
                        val obj = array.getJSONObject(i)
                        val bucketView = RemoteViews(context.packageName, R.layout.widget_bucket_item)
                        
                        val bucketName = obj.optString("name", "Bucket").uppercase()
                        val remainingText = obj.optString("remaining_text", "₹0 left")
                        val allocatedText = obj.optString("allocated_text", "")
                        val isOverBudget = obj.optBoolean("is_over_budget", false)
                        val bucketProgress = obj.optInt("progress", 0)

                        bucketView.setTextViewText(R.id.bucket_name, bucketName)
                        bucketView.setTextViewText(R.id.bucket_spent, remainingText)
                        bucketView.setTextViewText(R.id.bucket_allocated, allocatedText)
                        
                        // BUCKET PROGRESS BAR & TEXT COLOR TOGGLE
                        if (isOverBudget) {
                            bucketView.setTextColor(R.id.bucket_spent, android.graphics.Color.parseColor("#E71D36"))
                            bucketView.setViewVisibility(R.id.bucket_progress, View.GONE)
                            bucketView.setViewVisibility(R.id.bucket_progress_over, View.VISIBLE)
                            bucketView.setProgressBar(R.id.bucket_progress_over, 100, 100, false) // 100% full red bar
                        } else {
                            bucketView.setTextColor(R.id.bucket_spent, android.graphics.Color.parseColor("#2EC4B6"))
                            bucketView.setViewVisibility(R.id.bucket_progress, View.VISIBLE)
                            bucketView.setViewVisibility(R.id.bucket_progress_over, View.GONE)
                            bucketView.setProgressBar(R.id.bucket_progress, 100, bucketProgress, false)
                        }
                        
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