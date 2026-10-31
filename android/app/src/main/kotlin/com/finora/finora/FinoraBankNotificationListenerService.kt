package com.finora.finora

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import android.content.Context
import android.content.ComponentName
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
        @Volatile var connected = false
        private val queueLock = Any()

        fun requestReconnect(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !connected) {
                requestRebind(ComponentName(context, FinoraBankNotificationListenerService::class.java))
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
            prefs.edit().putString(KEY_PENDING_NOTIFICATIONS, keep.toString())
                .putStringSet(KEY_HANDLED, handled).commit()
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
            prefs.edit().putString(KEY_PENDING_NOTIFICATIONS, array.toString())
                .putLong("lastReceivedAt", jsonObj.getLong("timestamp")).commit()
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        connected = true
        // Android can deliver notifications before Flutter starts listening.
        try { activeNotifications?.forEach { onNotificationPosted(it) } }
        catch (_: Exception) { /* Notification access may have been revoked. */ }
    }

    override fun onListenerDisconnected() {
        connected = false
        super.onListenerDisconnected()
        requestReconnect(this)
    }

    override fun onDestroy() {
        connected = false
        super.onDestroy()
    }

    private fun showCapturedNotification(context: Context, title: String, text: String) {
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

            val notifTitle = "FINORA: Có thông báo ngân hàng cần kiểm tra"
            val builder = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(R.drawable.finora_bank_notification)
                .setContentTitle(notifTitle)
                .setContentText("Mở FINORA để kiểm tra và ghi vào sổ.")
                .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)

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
        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.joinToString("\n") ?: ""
        val messages = Notification.MessagingStyle.Message.getMessagesFromBundleArray(
            extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        ).joinToString("\n") { it.text?.toString() ?: "" }
        val parts = listOf(bigText, lines, messages, text).filter { it.isNotBlank() }.distinct()
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
            "com.mservice.momotransfer", "com.mservice.momopay", "vn.com.vng.zalopay",
            "com.vng.zalopay", "com.b2c.bankplus", "com.bplus.vtpay",
            "com.viettel.viettelpay", "vn.vnpay.vnpay", "com.airpay"
        )
        val normalizedPackage = pkg.lowercase()
        val directBank = BANK_PACKAGES.any { it.lowercase() == normalizedPackage } &&
            pkg !in ECOMMERCE_PACKAGES && pkg !in walletPackages
        val directWallet = walletsEnabled && pkg in walletPackages
        val walletSenders = setOf("momo", "zalopay", "viettelmoney", "viettel money", "viettelpay", "vnpay", "shopeepay")
        val trustedSmsSender = pkg in SMS_PACKAGES && BANK_KEYWORDS.any {
            it !in setOf("shopee", "tiktok", "tiktok shop", "lazada") && lowerTitle.trim() == it &&
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
        showCapturedNotification(applicationContext, title, combinedText)

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
