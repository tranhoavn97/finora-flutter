package com.finora.finora

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.provider.Settings
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.abs

object FinoraWidgetHelper {
    const val PREFS_WIDGET = "finora_home_widget_prefs"
    private const val KEY_PAYLOAD = "widget_payload_json"
    const val ACTION_REFRESH_WIDGETS = "com.finora.app.ACTION_REFRESH_WIDGETS"

    data class PendingItem(
        val bankName: String,
        val headline: String,
        val snippet: String,
        val amountText: String,
        val timeText: String,
        val isPositive: Boolean,
        val timestamp: Long
    )

    data class RecentTxItem(
        val title: String,
        val meta: String,
        val amount: Double,
        val type: String
    )

    data class WidgetSnapshot(
        val todayExpense: Double,
        val todayCount: Int,
        val monthExpense: Double,
        val monthIncome: Double,
        val totalBalance: Double,
        val hideAmounts: Boolean,
        val syncedAt: String,
        val recent: List<RecentTxItem>,
        val pendingItems: List<PendingItem>,
        val pendingCount: Int,
        val listenerEnabled: Boolean
    )

    fun savePayload(context: Context, jsonStr: String) {
        val prefs = context.getSharedPreferences(PREFS_WIDGET, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_PAYLOAD, jsonStr).commit()
        updateAllWidgets(context)
    }

