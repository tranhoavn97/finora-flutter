import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/services/bank_notification_parser.dart';
import '../../core/services/bank_sync_service.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/bank_transaction_prompt_sheet.dart';
import '../../core/widgets/finora_notice.dart';

class BankInboxView extends StatefulWidget {
  final String userId;
  const BankInboxView({super.key, required this.userId});

  @override
  State<BankInboxView> createState() => _BankInboxViewState();
}

class _BankInboxViewState extends State<BankInboxView> {
  final _bank = BankSyncService();
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final granted = await _bank.isPermissionGranted();
    await _bank.reconnect();
    if (mounted) setState(() => _granted = granted);
  }

  Future<void> _review(ParsedBankTransaction tx) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BankTransactionPromptSheet(
        tx: tx,
        userId: widget.userId,
      ),
    );
  }

  Future<void> _showPasteNotificationModal(bool isDark) async {
    final bankCtrl = TextEditingController(text: 'Techcombank');
    final contentCtrl = TextEditingController();
    final created = await showModalBottomSheet<ParsedBankTransaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF059669).withValues(alpha: 0.32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Bóc tách thông báo Ngân hàng / Shopee / TikTok',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tự động tách Mã giao dịch chính, nhận diện chuyển khoản cùng máy, trả thẻ tín dụng & đơn Shopee/TikTok.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bankCtrl,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: const [FinoraCapitalizeFirstFormatter()],
                decoration: InputDecoration(
                  labelText: 'Ngân hàng hoặc Ứng dụng (Techcombank, VCB, Shopee...)',
                  prefixIcon: const Icon(Icons.account_balance_rounded, size: 18),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nội dung biến động số dư / SMS ngân hàng',
                  hintText:
                      'VD: TK 1903... -250,000 VND. ND: FT263039912 Thanh toan don Shopee',
                  prefixIcon: const Icon(Icons.receipt_long_rounded, size: 18),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        final rawText = contentCtrl.text.trim();
                        if (rawText.isEmpty) return;
                        final parsed = _bank.injectManualNotification(
                          title: bankCtrl.text.trim().isNotEmpty
                              ? bankCtrl.text.trim()
                              : 'Ngân hàng',
                          text: rawText,
                        );
                        Navigator.pop(ctx, parsed);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                      label: const Text(
                        'Phân tích & Mở lưu',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (created != null && mounted) {
      await _review(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _bank,
      builder: (context, _) {
        final pending = _bank.pending;
        final unrecognized = _bank.unrecognized;
        final incomeCount = pending.where((e) => e.type == 'income').length;
        final expenseCount = pending.where((e) => e.type == 'expense').length;
        final transferCount = pending.where((e) => e.isTransfer).length;

        return RefreshIndicator(
          color: const Color(0xFF059669),
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              _StatusCard(
                granted: _granted,
                connected: _bank.connected,
                error: _bank.error,
                onRefresh: _refresh,
                onOpenPasteModal: () => _showPasteNotificationModal(isDark),
              ),
              if (pending.isNotEmpty) ...[
                const SizedBox(height: 12),
                // Summary Bar for Pending Transactions
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đã bóc tách ${pending.length} biến động số dư',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (transferCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0284C7).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$transferCount CK',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      if (incomeCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF059669).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '+$incomeCount Thu',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      if (expenseCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE11D48).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '-$expenseCount Chi',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (pending.isEmpty && unrecognized.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.18 : 0.10),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          size: 30,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Không có giao dịch ngân hàng chờ xử lý',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Khi ngân hàng, Shopee hoặc TikTok báo biến động số dư, Finora sẽ tự tách Mã giao dịch chính và giữ lại ở đây.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ...pending.map(
                (tx) => _PendingTile(
                  tx: tx,
                  onReview: () => _review(tx),
                  onDismiss: () => _bank.acknowledge(tx.rawId),
                ),
              ),
              if (unrecognized.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Thông báo ngân hàng chưa đọc được số tiền (${unrecognized.length})',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...unrecognized.entries.map(
                  (entry) => _UnrecognizedTile(
                    rawId: entry.key,
                    title: entry.value.title,
                    text: entry.value.text,
                    onReview: () => _review(
                      BankNotificationParser.fromUnrecognized(
                        rawId: entry.key,
                        title: entry.value.title,
                        text: entry.value.text,
                      ),
                    ),
                    onAcknowledge: () => _bank.acknowledge(entry.key),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool? granted;
  final bool connected;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback onOpenPasteModal;
  const _StatusCard({
    required this.granted,
    required this.connected,
    required this.error,
    required this.onRefresh,
    required this.onOpenPasteModal,
  });

  @override
  Widget build(BuildContext context) {
    final bank = BankSyncService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final needsPermission = !kIsWeb && granted == false;
    final Color statusColor = kIsWeb
        ? const Color(0xFF059669)
        : (needsPermission
            ? const Color(0xFFE11D48)
            : (connected ? const Color(0xFF059669) : const Color(0xFFD97706)));

    final title = kIsWeb
        ? 'Đồng bộ Mã giao dịch Ngân hàng (Web & Mobile)'
        : (needsPermission
            ? 'Chưa bật quyền đọc thông báo ngân hàng'
            : connected
                ? 'Đang lắng nghe Ngân hàng · Shopee · TikTok'
                : 'Dịch vụ đọc thông báo chưa kết nối');
    final subtitle = error ??
        (kIsWeb
            ? 'Dán nhanh nội dung SMS/thông báo ngân hàng để tự động gán Mã giao dịch chính & ghi chú riêng.'
            : (needsPermission
                ? 'Bật quyền Thông báo thiết bị & ứng dụng cho Finora để tự nhận biến động số dư.'
                : connected
                    ? 'Tự động nhận diện Thu/Chi, Chuyển khoản cùng máy, Trả thẻ tín dụng & đơn Shopee/TikTok.'
                    : 'Nếu Android vừa khởi động lại hoặc chặn dịch vụ chạy nền, hãy chạm kết nối lại.'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  needsPermission
                      ? Icons.notifications_paused_rounded
                      : (connected || kIsWeb
                          ? Icons.verified_user_rounded
                          : Icons.sync_problem_rounded),
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (kIsWeb) {
                    onOpenPasteModal();
                  } else if (needsPermission) {
                    bank.requestPermission();
                  } else if (!connected) {
                    bank.openAppInfo();
                  } else {
                    onRefresh();
                  }
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Text(
                    kIsWeb
                        ? 'Dán thông báo'
                        : (needsPermission
                            ? 'Cấp quyền'
                            : connected
                                ? 'Làm mới'
                                : 'Mở cài đặt'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onOpenPasteModal,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669)
                        .withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF059669).withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.content_paste_go_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Dán nhanh thông báo Ngân hàng / Shopee / TikTok',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  final ParsedBankTransaction tx;
  final VoidCallback onReview;
  final VoidCallback onDismiss;
  const _PendingTile({
    required this.tx,
    required this.onReview,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == 'income';
    final isTransfer = tx.isTransfer;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isTransfer
        ? const Color(0xFF0284C7)
        : (isIncome ? const Color(0xFF059669) : const Color(0xFFE11D48));
    final sign = isTransfer ? '⇄ ' : (isIncome ? '+' : '-');
    final timeStr = DateFormat('HH:mm • dd/MM/yyyy').format(tx.timestamp);
    final acct = tx.accountNumber?.trim() ?? '';
    final txCode =
        tx.transactionCode.trim().isNotEmpty ? tx.transactionCode.trim() : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.35 : 0.22),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Center(
                        child: BankIcon(
                          bankCode: tx.bankCode,
                          bankName: tx.bankName,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tx.matchedTransferBankName != null
                                      ? '${tx.bankName} → ${tx.matchedTransferBankName}'
                                      : tx.bankName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tx.isCreditCardPayment
                                      ? 'Trả thẻ TD'
                                      : (isTransfer
                                          ? 'CK nội bộ'
                                          : (isIncome
                                              ? 'Thu nhập'
                                              : 'Chi tiêu')),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (acct.isNotEmpty) ...[
                                Text(
                                  'TK $acct',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  timeStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$sign${formatVND(tx.amount.round())}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16.5,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (txCode.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.16 : 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tag_rounded, size: 13, color: color),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Mã GD chính: $txCode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withValues(alpha: 0.65)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.notes_rounded,
                        size: 15,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tx.note,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onDismiss();
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReview();
                        },
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isTransfer
                                  ? const [Color(0xFF0284C7), Color(0xFF0369A1)]
                                  : (isIncome
                                      ? const [
                                          Color(0xFF059669),
                                          Color(0xFF047857)
                                        ]
                                      : const [
                                          Color(0xFFE11D48),
                                          Color(0xFFBE123C)
                                        ]),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Kiểm tra & ghi vào sổ',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnrecognizedTile extends StatelessWidget {
  final String rawId;
  final String title;
  final String text;
  final VoidCallback onReview;
  final VoidCallback onAcknowledge;
  const _UnrecognizedTile({
    required this.rawId,
    required this.title,
    required this.text,
    required this.onReview,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            onReview();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD97706).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFD97706).withValues(alpha: 0.14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 18,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Thông báo ngân hàng' : title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onAcknowledge();
                      },
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Bỏ qua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onReview();
                        },
                        child: Container(
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF047857)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Chọn danh mục & Lưu',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
