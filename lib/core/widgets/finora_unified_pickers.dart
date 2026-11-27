import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/category.dart';
import '../../data/models/wallet.dart';
import '../utils/formatters.dart';
import '../utils/search.dart';
import 'bank_icon.dart';
import 'bank_transaction_prompt_sheet.dart';
import 'glass_widgets.dart';

/// Unified Luxury Fintech pastel owner pill (matches Web CustomDropdown badges).
class FinoraOwnerPill extends StatelessWidget {
  final String owner;
  final String ownerName;
  final bool isDark;
  final bool compact;

  const FinoraOwnerPill({
    super.key,
    required this.owner,
    required this.ownerName,
    required this.isDark,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = owner.trim().toLowerCase();
    final isWife = normalized == 'wife' || ownerName.toLowerCase() == 'vợ';
    final isJoint = normalized == 'joint' ||
        normalized == 'shared' ||
        ownerName.toLowerCase() == 'chung';

    final Color bg;
    final Color border;
    final Color fg;

    if (isWife) {
      bg = isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2);
      border = isDark
          ? const Color(0xFF9F1239).withValues(alpha: 0.55)
          : const Color(0xFFFECDD3);
      fg = isDark ? const Color(0xFFFDA4AF) : const Color(0xFFE11D48);
    } else if (isJoint) {
      bg = isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB);
      border = isDark
          ? const Color(0xFF92400E).withValues(alpha: 0.55)
          : const Color(0xFFFDE68A);
      fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
    } else {
      bg = isDark ? const Color(0xFF082F49) : const Color(0xFFF0F9FF);
      border = isDark
          ? const Color(0xFF075985).withValues(alpha: 0.55)
          : const Color(0xFFBAE6FD);
      fg = isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 7,
        vertical: compact ? 1.5 : 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        ownerName.toUpperCase(),
        style: TextStyle(
          fontSize: compact ? 9 : 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          height: 1.05,
          color: fg,
        ),
      ),
    );
  }
}

String _walletAcctTag(Wallet w) {
  final digits = (w.accountNumber ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 4) {
    return '••${digits.substring(digits.length - 4)}';
  }
  if (digits.isNotEmpty) return '••$digits';
  return '';
}

String _walletTypeLabel(Wallet w) {
  if (w.isCreditCard) return 'Thẻ tín dụng';
  if (w.type == 'saving') return 'Tiết kiệm';
  if (w.type == 'bank') return 'Ngân hàng';
  return 'Tiền mặt';
}

