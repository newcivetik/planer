package com.planer.planer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.view.View
import org.json.JSONArray
import org.json.JSONObject

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
        private const val PREFS_NAME = "HomeWidgetPreferences"

        private fun getPrefs(context: Context): SharedPreferences {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        }

        private fun createOpenAppIntent(context: Context): PendingIntent {
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent()
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun getPriorityDotResId(priority: String): Int {
            return when (priority.lowercase()) {
                "high", "высокий" -> R.drawable.dot_high
                "medium", "средний" -> R.drawable.dot_medium
                else -> R.drawable.dot_low
            }
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

            // Set click intent to open app on any widget tap
            val pendingIntent = createOpenAppIntent(context)
            views.setOnClickPendingIntent(android.R.id.background, pendingIntent)

            when (layoutId) {
                R.layout.widget_small -> {
                    setupSmallWidget(views, progress, completed, total, dateStr, pendingIntent)
                }
                R.layout.widget_medium -> {
                    setupMediumWidget(views, progress, completed, total, tasks, pendingIntent)
                }
                R.layout.widget_large -> {
                    setupLargeWidget(views, progress, completed, total, dateStr, tasks, pendingIntent)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun setupSmallWidget(
            views: RemoteViews,
            progress: Int,
            completed: Int,
            total: Int,
            dateStr: String,
            pendingIntent: PendingIntent
        ) {
            views.setTextViewText(R.id.widget_progress_text, "$progress%")
            views.setTextViewText(R.id.widget_completed_text, "$completed/$total задач")
            views.setTextViewText(
                R.id.widget_date_text,
                if (dateStr.isNotEmpty()) dateStr else "Сегодня"
            )
            // Clickable on the whole widget
            views.setOnClickPendingIntent(R.id.widget_progress_text, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_completed_text, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_date_text, pendingIntent)
        }

        private fun setupMediumWidget(
            views: RemoteViews,
            progress: Int,
            completed: Int,
            total: Int,
            tasks: JSONArray,
            pendingIntent: PendingIntent
        ) {
            views.setTextViewText(R.id.widget_progress_text, "$progress%")
            views.setTextViewText(R.id.widget_completed_text, "$completed/$total")

            // Clickable areas
            views.setOnClickPendingIntent(R.id.widget_progress_text, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_task_list, pendingIntent)

            updateMediumTaskList(views, tasks, 4)
        }

        private fun setupLargeWidget(
            views: RemoteViews,
            progress: Int,
            completed: Int,
            total: Int,
            dateStr: String,
            tasks: JSONArray,
            pendingIntent: PendingIntent
        ) {
            views.setTextViewText(R.id.widget_progress_text, "$progress%")
            views.setTextViewText(R.id.widget_summary_text, "$completed из $total выполнено")
            views.setTextViewText(
                R.id.widget_date_text,
                if (dateStr.isNotEmpty()) dateStr else "Сегодня"
            )

            // Clickable areas
            views.setOnClickPendingIntent(R.id.widget_progress_text, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_date_text, pendingIntent)

            updateLargeTaskList(views, tasks, 5)
        }

        private fun updateMediumTaskList(views: RemoteViews, tasks: JSONArray, maxTasks: Int) {
            val taskRowIds = listOf(
                R.id.widget_task_row_1,
                R.id.widget_task_row_2,
                R.id.widget_task_row_3,
                R.id.widget_task_row_4
            )
            val taskTitleIds = listOf(
                R.id.widget_task_1,
                R.id.widget_task_2,
                R.id.widget_task_3,
                R.id.widget_task_4
            )
            val taskTimeIds = listOf(
                R.id.widget_task_time_1,
                R.id.widget_task_time_2,
                R.id.widget_task_time_3,
                R.id.widget_task_time_4
            )
            val taskDotIds = listOf(
                R.id.widget_task_dot_1,
                R.id.widget_task_dot_2,
                R.id.widget_task_dot_3,
                R.id.widget_task_dot_4
            )

            val count = minOf(tasks.length(), maxTasks)

            if (count > 0) {
                views.setViewVisibility(R.id.widget_no_tasks, View.GONE)
            }

            for (i in 0 until count) {
                if (i >= taskRowIds.size) break
                val task = tasks.getJSONObject(i)
                populateTaskRow(views, task, taskRowIds[i], taskTitleIds[i], taskTimeIds[i], taskDotIds[i])
            }
        }

        private fun updateLargeTaskList(views: RemoteViews, tasks: JSONArray, maxTasks: Int) {
            val taskRowIds = listOf(
                R.id.widget_task_row_1,
                R.id.widget_task_row_2,
                R.id.widget_task_row_3,
                R.id.widget_task_row_4,
                R.id.widget_task_row_5
            )
            val taskTitleIds = listOf(
                R.id.widget_task_1,
                R.id.widget_task_2,
                R.id.widget_task_3,
                R.id.widget_task_4,
                R.id.widget_task_5
            )
            val taskTimeIds = listOf(
                R.id.widget_task_time_1,
                R.id.widget_task_time_2,
                R.id.widget_task_time_3,
                R.id.widget_task_time_4,
                R.id.widget_task_time_5
            )
            val taskDotIds = listOf(
                R.id.widget_task_dot_1,
                R.id.widget_task_dot_2,
                R.id.widget_task_dot_3,
                R.id.widget_task_dot_4,
                R.id.widget_task_dot_5
            )

            val count = minOf(tasks.length(), maxTasks)

            if (count > 0) {
                views.setViewVisibility(R.id.widget_no_tasks, View.GONE)
            }

            for (i in 0 until count) {
                if (i >= taskRowIds.size) break
                val task = tasks.getJSONObject(i)
                populateTaskRow(views, task, taskRowIds[i], taskTitleIds[i], taskTimeIds[i], taskDotIds[i])
            }
        }

        private fun populateTaskRow(
            views: RemoteViews,
            task: JSONObject,
            rowId: Int,
            titleId: Int,
            timeId: Int,
            dotId: Int
        ) {
            val title = task.optString("title", "")
            val time = task.optString("time", "")
            val priority = task.optString("priority", "low")

            // Show the row
            views.setViewVisibility(rowId, View.VISIBLE)

            // Set task title
            views.setTextViewText(titleId, title)

            // Set time if available
            if (time.isNotEmpty()) {
                views.setTextViewText(timeId, time)
                views.setViewVisibility(timeId, View.VISIBLE)
            }

            // Set priority dot color via background resource
            views.setInt(dotId, "setBackgroundResource", getPriorityDotResId(priority))
        }
    }
}
