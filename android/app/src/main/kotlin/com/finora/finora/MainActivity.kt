package com.finora.finora

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.Display
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {
    private var bankInboxChannel: MethodChannel? = null
    private var homeWidgetChannel: MethodChannel? = null
    private var pendingNotificationPermResult: MethodChannel.Result? = null
    private val CHANNEL = "com.finora.display/refresh_rate"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FinoraBankNotificationListenerService.ensureNotificationChannels(this)
        requestSmoothDisplay()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = intent.getStringExtra("finora_action")
        val fromBankSync = intent.getBooleanExtra("from_bank_sync", false)
        if (!action.isNullOrBlank()) {
            intent.removeExtra("finora_action")
            intent.removeExtra("from_bank_sync")
            if (action == "open_bank_inbox") {
                bankInboxChannel?.invokeMethod("openBankInbox", null)
            } else {
                bankInboxChannel?.invokeMethod("onLaunchAction", action)
            }
        } else if (fromBankSync) {
            intent.removeExtra("from_bank_sync")
            bankInboxChannel?.invokeMethod("openBankInbox", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 701) {
            val granted = isPostNotificationsEnabled()
            pendingNotificationPermResult?.success(granted)
            pendingNotificationPermResult = null
            if (granted) {
                FinoraBankNotificationListenerService.refreshCombinedBadge(this)
            }
        }
    }

    private fun isPostNotificationsEnabled(): Boolean {
        val osEnabled = NotificationManagerCompat.from(this).areNotificationsEnabled()
        return if (Build.VERSION.SDK_INT >= 33) {
            osEnabled &&
                checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            osEnabled
        }
    }

    override fun onPostResume() {
        super.onPostResume()
        requestSmoothDisplay()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.finora/bank_apps").setMethodCallHandler { call, result ->
            if (call.method != "openBank") {
                result.notImplemented()
            } else {
                val pkg = call.argument<String>("package")?.trim()
                val deepLink = call.argument<String>("deepLink")?.trim()
                if (pkg.isNullOrEmpty()) {
                    result.error("INVALID_PACKAGE", "Missing banking package", null)
                } else {
                    var launched = false
                    if (!deepLink.isNullOrEmpty()) {
                        try {
                            val dlIntent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                                setPackage(pkg)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            if (dlIntent.resolveActivity(packageManager) != null) {
                                startActivity(dlIntent)
                                launched = true
                            }
                        } catch (_: Exception) {}
                    }
                    if (!launched) {
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(pkg)
                            if (intent != null) {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                launched = true
                            }
                        } catch (_: Exception) {}
                    }
                    result.success(launched)
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable120Hz" -> {
                    val appliedRate = requestSmoothDisplay()
                    result.success(appliedRate)
                }
                "getRefreshRate" -> {
                    val rate = getActiveRefreshRate()
                    result.success(rate)
                }
                else -> result.notImplemented()
            }
        }

        val bankSyncChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.finora/bank_sync")
        bankInboxChannel = bankSyncChannel
        FinoraBankNotificationListenerService.onConnectionStatusChanged = { isConnected ->
            runOnUiThread {
                try {
                    bankSyncChannel.invokeMethod("onSyncStatusChanged", mapOf("connected" to isConnected))
                } catch (_: Exception) {}
            }
        }
        bankSyncChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeBankInboxRequest" -> {
                    val launchedFromHistory =
                        ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
                    val requested = !launchedFromHistory &&
                        intent?.getBooleanExtra("from_bank_sync", false) == true
                    intent?.removeExtra("from_bank_sync")
                    result.success(requested)
                }
                "consumeLaunchAction" -> {
                    val launchedFromHistory =
                        ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0
                    val action = if (launchedFromHistory) null else intent?.getStringExtra("finora_action")
                    intent?.removeExtra("finora_action")
                    result.success(action)
                }
                "isPermissionGranted" -> {
                    try {
                        val enabledPackages = try {
                            NotificationManagerCompat.getEnabledListenerPackages(this)
                        } catch (_: Exception) {
                            emptySet()
                        }
                        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: ""
                        val isGranted = enabledPackages.contains(packageName) || flat.contains(packageName)
                        result.success(isGranted)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "requestPermission" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openAppInfo" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", packageName, null)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "getPendingNotifications" -> {
                    try {
                        val list = FinoraBankNotificationListenerService.getPendingNotifications(this)
                        result.success(list)
                    } catch (e: Exception) {
                        result.success(emptyList<String>())
                    }
                }
                "acknowledgeNotifications" -> {
                    val ids = call.argument<List<String>>("ids") ?: emptyList()
                    FinoraBankNotificationListenerService.acknowledge(this, ids)
                    result.success(true)
                }
                "getSyncStatus" -> {
                    val prefs = getSharedPreferences(FinoraBankNotificationListenerService.PREFS_NAME, MODE_PRIVATE)
                    val isConn = FinoraBankNotificationListenerService.isAliveAndConnected()
                    result.success(mapOf(
                        "connected" to isConn,
                        "lastReceivedAt" to prefs.getLong("lastReceivedAt", 0)
                    ))
                }
                "reconnect" -> {
                    FinoraBankNotificationListenerService.requestReconnect(this)
                    result.success(true)
                }
                "isPostNotificationsGranted" -> {
                    result.success(isPostNotificationsEnabled())
                }
                "requestPostNotifications" -> {
                    if (isPostNotificationsEnabled()) {
                        result.success(true)
                    } else if (Build.VERSION.SDK_INT >= 33) {
                        pendingNotificationPermResult?.success(false)
                        pendingNotificationPermResult = result
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 701)
                    } else {
                        result.success(false)
                    }
                }
                "openNotificationSettings" -> {
                    try {
                        val settingsIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        } else {
                            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                        }
                        settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(settingsIntent)
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }
                "showSystemNotification" -> {
                    val title = call.argument<String>("title") ?: "FINORA"
                    val body = call.argument<String>("body") ?: ""
                    val channelType = call.argument<String>("channel") ?: "activity"
                    val notifId = call.argument<Int>("id") ?: ((System.currentTimeMillis() % 70000L) + 1000L).toInt()
                    val fromBankSync = call.argument<Boolean>("fromBankSync") ?: false
                    val action = call.argument<String>("action")
                    val channelId = if (channelType == "bank") {
                        FinoraBankNotificationListenerService.CHANNEL_BANK_SYNC
                    } else {
                        FinoraBankNotificationListenerService.CHANNEL_ACTIVITY
                    }
                    val shown = FinoraBankNotificationListenerService.showSystemNotification(
                        context = this,
                        title = title,
                        body = body,
                        channelId = channelId,
                        notifId = notifId,
                        fromBankSync = fromBankSync,
                        finoraAction = action
                    )
                    result.success(shown)
                }
                "setExtraBadgeCount" -> {
                    val extra = call.argument<Int>("count") ?: 0
                    FinoraBankNotificationListenerService.setExtraBadgeCount(this, extra)
                    result.success(true)
                }
                "updateAppBadge" -> {
                    val count = call.argument<Int>("count") ?: 0
                    val extraCount = call.argument<Int>("extraCount")
                    if (extraCount != null) {
                        val prefs = getSharedPreferences(FinoraBankNotificationListenerService.PREFS_NAME, MODE_PRIVATE)
                        prefs.edit().putInt("extra_badge_count", extraCount.coerceAtLeast(0)).apply()
                    }
                    FinoraBankNotificationListenerService.updateAppBadge(this, count)
                    result.success(true)
                }
                "updateScanSettings" -> {
                    val scanEcommerce = false
                    val scanEWallets = call.argument<Boolean>("scanEWallets") ?: true
                    val scanAllApps = false
                    val prefs = getSharedPreferences(FinoraBankNotificationListenerService.PREFS_NAME, MODE_PRIVATE)
                    prefs.edit()
                        .putBoolean("finora_scan_ecommerce", scanEcommerce)
                        .putBoolean("finora_scan_ewallets", scanEWallets)
                        .putBoolean("finora_scan_all_apps", scanAllApps)
                        .apply()
                    result.success(true)
                }
                "getScanSettings" -> {
                    val prefs = getSharedPreferences(FinoraBankNotificationListenerService.PREFS_NAME, MODE_PRIVATE)
                    result.success(mapOf(
                        "scanEcommerce" to false,
                        "scanEWallets" to prefs.getBoolean("finora_scan_ewallets", true),
                        "scanAllApps" to false
                    ))
                }
                else -> result.notImplemented()
            }
        }

        FinoraBankNotificationListenerService.onNotificationReceivedListener = { json ->
            runOnUiThread {
                bankSyncChannel.invokeMethod("onBankNotification", json.toString())
            }
        }

        val widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.finora/home_widget")
        homeWidgetChannel = widgetChannel
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "syncWidgetData" -> {
                    val payload = call.argument<String>("payload") ?: "{}"
                    FinoraWidgetHelper.savePayload(this, payload)
                    result.success(true)
                }
                "updateNotificationPrefs" -> {
                    val prefs = getSharedPreferences(FinoraBankNotificationListenerService.PREFS_NAME, MODE_PRIVATE)
                    prefs.edit()
                        .putBoolean("finora_notify_bank_expense", call.argument<Boolean>("notifyBankExpense") ?: true)
                        .putBoolean("finora_notify_bank_income", call.argument<Boolean>("notifyBankIncome") ?: true)
                        .putBoolean("finora_notify_budget_alert", call.argument<Boolean>("notifyBudgetAlert") ?: true)
                        .putBoolean("finora_notify_loan_reminder", call.argument<Boolean>("notifyLoanReminder") ?: true)
                        .putBoolean("finora_notify_show_amount", call.argument<Boolean>("notifyShowAmount") ?: true)
                        .putBoolean("finora_notify_app_badge", call.argument<Boolean>("notifyAppBadge") ?: true)
                        .apply()
                    FinoraBankNotificationListenerService.refreshCombinedBadge(this)
                    result.success(true)
                }
                "refreshWidgets" -> {
                    FinoraWidgetHelper.updateAllWidgets(this)
                    result.success(true)
                }
                "canPinWidgets" -> {
                    val supported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        AppWidgetManager.getInstance(this).isRequestPinAppWidgetSupported
                    } else {
                        false
                    }
                    result.success(supported)
                }
                "requestPinWidget" -> {
                    val widgetType = call.argument<String>("widgetType") ?: "5x2"
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val manager = AppWidgetManager.getInstance(this)
                        if (manager.isRequestPinAppWidgetSupported) {
                            val provider = ComponentName(
                                this,
                                if (widgetType == "5x4") {
                                    FinoraWidget5x4Provider::class.java
                                } else {
                                    FinoraWidget5x2Provider::class.java
                                }
                            )
                            FinoraWidgetHelper.updateAllWidgets(this)
                            val ok = manager.requestPinAppWidget(provider, null, null)
                            result.success(ok)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bankInboxChannel = null
        homeWidgetChannel = null
        pendingNotificationPermResult = null
        FinoraBankNotificationListenerService.onNotificationReceivedListener = null
        FinoraBankNotificationListenerService.onConnectionStatusChanged = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        requestSmoothDisplay()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        requestSmoothDisplay()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) requestSmoothDisplay()
    }

    @Suppress("DEPRECATION")
    private fun getActiveRefreshRate(): Float {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                this.display ?: windowManager.defaultDisplay
            } else {
                windowManager.defaultDisplay
            }
            display?.mode?.refreshRate ?: 60.0f
        } else {
            60.0f
        }
    }

    @Suppress("DEPRECATION")
    private fun requestSmoothDisplay(): Float {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return 60.0f
        try {
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                this.display ?: windowManager.defaultDisplay
            } else {
                windowManager.defaultDisplay
            } ?: return 60.0f

            val modes = display.supportedModes
            var bestMode: Display.Mode? = null
            var maxRate = 60.0f

            // Unconditionally find best mode with highest refresh rate up to 165Hz (90Hz / 120Hz / 144Hz)
            for (m in modes) {
                if (m.refreshRate > maxRate && m.refreshRate <= 165.5f) {
                    maxRate = m.refreshRate
                    bestMode = m
                }
            }

            val params = window.attributes
            if (bestMode != null) {
                params.preferredDisplayModeId = bestMode.modeId
                params.preferredRefreshRate = bestMode.refreshRate
            } else {
                params.preferredRefreshRate = maxRate
            }

            // Dynamic lock to highest refresh rate (available on Android 11+)
            try {
                params.javaClass.getField("preferredMinDisplayRefreshRate").set(params, maxRate)
            } catch (_: Exception) {}
            try {
                params.javaClass.getField("preferredMaxDisplayRefreshRate").set(params, maxRate)
            } catch (_: Exception) {}
            window.attributes = params
            return maxRate
        } catch (e: Exception) {
            return 60.0f
        }
    }
}