/// Unified searchable Luxury Fintech wallet picker bottom sheet (matches Web CustomDropdown).
Future<Wallet?> showFinoraWalletPickerSheet({
  required BuildContext context,
  required List<Wallet> wallets,
  String? selectedWalletId,
  String title = 'Chọn ví / Tài khoản',
  String subtitle = 'Tìm nhanh theo tên ví, chủ sở hữu hoặc số tài khoản',
}) {
  if (wallets.isEmpty) return Future.value(null);
  HapticFeedback.selectionClick();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<Wallet>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      String searchQuery = '';
      return StatefulBuilder(
        builder: (ctx, setStateSheet) {
          final q = normalizeSearch(searchQuery);
          final filtered = q.isEmpty
              ? wallets
              : wallets.where((w) {
                  final resolved =
                      BankTransactionPromptSheet.resolveOwnerForWallet(w);
                  final haystack = normalizeSearch(
                    '${w.name} ${w.bankName ?? ''} ${w.bankCode ?? ''} '
                    '${resolved.ownerName} ${w.accountNumber ?? ''} ${_walletTypeLabel(w)}',
                  );
                  return haystack.contains(q);
                }).toList();

          return AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuad,
            child: GlassBottomSheet(
              radius: 30,
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669)
                                  .withValues(alpha: isDark ? 0.22 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 18,
                              color: Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) =>
                                    setStateSheet(() => searchQuery = val),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tìm ví, chủ ví (Chồng/Vợ), số TK...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: filtered.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                child: Text(
                                  'Không tìm thấy ví phù hợp',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final w = filtered[index];
                                  final selected = w.id == selectedWalletId;
                                  final resolved = BankTransactionPromptSheet
                                      .resolveOwnerForWallet(w);
                                  final acctTag = _walletAcctTag(w);
                                  final amountVal = w.isCreditCard
                                      ? w.currentDebt
                                      : w.balance;
                                  final amountLabel =
                                      w.isCreditCard ? 'Dư nợ' : 'Số dư';
                                  final amountColor = w.isCreditCard
                                      ? (w.currentDebt > 0
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFF059669))
                                      : (w.balance < 0
                                          ? const Color(0xFFE11D48)
                                          : const Color(0xFF059669));

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () => Navigator.pop(ctx, w),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? const Color(0xFF059669)
                                                  .withValues(
                                                      alpha:
                                                          isDark ? 0.20 : 0.09)
                                              : (isDark
                                                  ? Colors.white
                                                      .withValues(alpha: 0.04)
                                                  : const Color(0xFFF8FAFC)),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: selected
                                                ? const Color(0xFF059669)
                                                : (isDark
                                                    ? Colors.white
                                                        .withValues(alpha: 0.08)
                                                    : const Color(0xFFE2E8F0)),
                                            width: selected ? 1.4 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Clean borderless circular BankIcon
                                            BankIcon(
                                              bankCode: w.bankCode ?? w.type,
                                              bankName: w.bankName ?? w.name,
                                              customIconUrl: w.iconUrl,
                                              size: 38,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    w.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      FinoraOwnerPill(
                                                        owner: resolved.owner,
                                                        ownerName:
                                                            resolved.ownerName,
                                                        isDark: isDark,
                                                        compact: true,
                                                      ),
                                                      if (acctTag
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          acctTag,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontFamily:
                                                                'monospace',
                                                            color: isDark
                                                                ? const Color(
                                                                    0xFF94A3B8)
                                                                : const Color(
                                                                    0xFF64748B),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  formatVND(amountVal),
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: amountColor,
                                                    fontFeatures: const [
                                                      FontFeature
                                                          .tabularFigures(),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  amountLabel,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF94A3B8)
                                                        : const Color(
                                                            0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (selected) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF059669),
                                                size: 20,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Unified Luxury Fintech wallet trigger field (48px rounded-16, circular BankIcon, pastel owner pill, tabular balance).
class FinoraWalletPickerField extends StatelessWidget {
  final String? label;
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final ValueChanged<Wallet> onSelected;
  final String placeholder;
  final bool enabled;

  const FinoraWalletPickerField({
    super.key,
    this.label,
    required this.wallets,
    required this.selectedWalletId,
    required this.onSelected,
    this.placeholder = 'Chọn ví / Tài khoản',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected =
        wallets.where((w) => w.id == selectedWalletId).firstOrNull;
    final resolved = selected != null
        ? BankTransactionPromptSheet.resolveOwnerForWallet(selected)
        : null;
    final acctTag = selected != null ? _walletAcctTag(selected) : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFA3B4D4)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
              if (resolved != null)
                FinoraOwnerPill(
                  owner: resolved.owner,
                  ownerName: resolved.ownerName,
                  isDark: isDark,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled && wallets.isNotEmpty
                ? () async {
                    final picked = await showFinoraWalletPickerSheet(
                      context: context,
                      wallets: wallets,
                      selectedWalletId: selectedWalletId,
                      title: label ?? placeholder,
                    );
                    if (picked != null) {
                      onSelected(picked);
                    }
                  }
                : null,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  if (selected != null)
                    BankIcon(
                      bankCode: selected.bankCode ?? selected.type,
                      bankName: selected.bankName ?? selected.name,
                      customIconUrl: selected.iconUrl,
                      size: 28,
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: selected == null
                        ? Text(
                            placeholder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if (acctTag.isNotEmpty || label == null)
                                Row(
                                  children: [
                                    if (label == null && resolved != null) ...[
                                      FinoraOwnerPill(
                                        owner: resolved.owner,
                                        ownerName: resolved.ownerName,
                                        isDark: isDark,
                                        compact: true,
                                      ),
                                      if (acctTag.isNotEmpty)
                                        const SizedBox(width: 5),
                                    ],
                                    if (acctTag.isNotEmpty)
                                      Text(
                                        acctTag,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'monospace',
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                  if (selected != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      formatVND(
                        selected.isCreditCard
                            ? selected.currentDebt
                            : selected.balance,
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: selected.isCreditCard
                            ? const Color(0xFFE11D48)
                            : const Color(0xFF059669),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Unified searchable Luxury Fintech category picker bottom sheet.
Future<Category?> showFinoraCategoryPickerSheet({
  required BuildContext context,
  required List<Category> categories,
  String? selectedCategoryId,
  String title = 'Chọn danh mục',
  Color accent = const Color(0xFF059669),
}) {
  if (categories.isEmpty) return Future.value(null);
  HapticFeedback.selectionClick();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<Category>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      String searchQuery = '';
      bool isListView = true;
      return StatefulBuilder(
        builder: (ctx, setStateSheet) {
          final q = normalizeSearch(searchQuery);
          final filtered = q.isEmpty
              ? categories
              : categories
                  .where((c) => normalizeSearch(c.name).contains(q))
                  .toList();

          return AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuad,
            child: GlassBottomSheet(
              radius: 30,
              child: SafeArea(
                top: false,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.78,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  accent.withValues(alpha: isDark ? 0.22 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.category_rounded,
                              size: 18,
                              color: accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                setStateSheet(() => isListView = !isListView),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                isListView
                                    ? Icons.grid_view_rounded
                                    : Icons.view_list_rounded,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                onChanged: (val) =>
                                    setStateSheet(() => searchQuery = val),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Tìm nhanh danh mục...',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: filtered.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 28),
                                child: Text(
                                  'Không tìm thấy danh mục phù hợp',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              )
                            : isListView
                                ? ListView.separated(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (_, index) {
                                      final c = filtered[index];
                                      final selected =
                                          c.id == selectedCategoryId;
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          onTap: () => Navigator.pop(ctx, c),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 9,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? accent.withValues(
                                                      alpha:
                                                          isDark ? 0.22 : 0.10)
                                                  : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.04)
                                                      : const Color(
                                                          0xFFF8FAFC)),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: selected
                                                    ? accent
                                                    : (isDark
                                                        ? Colors.white
                                                            .withValues(
                                                                alpha: 0.08)
                                                        : const Color(
                                                            0xFFE2E8F0)),
                                                width: selected ? 1.4 : 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                CategoryIconBadge(
                                                  icon: c.icon,
                                                  categoryName: c.name,
                                                  colorHex: c.color,
                                                  size: 36,
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    c.name,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: selected
                                                          ? FontWeight.w800
                                                          : FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF0F172A),
                                                    ),
                                                  ),
                                                ),
                                                if (selected)
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    color: accent,
                                                    size: 20,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.85,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (_, index) {
                                      final c = filtered[index];
                                      final selected =
                                          c.id == selectedCategoryId;
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          onTap: () => Navigator.pop(ctx, c),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? accent.withValues(
                                                      alpha:
                                                          isDark ? 0.24 : 0.14)
                                                  : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.05)
                                                      : const Color(
                                                          0xFFF8FAFC)),
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: selected
                                                    ? accent
                                                    : (isDark
                                                        ? Colors.white12
                                                        : const Color(
                                                            0xFFE2E8F0)),
                                                width: selected ? 1.6 : 1.0,
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CategoryIconBadge(
                                                  icon: c.icon,
                                                  categoryName: c.name,
                                                  colorHex: c.color,
                                                  size: 36,
                                                  isDark: isDark,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  c.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: selected
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A),
                                                    height: 1.15,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Unified Luxury Fintech category trigger field (48px rounded-16, circular CategoryIconBadge).
class FinoraCategoryPickerField extends StatelessWidget {
  final String? label;
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category> onSelected;
  final String placeholder;
  final Color accent;
  final bool enabled;

  const FinoraCategoryPickerField({
    super.key,
    this.label,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.placeholder = 'Chọn danh mục',
    this.accent = const Color(0xFF059669),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected =
        categories.where((c) => c.id == selectedCategoryId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color:
                  isDark ? const Color(0xFFA3B4D4) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled && categories.isNotEmpty
                ? () async {
                    final picked = await showFinoraCategoryPickerSheet(
                      context: context,
                      categories: categories,
                      selectedCategoryId: selectedCategoryId,
                      title: label ?? placeholder,
                      accent: accent,
                    );
                    if (picked != null) {
                      onSelected(picked);
                    }
                  }
                : null,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  if (selected != null)
                    CategoryIconBadge(
                      icon: selected.icon,
                      categoryName: selected.name,
                      colorHex: selected.color,
                      size: 28,
                      isDark: isDark,
                    )
                  else
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected?.name ?? placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected != null
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected != null
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
