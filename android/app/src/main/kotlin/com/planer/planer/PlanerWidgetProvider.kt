package com.planer.planer

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.view.View
import org.json.JSONArray

class PlanerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = getPrefs(context)
            val progress = prefs.getInt("progress", 0)
            val completed = prefs.getInt("completed", 0)
            val total = prefs.getInt("total", 0)
            val dateStr = prefs.getString("date", "") ?: ""
            val tasksJson = prefs.getString("tasks", "[]") ?: "[]"

            val tasks = try {
                JSONArray(tasksJson)
            } catch (e: Exception) {
                JSONArray()
            }

            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)

            val layoutId = when {
                minHeight >= 200 -> R.layout.widget_large
                minWidth >= 200 -> R.layout.widget_medium
                else -> R.layout.widget_small
            }

            val views = RemoteViews(context.packageName, layoutId)

            when (layoutId) {
                R.layout.widget_small -> {
                    views.setTextViewText(R.id.widget_progress_text, "$progress%")
                    views.setTextViewText(R.id.widget_completed_text, "$completed/$total задач")
                    views.setTextViewText(R.id.widget_date_text, if (dateStr.isNotEmpty()) dateStr else "Сегодня")
                }
                R.layout.widget_medium -> {
                    views.setTextViewText(R.id.widget_progress_text, "$progress%")
                    views.setTextViewText(R.id.widget_completed_text, "$completed/$total")
                    updateTaskList(views, tasks, 4)
                }
                R.layout.widget_large -> {
                    views.setTextViewText(R.id.widget_progress_text, "$progress%")
                    views.setTextViewText(R.id.widget_summary_text, "$completed из $total выполнено")
                    views.setTextViewText(R.id.widget_date_text, if (dateStr.isNotEmpty()) dateStr else "Сегодня")
                    updateTaskListLarge(views, tasks, 5)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun updateTaskList(views: RemoteViews, tasks: JSONArray, maxTasks: Int) {
            val taskIds = listOf(
                R.id.widget_task_1,
                R.id.widget_task_2,
                R.id.widget_task_3,
                R.id.widget_task_4
            )

            val count = minOf(tasks.length(), maxTasks)

            if (count > 0) {
                views.setViewVisibility(R.id.widget_no_tasks, View.GONE)
            }

            for (i in 0 until count) {
                if (i >= taskIds.size) break
                val task = tasks.getJSONObject(i)
                val title = task.optString("title", "")
                val time = task.optString("time", "")
                val displayText = if (time.isNotEmpty()) "• $time  $title" else "• $title"
                views.setTextViewText(taskIds[i], displayText)
                views.setViewVisibility(taskIds[i], View.VISIBLE)
            }
        }

        private fun updateTaskListLarge(views: RemoteViews, tasks: JSONArray, maxTasks: Int) {
            val taskIds = listOf(
                R.id.widget_task_1,
                R.id.widget_task_2,
                R.id.widget_task_3,
                R.id.widget_task_4,
                R.id.widget_task_5
            )

            val count = minOf(tasks.length(), maxTasks)

            if (count > 0) {
                views.setViewVisibility(R.id.widget_no_tasks, View.GONE)
            }

            for (i in 0 until count) {
                if (i >= taskIds.size) break
                val task = tasks.getJSONObject(i)
                val title = task.optString("title", "")
                val time = task.optString("time", "")
                val displayText = if (time.isNotEmpty()) "$time  $title" else "• $title"
                views.setTextViewText(taskIds[i], displayText)
                views.setViewVisibility(taskIds[i], View.VISIBLE)
            }
        }
    }
}
