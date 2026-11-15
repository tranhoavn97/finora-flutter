package com.finora.finora

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

class FinoraWidget5x2Provider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        FinoraWidgetHelper.update5x2(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == FinoraWidgetHelper.ACTION_REFRESH_WIDGETS) {
            FinoraWidgetHelper.updateAllWidgets(context)
        }
    }
}
