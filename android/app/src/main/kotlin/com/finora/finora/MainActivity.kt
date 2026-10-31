package com.finora.finora

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.Display
import android.view.WindowManager
import androidx.core.app.NotificationManagerCompat

class MainActivity : FlutterActivity() {
    private var bankInboxChannel: MethodChannel? = null
    private val CHANNEL = "com.finora.display/refresh_rate"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestSmoothDisplay()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra("from_bank_sync", false)) {
            bankInboxChannel?.invokeMethod("openBankInbox", null)
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
                val pkg = call.argument<String>("package")
                if (pkg !in setOf("com.mbmobile", "vn.com.techcombank.bb.app")) {
                    result.error("UNSUPPORTED_BANK", "Unsupported banking package", null)
                } else {
                    try {
                        val intent = packageManager.getLaunchIntentForPackage(pkg!!)
                        if (intent == null) result.success(false)
                        else { startActivity(intent); result.success(true) }
                    } catch (_: Exception) { result.success(false) }
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
        bankSyncChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeBankInboxRequest" -> {
                    val requested = intent?.getBooleanExtra("from_bank_sync", false) == true
                    intent?.removeExtra("from_bank_sync")
                    result.success(requested)
                }
                "isPermissionGranted" -> {
                    try {
                        val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(this)
                        result.success(enabledPackages.contains(packageName))
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
                    result.success(mapOf(
                        "connected" to FinoraBankNotificationListenerService.connected,
                        "lastReceivedAt" to prefs.getLong("lastReceivedAt", 0)
                    ))
                }
                "reconnect" -> {
                    FinoraBankNotificationListenerService.requestReconnect(this)
                    result.success(true)
                }
                "requestPostNotifications" -> {
                    if (Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED) {
                        requestPermissions(arrayOf(android.Manifest.permission.POST_NOTIFICATIONS), 701)
                    }
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
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        bankInboxChannel = null
        FinoraBankNotificationListenerService.onNotificationReceivedListener = null
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
