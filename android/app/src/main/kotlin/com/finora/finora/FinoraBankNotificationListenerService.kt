package com.finora.finora

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.net.Uri
import android.content.ContentValues
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.content.Context
import android.content.ComponentName
import android.content.pm.PackageManager
import java.security.MessageDigest
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

class FinoraBankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "FinoraBankSync"
        const val PREFS_NAME = "finora_bank_sync_prefs"
        const val KEY_PENDING_NOTIFICATIONS = "pending_notifications"
        private const val KEY_HANDLED = "handled_notifications"
        private const val KEY_EXTRA_BADGE_COUNT = "extra_badge_count"
        const val CHANNEL_BANK_SYNC = "finora_bank_sync_channel_v2"
        const val CHANNEL_APP_BADGE = "finora_app_badge_channel_v2"
        const val CHANNEL_ACTIVITY = "finora_activity_channel_v1"
        private const val BADGE_NOTIFICATION_ID = 88888
        @Volatile var instance: FinoraBankNotificationListenerService? = null
        @Volatile var connected = false
        var onConnectionStatusChanged: ((Boolean) -> Unit)? = null
        private val queueLock = Any()

        fun ensureNotificationChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            try {
                val notificationManager =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                // Remove legacy low-importance / duplicate channels on upgrade.
                try {
                    notificationManager.deleteNotificationChannel("finora_app_badge_channel")
                    notificationManager.deleteNotificationChannel("finora_bank_sync_channel")
                } catch (_: Exception) {}

                val bankChannel = NotificationChannel(
                    CHANNEL_BANK_SYNC,
                    "Biến động số dư ngân hàng",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Thông báo ngay khi nhận được biến động số dư từ ngân hàng hoặc ví điện tử"
                    enableVibration(true)
                    setShowBadge(false)
                }
                notificationManager.createNotificationChannel(bankChannel)

                val activityChannel = NotificationChannel(
                    CHANNEL_ACTIVITY,
                    "Nhắc nhở & Hoạt động tài chính",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Cảnh báo hạn mức, nhắc lịch sổ nợ và hoạt động ví gia đình"
                    enableVibration(true)
                    setShowBadge(false)
                }
                notificationManager.createNotificationChannel(activityChannel)

                // Launcher badge channel must be IMPORTANCE_LOW+ and not MIN so launchers show badge numbers.
                val badgeChannel = NotificationChannel(
                    CHANNEL_APP_BADGE,
                    "Số thông báo trên biểu tượng ứng dụng",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Hiển thị số lượng biến động và thông báo chưa đọc trên icon FINORA"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(true)
                }
                notificationManager.createNotificationChannel(badgeChannel)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to create notification channels: ${e.message}")
            }
        }

        fun setExtraBadgeCount(context: Context, extraCount: Int) {
            val sanitized = extraCount.coerceAtLeast(0)
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putInt(KEY_EXTRA_BADGE_COUNT, sanitized).apply()
            refreshCombinedBadge(context)
        }

        fun refreshCombinedBadge(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pendingCount = try {
                JSONArray(prefs.getString(KEY_PENDING_NOTIFICATIONS, "[]")).length()
            } catch (_: Exception) {
                0
            }
            val extraCount = prefs.getInt(KEY_EXTRA_BADGE_COUNT, 0).coerceAtLeast(0)
            updateAppBadge(context, pendingCount + extraCount)
        }

        fun updateAppBadge(context: Context, rawCount: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val badgeEnabled = prefs.getBoolean("finora_notify_app_badge", true)
            val count = if (badgeEnabled) rawCount.coerceAtLeast(0) else 0
            try {
                ensureNotificationChannels(context)
                val notificationManager =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

                if (count > 0 && NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_MAIN
                        addCategory(Intent.CATEGORY_LAUNCHER)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("from_bank_sync", true)
                    }
                    val pendingIntent = PendingIntent.getActivity(
                        context,
                        8888,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or
                            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                    )

                    val pendingLen = try {
                        val p = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        JSONArray(p.getString(KEY_PENDING_NOTIFICATIONS, "[]")).length()
                    } catch (_: Exception) {
                        0
                    }
                    val summaryText = if (pendingLen > 0) {
                        "Có $count thông báo ($pendingLen biến động số dư chờ ghi sổ)"
                    } else {
                        "Có $count thông báo chưa đọc trong FINORA"
                    }

                    val builder = NotificationCompat.Builder(context, CHANNEL_APP_BADGE)
                        .setSmallIcon(R.drawable.finora_bank_notification)
                        .setContentTitle("FINORA")
                        .setContentText(summaryText)
                        .setNumber(count)
                        .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
                        .setPriority(NotificationCompat.PRIORITY_LOW)
                        .setCategory(NotificationCompat.CATEGORY_STATUS)
                        .setGroup("finora_app_badge_group")
                        .setOnlyAlertOnce(true)
                        .setSilent(true)
                        .setOngoing(false)
                        .setAutoCancel(false)
                        .setContentIntent(pendingIntent)

                    val notification = builder.build()
                    // Reflection fallback for MIUI / HyperOS badge field
                    try {
                        val field = notification.javaClass.getDeclaredField("extraNotification")
                        val extraNotification = field.get(notification)
                        val setMsgCount = extraNotification?.javaClass?.getDeclaredMethod(
                            "setMessageCount",
                            Int::class.javaPrimitiveType
                        )
                        setMsgCount?.invoke(extraNotification, count)
                    } catch (_: Exception) {}

                    notificationManager.notify(BADGE_NOTIFICATION_ID, notification)
                } else {
                    notificationManager.cancel(BADGE_NOTIFICATION_ID)
                }

                val launcherClass = context.packageManager
                    .getLaunchIntentForPackage(context.packageName)
                    ?.component
                    ?.className
                    ?: "com.finora.finora.MainActivity"

                // 1. Samsung OneUI Badge (update first, insert fallback)
                try {
                    val contentUri = Uri.parse("content://com.sec.android.provider.badge/apps")
                    val contentValues = ContentValues().apply {
                        put("package", context.packageName)
                        put("class", launcherClass)
                        put("badgecount", count)
                    }
                    val updated = context.contentResolver.update(
                        contentUri,
                        contentValues,
                        "package=? AND class=?",
                        arrayOf(context.packageName, launcherClass)
                    )
                    if (updated == 0) {
                        context.contentResolver.insert(contentUri, contentValues)
                    }
                } catch (_: Exception) {}

                // 2. Xiaomi / MIUI / HyperOS Badge broadcast
                try {
                    val miuiIntent = Intent("android.intent.action.APPLICATION_MESSAGE_UPDATE").apply {
                        putExtra(
                            "android.intent.extra.update_application_component_name",
                            "${context.packageName}/$launcherClass"
                        )
                        putExtra(
                            "android.intent.extra.update_application_message_text",
                            if (count > 0) count.toString() else ""
                        )
                    }
                    context.sendBroadcast(miuiIntent)
                } catch (_: Exception) {}

                // 3. Sony Xperia
                try {
                    val sonyIntent = Intent("com.sonyericsson.home.action.UPDATE_BADGE").apply {
                        putExtra("com.sonyericsson.home.intent.extra.badge.PACKAGE_NAME", context.packageName)
                        putExtra("com.sonyericsson.home.intent.extra.badge.ACTIVITY_NAME", launcherClass)
                        putExtra("com.sonyericsson.home.intent.extra.badge.MESSAGE", if (count > 0) count.toString() else "")
                        putExtra("com.sonyericsson.home.intent.extra.badge.SHOW_MESSAGE", count > 0)
                    }
                    context.sendBroadcast(sonyIntent)
                } catch (_: Exception) {}

                // 4. Huawei / Honor
                try {
                    val bundle = Bundle().apply {
                        putString("package", context.packageName)
                        putString("class", launcherClass)
                        putInt("badgenumber", count)
                    }
                    context.contentResolver.call(
                        Uri.parse("content://com.huawei.android.launcher.settings/badge/"),
                        "change_badge",
                        null,
                        bundle
                    )
                } catch (_: Exception) {}

                // 5. OPPO / Realme ColorOS
                try {
                    val extras = Bundle().apply {
                        putInt("app_badge_count", count)
                    }
                    context.contentResolver.call(
                        Uri.parse("content://com.android.badge/badge"),
                        "setAppBadgeCount",
                        null,
                        extras
                    )
                } catch (_: Exception) {}

                // 6. Vivo OriginOS / FuntouchOS
                try {
                    val vivoIntent = Intent("launcher.action.CHANGE_APPLICATION_NOTIFICATION_NUM").apply {
                        putExtra("packageName", context.packageName)
                        putExtra("className", launcherClass)
                        putExtra("notificationNum", count)
                    }
                    context.sendBroadcast(vivoIntent)
                } catch (_: Exception) {}
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update launcher badge: ${e.message}")
            }
        }

        fun showSystemNotification(
            context: Context,
            title: String,
            body: String,
            channelId: String = CHANNEL_ACTIVITY,
            notifId: Int = ((System.currentTimeMillis() % 70000L) + 1000L).toInt(),
            fromBankSync: Boolean = false,
            finoraAction: String? = null
        ): Boolean {
            return try {
                ensureNotificationChannels(context)
                if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                    return false
                }
                val safeNotifId = if (notifId == BADGE_NOTIFICATION_ID) BADGE_NOTIFICATION_ID - 1 else notifId
                val notificationManager =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP
                    if (fromBankSync) putExtra("from_bank_sync", true)
                    if (!finoraAction.isNullOrBlank()) putExtra("finora_action", finoraAction)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    safeNotifId,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                )

                val builder = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(R.drawable.finora_bank_notification)
                    .setContentTitle(title)
                    .setContentText(body)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                    .setPriority(
                        if (channelId == CHANNEL_BANK_SYNC) NotificationCompat.PRIORITY_HIGH
                        else NotificationCompat.PRIORITY_DEFAULT
                    )
                    .setGroup("finora_events_group")
                    .setAutoCancel(true)
                    .setContentIntent(pendingIntent)

                notificationManager.notify(safeNotifId, builder.build())
                true
            } catch (e: Exception) {
                Log.w(TAG, "Failed to show system notification: ${e.message}")
                false
            }
        }


        fun isAliveAndConnected(): Boolean {
            if (connected) return true
            val inst = instance ?: return false
            return try {
                inst.activeNotifications != null
            } catch (_: Exception) {
                false
            }
        }

        fun requestReconnect(context: Context) {
            try {
                val pm = context.packageManager
                val componentName = ComponentName(context, FinoraBankNotificationListenerService::class.java)
                pm.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP
                )
                pm.setComponentEnabledSetting(
                    componentName,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    try {
                        requestRebind(componentName)
                    } catch (_: Exception) {}
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to request reconnect", e)
            }
        }

        fun acknowledge(context: Context, ids: List<String>) = synchronized(queueLock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val pending = JSONArray(prefs.getString(KEY_PENDING_NOTIFICATIONS, "[]"))
            val keep = JSONArray()
            for (i in 0 until pending.length()) {
                val raw = pending.getString(i)
                if (JSONObject(raw).optString("id") !in ids) keep.put(raw)
            }
            val handled = (prefs.getStringSet(KEY_HANDLED, emptySet()) ?: emptySet()).toMutableSet()
            handled.addAll(ids)
            // Keep IDs, not notification bodies, for replay prevention.
            val ok = prefs.edit().putString(KEY_PENDING_NOTIFICATIONS, keep.toString())
                .putStringSet(KEY_HANDLED, handled).commit()
            if (ok) {
                refreshCombinedBadge(context)
                FinoraWidgetHelper.syncNativePendingCount(context, keep.length())
                FinoraWidgetHelper.updateAllWidgets(context)
            }
            ok
        }

        // Set of known Vietnamese banking and wallet packages
        val BANK_PACKAGES = setOf(
            // Vietcombank
            "com.VCB",
            "com.vietcombank.mobile",
            // Techcombank
            "vn.com.techcombank.bb.app",
            "com.techcombank.mobile",
            // MB Bank
            "com.mbmobile",
            "com.mb.mbbank",
            // ACB
            "mobile.acb.com.vn",
            "com.acb.mobile",
            // VPBank
            "com.vnpay.vpbankonline",
            "com.vpbank.online",
            "com.vpbank.neo",
            // BIDV
            "com.vnpay.bidv",
            "com.bidv.smartbanking",
            // VietinBank
            "com.vietinbank.ipay",
            // TPBank
            "com.tpb.mb.gprsandroid",
            "com.tpbank.mobile",
            // Sacombank
            "com.vnpay.sacombank",
            "com.sacombank.mplus",
            // Agribank
            "com.vnpay.agribank",
            // VIB
            "com.vib.vibmobile",
            // HDBank
            "com.vnpay.hdbank",
            // MSB
            "com.vnpay.msb",
            // OCB
            "com.ocb.omni",
            // SHB
            "vn.shb.mbanking",
            // Eximbank
            "com.vnpay.eximbank",
            // SeABank
            "vn.com.seabank.mb1",
            // Digital banks
            "timo.vn.bank",
            "vn.timo",
            "xyz.be.cake",
            "com.cake.bank",
            "vn.liobank",
            "com.vnpay.vietcapitalbank",
            "com.kasikornbank.kplus.vn",
            "com.vnpay.agribankplus",
            "com.vib.myvib2",
            "vn.com.msb.smartBanking",
            "com.ocb.omni.app",
            "vn.com.lpb.lienviet24h",
            "vn.com.lpbank.mobile",
            "vn.com.abbank.mobile",
            "com.vnpay.abbank",
            "com.vnpay.baca",
            "com.vnpay.namabank",
            // NCB (Ngân hàng Quốc Dân) - iziMobile & iziBiz
            "com.ncb.bank",
            "com.ncb.izimobile",
            "vn.com.ncb.izimobile",
            "com.vnpay.ncb",
            "com.ncb.izibiz",
            "vn.com.ncb.izibiz",
            // Additional Vietnamese Banks & Digital Banks
            "vn.com.techcombank.bb.app",
            "com.mbmobile",
            "com.VCB",
            "com.vietinbank.ipay",
            "vn.com.bidv.smartbanking",
            "com.vnpay.bidv",
            "com.agribank.agribankplus",
            "com.vnpay.agribank",
            "vn.tpb.mb.g0sales",
            "com.tpb.mb.g0sales",
            "com.vnpay.vpbankonline",
            "vn.com.vpbank.neo",
            "com.scb.mobile",
            "com.hdbank.hdbank",
            "com.vnpay.hdbank",
            "com.vnpay.PvcomBank",
            "com.pvcombank.pvc",
            "vn.com.seabank.mb1",
            "com.seabank.seabankmobile",
            "vn.shb.mb",
            "com.shb.mb",
            "com.vnpay.shb",
            "vn.com.eximbank.edigi",
            "com.vnpay.eximbank",
            "com.oceanbank.easyocean",
            "com.vnpay.oceanbank",
            "com.kienlongbank.plus",
            "com.klb.mobile",
            "com.vnpay.klb",
            "com.vietabank.vietabank",
            "com.vnpay.vietabank",
            "com.baovietbank.baovietbank",
            "com.vnpay.baoviet",
            "com.pgbank.flex",
            "com.vnpay.pgbank",
            "com.saigonbank.saigonbankmobile",
            "com.vnpay.saigonbank",
            "vn.com.vietbank.digital",
            "com.vnpay.vietbank",
            "com.wooribank.smart.vn",
            "com.shinhan.global.vn.bank",
            "com.hsbc.hsbcvietnam",
            "scb.mobile.vn",
            "vn.uob.tmrw.app",
            "com.cimb.octovn",
            "vn.com.banviet.timo",
            "io.timo.app",
            "vn.cake.app",
            "vn.tnex.consumer",
            "vn.lio.bank",
            "com.kbank.kplusvn",
            "timo.vn.bank",
            "xyz.be.cake",
            "com.tpb.mb.gprsandroid",
            "mobile.acb.com.vn",
            "vn.shb.mbanking",
            "com.vib.vibmobile",
            "com.vnpay.sacombank",
            "com.vnpay.msb",
            "com.ocb.omni",
            "com.airpay.merchants",
            "com.shopeepay.vn",
            // E-Wallets
            "com.mservice.momotransfer",
            "com.mservice.momopay",
            "vn.com.vng.zalopay",
            "com.vng.zalopay",
            "com.b2c.bankplus",
            "com.bplus.vtpay",
            "com.viettel.viettelpay",
            "vn.vnpay.vnpay",
            "com.airpay",
            // E-Commerce (Shopee / TikTok Shop / Lazada)
            "com.shopee.vn",
            "com.ss.android.ugc.trill",
            "com.zhiliaoapp.musically",
            "com.lazada.android"
        )

        val ECOMMERCE_PACKAGES = setOf(
            "com.shopee.vn",
            "com.ss.android.ugc.trill",
            "com.zhiliaoapp.musically",
            "com.lazada.android"
        )

        // Android SMS / Messaging packages
        val SMS_PACKAGES = setOf(
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.miui.mms",
            "com.oppo.mms",
            "com.coloros.mms",
            "com.oplus.mms",
            "com.vivo.mms",
            "com.huawei.message"
        )

        // Known bank names / sender aliases for SMS & push filtering
        val BANK_KEYWORDS = listOf(
            "vcb", "vcb digibank", "vietcombank",
            "techcombank", "tcb",
            "mbbank", "mb bank",
            "acb",
            "vpbank",
            "bidv",
            "vietinbank",
            "tpbank",
            "sacombank",
            "agribank",
            "vib",
            "hdbank",
            "msb",
            "ocb",
            "shb",
            "eximbank",
            "seabank",
            "cake",
            "timo",
            "liobank",
            "momo",
            "zalopay",
            "viettelmoney", "viettel money", "viettelpay",
            "vnpay", "namabank", "nam a bank", "bacabank", "bac a bank",
            "vietbank", "pvcombank", "ncb", "abbank", "kienlongbank",
            "bvbank", "vietcapitalbank", "saigonbank", "pgbank", "shinhan",
            "woori", "hsbc", "uob", "cimb", "publicbank", "vietabank", "shopeepay",
            "shopee", "tiktok", "tiktok shop", "lazada"
        )

        val MONEY_INDICATORS = listOf(
            "vnd", "vnd.", "đ", "₫",
            "gd:", "giao dich", "giao dịch",
            "so du", "số dư", "sd:",
            "bien dong", "biến động",
            "thanh toan", "thanh toán",
            "chuyen tien", "chuyển tiền", "chuyen khoan", "chuyển khoản",
            "nhan tien", "nhận tiền", "nhan duoc", "nhận được",
            "đơn hàng", "don hang", "đặt hàng", "dat hang",
            "+", "-"
        )

        // Callback hook to active MainActivity
        var onNotificationReceivedListener: ((JSONObject) -> Unit)? = null

        fun getPendingNotifications(context: Context): List<String> = synchronized(queueLock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val array = JSONArray(prefs.getString(KEY_PENDING_NOTIFICATIONS, "[]"))
            (0 until array.length()).map { array.getString(it) }
        }

        fun queueNotification(context: Context, jsonObj: JSONObject): Boolean = synchronized(queueLock) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val id = jsonObj.getString("id")
            if (id in (prefs.getStringSet(KEY_HANDLED, emptySet()) ?: emptySet())) return@synchronized false
            val array = JSONArray(prefs.getString(KEY_PENDING_NOTIFICATIONS, "[]"))
            for (i in 0 until array.length()) {
                if (JSONObject(array.getString(i)).optString("id") == id) return@synchronized false
            }
            array.put(jsonObj.toString())
            // Never drop pending financial events just because the app has not opened.
            val ok = prefs.edit().putString(KEY_PENDING_NOTIFICATIONS, array.toString())
                .putLong("lastReceivedAt", jsonObj.getLong("timestamp")).commit()
            if (ok) {
                refreshCombinedBadge(context)
                FinoraWidgetHelper.syncNativePendingCount(context, array.length())
                FinoraWidgetHelper.updateAllWidgets(context)
            }
            ok
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        ensureNotificationChannels(applicationContext)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        connected = true
        onConnectionStatusChanged?.invoke(true)
        // Android can deliver notifications before Flutter starts listening.
        try { activeNotifications?.forEach { onNotificationPosted(it) } }
        catch (_: Exception) { /* Notification access may have been revoked. */ }
    }

    override fun onListenerDisconnected() {
        connected = false
        onConnectionStatusChanged?.invoke(false)
        super.onListenerDisconnected()
        requestReconnect(this)
    }

    override fun onDestroy() {
        instance = null
        connected = false
        onConnectionStatusChanged?.invoke(false)
        super.onDestroy()
    }

    private fun showCapturedNotification(context: Context, title: String, text: String, pkg: String = "") {
        try {
            ensureNotificationChannels(context)
            if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                return
            }
            val channelId = CHANNEL_BANK_SYNC
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_bank_sync", true)
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                System.currentTimeMillis().toInt(),
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            // Determine bank name from package, title or text
            val combined = "$pkg $title $text".lowercase()
            val bankName = when {
                combined.contains("vcb") || combined.contains("vietcombank") -> "Vietcombank"
                combined.contains("mbbank") || combined.contains("mb bank") || combined.contains("mbmobile") || combined.contains("quân đội") -> "MB Bank"
                combined.contains("techcombank") || combined.contains("tcb") -> "Techcombank"
                combined.contains("vietinbank") || combined.contains("vtb") || combined.contains("ctg") -> "VietinBank"
                combined.contains("acb") || combined.contains("á châu") || combined.contains("a chau") -> "ACB"
                combined.contains("vpbank") || combined.contains("vpb") -> "VPBank"
                combined.contains("bidv") -> "BIDV"
                combined.contains("tpbank") || combined.contains("tpb") -> "TPBank"
                combined.contains("agribank") || combined.contains("vba") -> "Agribank"
                combined.contains("sacombank") || combined.contains("stb") -> "Sacombank"
                combined.contains("vib") -> "VIB"
                combined.contains("ocb") -> "OCB"
                combined.contains("msb") -> "MSB"
                combined.contains("shb") -> "SHB"
                combined.contains("hdbank") -> "HDBank"
                combined.contains("ncb") || combined.contains("izimobile") || combined.contains("izibiz") || combined.contains("quốc dân") || combined.contains("quoc dan") -> "NCB"
                combined.contains("msb") -> "MSB"
                combined.contains("ocb") -> "OCB"
                combined.contains("lpbank") || combined.contains("lienviet") -> "LPBank"
                combined.contains("abbank") -> "ABBANK"
                combined.contains("baca") -> "Bac A Bank"
                combined.contains("namabank") -> "Nam A Bank"
                combined.contains("seabank") -> "SeABank"
                combined.contains("eximbank") -> "Eximbank"
                combined.contains("pvcombank") -> "PVcomBank"
                combined.contains("kienlong") || combined.contains("klb") -> "KienlongBank"
                combined.contains("vietabank") -> "VietABank"
                combined.contains("vietbank") -> "VietBank"
                combined.contains("baoviet") -> "BaoViet Bank"
                combined.contains("pgbank") -> "PGBank"
                combined.contains("saigonbank") -> "SAIGONBANK"
                combined.contains("oceanbank") -> "OceanBank"
                combined.contains("timo") -> "Timo"
                combined.contains("cake") -> "CAKE"
                combined.contains("tnex") -> "TNEX"
                combined.contains("lio") -> "Liobank"
                combined.contains("shinhan") -> "Shinhan Bank"
                combined.contains("woori") -> "Woori Bank"
                combined.contains("hsbc") -> "HSBC"
                combined.contains("uob") -> "UOB"
                combined.contains("cimb") -> "CIMB"
                combined.contains("kbank") || combined.contains("kplus") -> "KBank"
                combined.contains("momo") -> "Ví MoMo"
                combined.contains("zalopay") -> "Ví ZaloPay"
                combined.contains("viettel") -> "Viettel Money"
                combined.contains("vnpay") -> "Ví VNPay"
                combined.contains("shopee") -> "ShopeePay"
                combined.contains("vnpt") -> "VNPT Money"
                combined.contains("payoo") -> "Payoo"
                combined.contains("foxpay") -> "Foxpay"
                title.isNotBlank() -> title.trim()
                else -> "Ngân hàng"
            }

            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val notifyExpense = prefs.getBoolean("finora_notify_bank_expense", true)
            val notifyIncome = prefs.getBoolean("finora_notify_bank_income", true)
            val notifyShowAmount = prefs.getBoolean("finora_notify_show_amount", true)

            val fullLower = "$title $text".lowercase()
            val isLikelyIncome = fullLower.contains("+") ||
                fullLower.contains("nhận") || fullLower.contains("nhan") ||
                fullLower.contains("cộng") || fullLower.contains("cong") ||
                fullLower.contains("chuyển đến") || fullLower.contains("chuyen den")
            if (isLikelyIncome && !notifyIncome) return
            if (!isLikelyIncome && !notifyExpense) return

            val notifTitle = "$bankName: Biến động số dư mới"
            val notifContent = if (!notifyShowAmount) {
                "Có biến động mới từ $bankName • Chạm để mở FINORA xem chi tiết."
            } else if (text.isNotBlank()) {
                text.lines().firstOrNull()?.take(70) ?: "Mở FINORA để kiểm tra và ghi vào sổ."
            } else {
                "Mở FINORA để kiểm tra và ghi vào sổ."
            }

            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.finora_bank_notification)
                .setContentTitle(notifTitle)
                .setContentText(notifContent)
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)

            // Load app icon as large icon if available
            if (pkg.isNotEmpty()) {
                try {
                    val appIcon = context.packageManager.getApplicationIcon(pkg)
                    val bitmap = if (appIcon is BitmapDrawable) {
                        appIcon.bitmap
                    } else {
                        val w = appIcon.intrinsicWidth.coerceAtLeast(1)
                        val h = appIcon.intrinsicHeight.coerceAtLeast(1)
                        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                        val canvas = Canvas(bmp)
                        appIcon.setBounds(0, 0, canvas.width, canvas.height)
                        appIcon.draw(canvas)
                        bmp
                    }
                    builder.setLargeIcon(bitmap)
                } catch (_: Exception) {}
            }

            if (pendingIntent != null) {
                builder.setContentIntent(pendingIntent)
            }

            val notifId = ((System.currentTimeMillis() % 70000L) + 1000L).toInt()
            notificationManager.notify(notifId, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show captured notification: ${e.message}")
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        val notification = sbn.notification ?: return
        if ((notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        val extras = notification.extras ?: return

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""
        val summaryText = extras.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString() ?: ""
        val infoText = extras.getCharSequence(Notification.EXTRA_INFO_TEXT)?.toString() ?: ""
        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.joinToString("\n") ?: ""
        val messages = Notification.MessagingStyle.Message.getMessagesFromBundleArray(
            extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        ).joinToString("\n") { it.text?.toString() ?: "" }
        val parts = listOf(bigText, lines, messages, text, subText, summaryText, infoText)
            .filter { it.isNotBlank() }
            .distinct()
        val combinedText = parts.filter { part -> parts.none { other -> other.length > part.length && other.contains(part) } }.joinToString("\n")

        if (title.isEmpty() && combinedText.isEmpty()) return

        val lowerTitle = title.lowercase()
        val lowerText = combinedText.lowercase()
        val combinedLower = "$lowerTitle $lowerText"

        // 1. Zero OTP Leakage Security Check: Never capture security codes or OTP
        if (combinedLower.contains("otp") || 
            combinedLower.contains("mã xác thực") || 
            combinedLower.contains("ma xac thuc") || 
            combinedLower.contains("smart otp") || 
            combinedLower.contains("password") || 
            combinedLower.contains("mật khẩu") || 
            combinedLower.contains("cảnh báo bảo mật") ||
            combinedLower.contains("mat khau") ||
            combinedLower.contains("verification code") ||
            combinedLower.contains("security code")) {
            return
        }

        // Financial source allowlist. Content mentioning a bank never grants
        // a shopping/chat app permission to create financial drafts.
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val walletsEnabled = prefs.getBoolean("finora_scan_ewallets", true)
        val walletPackages = setOf(
            "com.mservice.momotransfer", "com.mservice.momopay", "vn.momo.app",
            "vn.com.vng.zalopay", "com.vng.zalopay",
            "com.b2c.bankplus", "com.bplus.vtpay", "com.viettel.viettelpay",
            "vn.vnpay.vnpay", "vn.vnpay.ewallet",
            "com.airpay", "com.shopeepay.vn",
            "vn.payoo.app", "com.vnpt.epay", "vn.vnptpay.app",
            "vn.foxpay.app", "com.fpt.foxpay", "vn.moca.app"
        )
        val normalizedPackage = pkg.lowercase()
        val ncbPackageFallback = (normalizedPackage.startsWith("com.ncb.") ||
            normalizedPackage.startsWith("vn.com.ncb.")) &&
            !normalizedPackage.contains("otp")
        val directBank = (BANK_PACKAGES.any { it.lowercase() == normalizedPackage } || ncbPackageFallback) &&
            normalizedPackage !in ECOMMERCE_PACKAGES.map { it.lowercase() } &&
            normalizedPackage !in walletPackages.map { it.lowercase() }
        val directWallet = walletsEnabled && normalizedPackage in walletPackages.map { it.lowercase() }
        val walletSenders = setOf("momo", "zalopay", "viettelmoney", "viettel money", "viettelpay", "vnpay", "shopeepay")
        val trustedSmsSender = pkg in SMS_PACKAGES && BANK_KEYWORDS.any {
            it !in setOf("shopee", "tiktok", "tiktok shop", "lazada") &&
                (lowerTitle.contains(it) || it == lowerTitle.trim() || lowerText.contains(it)) &&
                (walletsEnabled || it !in walletSenders)
        }
        if (!directBank && !directWallet && !trustedSmsSender) return

        // No financial notification content in logcat.
        val eventTime = notification.`when`.takeIf { it > 0 } ?: sbn.postTime
        val fingerprint = "$pkg|${sbn.key}|$eventTime|$title|$combinedText"
        val eventId = MessageDigest.getInstance("SHA-256").digest(fingerprint.toByteArray())
            .joinToString("") { "%02x".format(it) }

        val json = JSONObject().apply {
            put("id", eventId)
            put("package", pkg)
            put("title", title)
            put("text", combinedText)
            put("timestamp", sbn.postTime)
        }

        // 1. Always queue locally so Flutter catches it even if background/killed
        if (!queueNotification(applicationContext, json)) return

        // 2. Show heads-up Android notification in system tray
        showCapturedNotification(applicationContext, title, combinedText, pkg)

        // 3. Notify active Flutter listener if foreground
        val listener = onNotificationReceivedListener
        if (listener != null) {
            try {
                listener(json)
            } catch (e: Exception) {
                Log.e(TAG, "Error invoking Flutter listener: ${e.message}")
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
    }
}
