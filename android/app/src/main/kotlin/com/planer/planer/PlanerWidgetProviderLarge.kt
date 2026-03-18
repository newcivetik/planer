package com.planer.planer

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class PlanerWidgetProviderLarge : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            PlanerWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}