    fun updateAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids5x2 = manager.getAppWidgetIds(
            ComponentName(context, FinoraWidget5x2Provider::class.java)
        )
        if (ids5x2.isNotEmpty()) {
            update5x2(context, manager, ids5x2)
        }
        val ids5x4 = manager.getAppWidgetIds(
            ComponentName(context, FinoraWidget5x4Provider::class.java)
        )
        if (ids5x4.isNotEmpty()) {
            update5x4(context, manager, ids5x4)
        }
    }

    fun update5x2(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        val snap = loadSnapshot(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.finora_widget_5x2)
            bindCommonHeader(
                context = context,
                views = views,
                snap = snap,
                refreshProviderClass = FinoraWidget5x2Provider::class.java,
                requestBase = 5200
            )

            // Left tile: direct today + month + balance summary
            views.setTextViewText(
                R.id.widget_today_expense,
                if (snap.hideAmounts) "•••••• đ"
                else if (snap.todayExpense > 0) "-${formatVnd(snap.todayExpense)}"
                else "0 đ"
            )
            views.setTextViewText(
                R.id.widget_month_summary,
                if (snap.hideAmounts) {
                    "Tháng: •••• • Ví: ••••"
                } else {
                    "Tháng: ${formatCompact(snap.monthExpense)} • Ví: ${formatCompact(snap.totalBalance)}"
                }
            )

            // Right tile: Pending bank balance items needing recording
            bindPendingHeaderVisuals(views, snap)
            val first = snap.pendingItems.firstOrNull()
            if (snap.pendingCount > 0 && first != null) {
                val amt = if (snap.hideAmounts) "•••• đ" else first.amountText
                val headline = if (amt.isNotBlank()) "${first.bankName} • $amt" else first.headline
                views.setTextViewText(R.id.widget_pending_headline, headline)
                val sub = buildString {
                    if (first.snippet.isNotBlank()) append(first.snippet)
                    if (first.timeText.isNotBlank()) {
                        if (isNotEmpty()) append(" • ")
                        append(first.timeText)
                    }
                    if (snap.pendingCount > 1) {
                        append(" (+${snap.pendingCount - 1} nữa)")
                    }
                }
                views.setTextViewText(
                    R.id.widget_pending_sub,
                    if (snap.hideAmounts) "${snap.pendingCount} biến động đang chờ ghi sổ" else sub.ifBlank { "Chạm để kiểm tra & ghi sổ" }
                )
            } else {
                views.setTextViewText(
                    R.id.widget_pending_headline,
                    if (snap.listenerEnabled) "Không có biến động chờ" else "Chưa bật đọc số dư"
                )
                views.setTextViewText(
                    R.id.widget_pending_sub,
                    if (snap.listenerEnabled) {
                        "Chạm để mở hộp thư số dư →"
                    } else {
                        "Chạm để bật tự động đọc ngân hàng →"
                    }
                )
            }

            manager.updateAppWidget(appWidgetId, views)
        }
    }

    fun update5x4(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        val snap = loadSnapshot(context)
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.finora_widget_5x4)
            bindCommonHeader(
                context = context,
                views = views,
                snap = snap,
                refreshProviderClass = FinoraWidget5x4Provider::class.java,
                requestBase = 5400
            )

            // Top 3 KPI tiles
            views.setTextViewText(
                R.id.widget_today_expense,
                if (snap.hideAmounts) "•••••• đ"
                else if (snap.todayExpense > 0) "-${formatVnd(snap.todayExpense)}"
                else "0 đ"
            )
            views.setTextViewText(
                R.id.widget_today_count,
                "${snap.todayCount} giao dịch"
            )
            views.setTextViewText(
                R.id.widget_month_expense,
                if (snap.hideAmounts) "•••••• đ" else formatVnd(snap.monthExpense)
            )
            views.setTextViewText(
                R.id.widget_month_income,
                if (snap.hideAmounts) "Thu: ••••" else "Thu: +${formatCompact(snap.monthIncome)}"
            )
            views.setTextViewText(
                R.id.widget_total_balance,
                if (snap.hideAmounts) "•••••• đ" else formatVnd(snap.totalBalance)
            )

            // Middle section: Pending bank queue (up to 2 rows)
            bindPendingHeaderVisuals(views, snap)
            val p1 = snap.pendingItems.getOrNull(0)
            val p2 = snap.pendingItems.getOrNull(1)
            if (p1 != null) {
                views.setViewVisibility(R.id.widget_pending_row_1, View.VISIBLE)
                views.setViewVisibility(R.id.widget_pending_empty, View.GONE)
                bindPendingRow(
                    views = views,
                    item = p1,
                    hideAmounts = snap.hideAmounts,
                    dotId = R.id.widget_pending_row_1_dot,
                    titleId = R.id.widget_pending_row_1_title,
                    subId = R.id.widget_pending_row_1_sub,
                    amountId = R.id.widget_pending_row_1_amount,
                    timeId = R.id.widget_pending_row_1_time
                )
            } else {
                views.setViewVisibility(R.id.widget_pending_row_1, View.GONE)
                views.setViewVisibility(R.id.widget_pending_empty, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_pending_empty,
                    if (snap.listenerEnabled) {
                        "Mọi biến động số dư đã được ghi chép đầy đủ. Chạm để mở hộp thư số dư."
                    } else {
                        "Bật quyền đọc thông báo ngân hàng trong FINORA để theo dõi số dư chờ tại đây."
                    }
                )
            }

            if (p2 != null) {
                views.setViewVisibility(R.id.widget_pending_row_2, View.VISIBLE)
                bindPendingRow(
                    views = views,
                    item = p2,
                    hideAmounts = snap.hideAmounts,
                    dotId = R.id.widget_pending_row_2_dot,
                    titleId = R.id.widget_pending_row_2_title,
                    subId = R.id.widget_pending_row_2_sub,
                    amountId = R.id.widget_pending_row_2_amount,
                    timeId = R.id.widget_pending_row_2_time
                )
            } else {
                views.setViewVisibility(R.id.widget_pending_row_2, View.GONE)
            }

            val remaining = snap.pendingCount - 2
            if (remaining > 0) {
                views.setViewVisibility(R.id.widget_pending_more, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_pending_more,
                    "+$remaining biến động khác đang chờ trong hộp thư →"
                )
            } else {
                views.setViewVisibility(R.id.widget_pending_more, View.GONE)
            }

            // Bottom section: Recent transactions (up to 3 rows)
            val r1 = snap.recent.getOrNull(0)
            val r2 = snap.recent.getOrNull(1)
            val r3 = snap.recent.getOrNull(2)
            views.setViewVisibility(
                R.id.widget_recent_empty,
                if (snap.recent.isEmpty()) View.VISIBLE else View.GONE
            )
            bindRecentRow(
                views, r1, snap.hideAmounts,
                R.id.widget_recent_row_1, R.id.widget_recent_1_dot,
                R.id.widget_recent_1_title, R.id.widget_recent_1_meta, R.id.widget_recent_1_amount
            )
            bindRecentRow(
                views, r2, snap.hideAmounts,
                R.id.widget_recent_row_2, R.id.widget_recent_2_dot,
                R.id.widget_recent_2_title, R.id.widget_recent_2_meta, R.id.widget_recent_2_amount
            )
            bindRecentRow(
                views, r3, snap.hideAmounts,
                R.id.widget_recent_row_3, R.id.widget_recent_3_dot,
                R.id.widget_recent_3_title, R.id.widget_recent_3_meta, R.id.widget_recent_3_amount
            )

            views.setOnClickPendingIntent(
                R.id.widget_recent_section,
                createLaunchPendingIntent(context, 5410, "open_dashboard", false)
            )

            manager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun bindCommonHeader(
        context: Context,
        views: RemoteViews,
        snap: WidgetSnapshot,
        refreshProviderClass: Class<*>,
        requestBase: Int
    ) {
        views.setTextViewText(
            R.id.widget_sync_time,
            if (snap.syncedAt.isNotBlank()) "Đồng bộ ${snap.syncedAt}" else "Theo dõi trực tiếp"
        )

        val openHomePi = createLaunchPendingIntent(context, requestBase + 1, "open_dashboard", false)
        val openInboxPi = createLaunchPendingIntent(context, requestBase + 2, "open_bank_inbox", true)
        val quickAddPi = createLaunchPendingIntent(context, requestBase + 3, "add_transaction", false)
        val refreshIntent = Intent(context, refreshProviderClass).apply {
            action = ACTION_REFRESH_WIDGETS
        }
        val refreshPi = PendingIntent.getBroadcast(
            context,
            requestBase + 4,
            refreshIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        views.setOnClickPendingIntent(R.id.widget_root, openHomePi)
        views.setOnClickPendingIntent(R.id.widget_header, openHomePi)
        views.setOnClickPendingIntent(R.id.widget_pending_card, openInboxPi)
        views.setOnClickPendingIntent(R.id.widget_btn_quick_add, quickAddPi)
        views.setOnClickPendingIntent(R.id.widget_btn_refresh, refreshPi)
    }

    private fun bindPendingHeaderVisuals(views: RemoteViews, snap: WidgetSnapshot) {
        if (snap.pendingCount > 0) {
            views.setInt(R.id.widget_pending_card, "setBackgroundResource", R.drawable.finora_widget_amber_card_bg)
            views.setInt(R.id.widget_pending_badge_pill, "setBackgroundResource", R.drawable.finora_widget_pill_amber)
            views.setTextColor(R.id.widget_pending_badge_pill, Color.parseColor("#FEF3C7"))
            views.setTextViewText(R.id.widget_pending_badge_pill, "${snap.pendingCount} chờ ghi")
        } else {
            views.setInt(R.id.widget_pending_card, "setBackgroundResource", R.drawable.finora_widget_emerald_card_bg)
            views.setInt(R.id.widget_pending_badge_pill, "setBackgroundResource", R.drawable.finora_widget_pill_emerald)
            views.setTextColor(R.id.widget_pending_badge_pill, Color.parseColor("#D1FAE5"))
            views.setTextViewText(
                R.id.widget_pending_badge_pill,
                if (snap.listenerEnabled) "Đã ghi đủ" else "Chưa bật"
            )
        }
    }

    private fun bindPendingRow(
        views: RemoteViews,
        item: PendingItem,
        hideAmounts: Boolean,
        dotId: Int,
        titleId: Int,
        subId: Int,
        amountId: Int,
        timeId: Int
    ) {
        val accent = if (item.isPositive) Color.parseColor("#34D399") else Color.parseColor("#FB7185")
        views.setInt(dotId, "setColorFilter", Color.parseColor("#FBBF24"))
        views.setTextViewText(titleId, item.bankName)
        views.setTextViewText(
            subId,
            if (hideAmounts) "Biến động đang chờ ghi sổ" else item.snippet.ifBlank { item.headline }
        )
        views.setTextViewText(
            amountId,
            if (hideAmounts) "•••• đ" else item.amountText.ifBlank { "Chờ duyệt" }
        )
        views.setTextColor(amountId, if (item.amountText.isBlank()) Color.parseColor("#FCD34D") else accent)
        views.setTextViewText(timeId, item.timeText)
    }

    private fun bindRecentRow(
        views: RemoteViews,
        item: RecentTxItem?,
        hideAmounts: Boolean,
        rowId: Int,
        dotId: Int,
        titleId: Int,
        metaId: Int,
        amountId: Int
    ) {
        if (item == null) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }
        views.setViewVisibility(rowId, View.VISIBLE)
        val isIncome = item.type.equals("income", ignoreCase = true) || item.amount > 0
        val isTransfer = item.type.equals("transfer", ignoreCase = true)
        val dotColor = when {
            isTransfer -> Color.parseColor("#38BDF8")
            isIncome -> Color.parseColor("#34D399")
            else -> Color.parseColor("#FB7185")
        }
        views.setInt(dotId, "setColorFilter", dotColor)
        views.setTextViewText(titleId, item.title)
        views.setTextViewText(metaId, item.meta)
        views.setTextColor(amountId, dotColor)
        val amountDisplay = if (hideAmounts) {
            "•••••• đ"
        } else {
            val prefix = when {
                isTransfer -> ""
                isIncome -> "+"
                else -> "-"
            }
            "$prefix${formatVnd(abs(item.amount))}"
        }
        views.setTextViewText(amountId, amountDisplay)
    }

    fun loadSnapshot(context: Context): WidgetSnapshot {
        val widgetPrefs = context.getSharedPreferences(PREFS_WIDGET, Context.MODE_PRIVATE)
        val rawPayload = widgetPrefs.getString(KEY_PAYLOAD, null)
        val payload = try {
            if (!rawPayload.isNullOrBlank()) JSONObject(rawPayload) else JSONObject()
        } catch (_: Exception) {
            JSONObject()
        }

        val bankPrefs = context.getSharedPreferences(
            FinoraBankNotificationListenerService.PREFS_NAME,
            Context.MODE_PRIVATE
        )
        val rawPendingArray = try {
            JSONArray(bankPrefs.getString(FinoraBankNotificationListenerService.KEY_PENDING_NOTIFICATIONS, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }

        val nativePending = mutableListOf<PendingItem>()
        for (i in 0 until rawPendingArray.length()) {
            val rawEntry = rawPendingArray.optString(i, "")
            if (rawEntry.isBlank()) continue
            val obj = try { JSONObject(rawEntry) } catch (_: Exception) { null } ?: continue
            val pkg = obj.optString("package", "")
            val title = obj.optString("title", "")
            val text = obj.optString("text", "")
            val ts = obj.optLong("timestamp", 0L)
            nativePending.add(parsePendingItem(pkg, title, text, ts))
        }
        nativePending.sortByDescending { it.timestamp }

        val recent = mutableListOf<RecentTxItem>()
        val recentArr = payload.optJSONArray("recent")
        if (recentArr != null) {
            for (i in 0 until recentArr.length()) {
                val obj = recentArr.optJSONObject(i) ?: continue
                recent.add(
                    RecentTxItem(
                        title = obj.optString("title", "Giao dịch"),
                        meta = obj.optString("meta", ""),
                        amount = obj.optDouble("amount", 0.0),
                        type = obj.optString("type", "expense")
                    )
                )
            }
        }

        // Also allow Flutter payload to pass unrecognized count or fallback queue count
        val flutterPendingCount = payload.optInt("pendingCount", 0)
        val effectivePendingCount = maxOf(nativePending.size, flutterPendingCount)
        val timeFmt = SimpleDateFormat("HH:mm", Locale.getDefault())
        val fallbackSynced = timeFmt.format(Date())

        return WidgetSnapshot(
            todayExpense = payload.optDouble("todayExpense", 0.0),
            todayCount = payload.optInt("todayCount", 0),
            monthExpense = payload.optDouble("monthExpense", 0.0),
            monthIncome = payload.optDouble("monthIncome", 0.0),
            totalBalance = payload.optDouble("totalBalance", 0.0),
            hideAmounts = payload.optBoolean("hideAmounts", false),
            syncedAt = payload.optString("syncedAt", "").ifBlank { fallbackSynced },
            recent = recent,
            pendingItems = nativePending,
            pendingCount = effectivePendingCount,
            listenerEnabled = isNotificationListenerEnabled(context)
        )
    }

    private fun parsePendingItem(
        pkg: String,
        title: String,
        text: String,
        ts: Long
    ): PendingItem {
        val bankName = detectBankName(pkg, title, text)
        val (amountText, isPositive) = extractSignedAmount(title, text)
        val firstLine = text.lines()
            .map { it.trim() }
            .firstOrNull { it.isNotBlank() }
            ?: title.trim()
        val timeText = if (ts > 0L) {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(ts))
        } else {
            ""
        }
        return PendingItem(
            bankName = bankName,
            headline = if (title.isNotBlank()) title.trim() else bankName,
            snippet = firstLine.take(58),
            amountText = amountText,
            timeText = timeText,
            isPositive = isPositive,
            timestamp = ts
        )
    }

    private fun detectBankName(pkg: String, title: String, text: String): String {
        val combined = "$pkg $title $text".lowercase(Locale.ROOT)
        return when {
            combined.contains("ncb") || combined.contains("izimobile") ||
                combined.contains("izibiz") || combined.contains("quốc dân") ||
                combined.contains("quoc dan") -> "NCB"
            combined.contains("vcb") || combined.contains("vietcombank") -> "Vietcombank"
            combined.contains("mbbank") || combined.contains("mb bank") ||
                combined.contains("mbmobile") || combined.contains("quân đội") -> "MB Bank"
            combined.contains("techcombank") || combined.contains("tcb") -> "Techcombank"
            combined.contains("vietinbank") || combined.contains("ipay") || combined.contains("ctg") -> "VietinBank"
            combined.contains("acb") -> "ACB"
            combined.contains("vpbank") || combined.contains("vpb") -> "VPBank"
            combined.contains("bidv") -> "BIDV"
            combined.contains("tpbank") || combined.contains("tpb") -> "TPBank"
            combined.contains("agribank") -> "Agribank"
            combined.contains("sacombank") || combined.contains("stb") -> "Sacombank"
            combined.contains("vib") -> "VIB"
            combined.contains("ocb") -> "OCB"
            combined.contains("msb") -> "MSB"
            combined.contains("shb") -> "SHB"
            combined.contains("hdbank") -> "HDBank"
            combined.contains("lpbank") || combined.contains("lienviet") -> "LPBank"
            combined.contains("seabank") -> "SeABank"
            combined.contains("eximbank") -> "Eximbank"
            combined.contains("timo") -> "Timo"
            combined.contains("cake") -> "CAKE"
            combined.contains("tnex") -> "TNEX"
            combined.contains("momo") -> "MoMo"
            combined.contains("zalopay") -> "ZaloPay"
            combined.contains("viettel") -> "Viettel Money"
            combined.contains("vnpay") -> "VNPay"
            combined.contains("shopeepay") -> "ShopeePay"
            title.isNotBlank() -> title.trim().take(24)
            else -> "Ngân hàng"
        }
    }

    private fun extractSignedAmount(title: String, text: String): Pair<String, Boolean> {
        val full = "$title\n$text"
        val lower = full.lowercase(Locale.ROOT)
        // Prefer explicitly signed amounts like +1,000,000 VND or -55.000đ
        val signedRegex = Regex("""([+-])\s*(\d{1,3}(?:[.,]\d{3})+|\d{4,12})(?:\s*(?:vnd|đ|₫))?""", RegexOption.IGNORE_CASE)
        val matches = signedRegex.findAll(full).toList()
        val chosen = matches.firstOrNull { m ->
            val before = full.substring(0, m.range.first).lowercase(Locale.ROOT)
            val tail = before.takeLast(20)
            !tail.contains("số dư") && !tail.contains("so du") && !tail.contains("sd:")
        } ?: matches.firstOrNull()

        if (chosen != null) {
            val sign = chosen.groupValues[1]
            val digits = chosen.groupValues[2].replace(".", "").replace(",", "").toDoubleOrNull()
            if (digits != null && digits >= 100) {
                val isPos = sign == "+"
                return "$sign${formatVnd(digits)}" to isPos
            }
        }

        val plainRegex = Regex("""(\d{1,3}(?:[.,]\d{3})+)\s*(?:vnd|đ|₫)""", RegexOption.IGNORE_CASE)
        val plainMatch = plainRegex.find(full)
        if (plainMatch != null) {
            val digits = plainMatch.groupValues[1].replace(".", "").replace(",", "").toDoubleOrNull()
            if (digits != null && digits >= 100) {
                val isPos = lower.contains("nhận") || lower.contains("nhan") ||
                    lower.contains("cộng") || lower.contains("cong") ||
                    lower.contains("nạp") || lower.contains("nap")
                val prefix = if (isPos) "+" else "-"
                return "$prefix${formatVnd(digits)}" to isPos
            }
        }
        return "" to false
    }

    private fun isNotificationListenerEnabled(context: Context): Boolean {
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        ) ?: ""
        return enabled.contains(context.packageName)
    }

    private fun createLaunchPendingIntent(
        context: Context,
        requestCode: Int,
        finoraAction: String?,
        fromBankSync: Boolean
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_SINGLE_TOP or
                Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (fromBankSync) {
                putExtra("from_bank_sync", true)
            }
            if (!finoraAction.isNullOrBlank()) {
                putExtra("finora_action", finoraAction)
            }
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )
    }

    private fun formatVnd(amount: Double): String {
        val symbols = DecimalFormatSymbols(Locale("vi", "VN")).apply {
            groupingSeparator = '.'
            decimalSeparator = ','
        }
        val df = DecimalFormat("#,##0", symbols)
        return "${df.format(amount.toLong())} đ"
    }

    private fun formatCompact(amount: Double): String {
        val absVal = abs(amount)
        val sign = if (amount < 0) "-" else ""
        return when {
            absVal >= 1_000_000_000 -> String.format(Locale.US, "%s%.1ftỷ", sign, absVal / 1_000_000_000.0).replace('.', ',')
            absVal >= 1_000_000 -> String.format(Locale.US, "%s%.1ftr", sign, absVal / 1_000_000.0).replace('.', ',')
            absVal >= 1_000 -> "${sign}${(absVal / 1_000).toLong()}k"
            else -> "${sign}${absVal.toLong()}đ"
        }
    }
}
