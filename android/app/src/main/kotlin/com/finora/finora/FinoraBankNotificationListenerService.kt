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
        @Volatile var instance: FinoraBankNotificationListenerService? = null
        @Volatile var connected = false
        var onConnectionStatusChanged: ((Boolean) -> Unit)? = null
        private val queueLock = Any()

        fun updateAppBadge(context: Context, count: Int) {
            try {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val badgeChannelId = "finora_app_badge_channel"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val channel = NotificationChannel(
                        badgeChannelId,
                        "FINORA Số thông báo",
                        NotificationManager.IMPORTANCE_MIN
                    ).apply {
                        setShowBadge(true)
                        description = "Hiển thị số lượng thông báo trên biểu tượng ứng dụng"
                    }
                    notificationManager.createNotificationChannel(channel)
                }

                if (count > 0) {
                    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                        flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        putExtra("from_bank_sync", true)
                    }
                    val pendingIntent = if (launchIntent != null) {
                        PendingIntent.getActivity(
                            context,
                            8888,
                            launchIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                        )
                    } else null

                    val builder = NotificationCompat.Builder(context, badgeChannelId)
                        .setSmallIcon(R.drawable.finora_bank_notification)
                        .setContentTitle("FINORA")
                        .setContentText("Có $count biến động số dư đang chờ xử lý")
                        .setNumber(count)
                        .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
                        .setPriority(NotificationCompat.PRIORITY_MIN)
                        .setOngoing(true)
                        .setAutoCancel(false)

                    if (pendingIntent != null) {
                        builder.setContentIntent(pendingIntent)
                    }
                    notificationManager.notify(88888, builder.build())
                } else {
                    notificationManager.cancel(88888)
                }

                // 1. Samsung OneUI Badge
                try {
                    val contentUri = Uri.parse("content://com.sec.android.provider.badge/apps")
                    val contentValues = ContentValues().apply {
                        put("package", context.packageName)
                        put("class", "com.finora.finora.MainActivity")
                        put("badgecount", count)
                    }
                    context.contentResolver.insert(contentUri, contentValues)
                } catch (_: Exception) {}

                // 2. Xiaomi / MIUI / HyperOS Badge
                try {
                    val miuiIntent = Intent("android.intent.action.APPLICATION_MESSAGE_UPDATE")
                    miuiIntent.putExtra("android.intent.extra.update_application_component_name", "${context.packageName}/com.finora.finora.MainActivity")
                    miuiIntent.putExtra("android.intent.extra.update_application_message_text", if (count > 0) count.toString() else "")
                    context.sendBroadcast(miuiIntent)
                } catch (_: Exception) {}

                // 3. Sony
                try {
                    val sonyIntent = Intent("com.sonyericsson.home.action.UPDATE_BADGE")
                    sonyIntent.putExtra("com.sonyericsson.home.intent.extra.badge.PACKAGE_NAME", context.packageName)
                    sonyIntent.putExtra("com.sonyericsson.home.intent.extra.badge.ACTIVITY_NAME", "com.finora.finora.MainActivity")
                    sonyIntent.putExtra("com.sonyericsson.home.intent.extra.badge.MESSAGE", count.toString())
                    sonyIntent.putExtra("com.sonyericsson.home.intent.extra.badge.SHOW_MESSAGE", count > 0)
                    context.sendBroadcast(sonyIntent)
                } catch (_: Exception) {}

                // 4. Huawei / Honor
                try {
                    val bundle = Bundle().apply {
                        putString("package", context.packageName)
                        putString("class", "com.finora.finora.MainActivity")
                        putInt("badgenumber", count)
                    }
                    context.contentResolver.call(Uri.parse("content://com.huawei.android.launcher.settings/badge/"), "change_badge", null, bundle)
                } catch (_: Exception) {}
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update launcher badge: ${e.message}")
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
            if (ok) updateAppBadge(context, keep.length())
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
            if (ok) updateAppBadge(context, array.length())
            ok
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
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
            val channelId = "finora_bank_sync_channel"
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    channelId,
                    "FINORA Nhận diện giao dịch ngân hàng",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Thông báo nhận diện biến động số dư ngân hàng tự động"
                    enableVibration(true)
                    setShowBadge(true)
                }
                notificationManager.createNotificationChannel(channel)
            }

            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_bank_sync", true)
            }
            val pendingIntent = if (launchIntent != null) {
                PendingIntent.getActivity(
                    context,
                    System.currentTimeMillis().toInt(),
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                )
            } else null

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

            val notifTitle = "$bankName: Biến động số dư mới"
            val notifContent = if (text.isNotBlank()) text.lines().firstOrNull()?.take(70) ?: "Mở FINORA để kiểm tra và ghi vào sổ." else "Mở FINORA để kiểm tra và ghi vào sổ."

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

            val notifId = (System.currentTimeMillis() % 100000).toInt()
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
