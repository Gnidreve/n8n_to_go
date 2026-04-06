package com.example.flutter_shadcn

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class N8nHelloWorldWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            appWidgetManager.updateAppWidget(appWidgetId, buildRemoteViews(context))
        }
    }

    private fun buildRemoteViews(context: Context): RemoteViews {
        return RemoteViews(context.packageName, R.layout.n8n_hello_world_widget).apply {
            setTextViewText(
                R.id.widget_metric_label_1,
                context.getString(R.string.widget_label_prod_executions),
            )
            setTextViewText(
                R.id.widget_metric_value_1,
                context.getString(R.string.widget_value_prod_executions),
            )
            setTextViewText(
                R.id.widget_metric_label_2,
                context.getString(R.string.widget_label_failed_prod_executions),
            )
            setTextViewText(
                R.id.widget_metric_value_2,
                context.getString(R.string.widget_value_failed_prod_executions),
            )
            setTextViewText(
                R.id.widget_metric_label_3,
                context.getString(R.string.widget_label_failure_rate),
            )
            setTextViewText(
                R.id.widget_metric_value_3,
                context.getString(R.string.widget_value_failure_rate),
            )
            setTextViewText(
                R.id.widget_metric_label_4,
                context.getString(R.string.widget_label_time_saved),
            )
            setTextViewText(
                R.id.widget_metric_value_4,
                context.getString(R.string.widget_value_time_saved),
            )
            setTextViewText(
                R.id.widget_metric_label_5,
                context.getString(R.string.widget_label_run_time_avg),
            )
            setTextViewText(
                R.id.widget_metric_value_5,
                context.getString(R.string.widget_value_run_time_avg),
            )
        }
    }
}
