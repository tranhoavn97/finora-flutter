import '../../core/widgets/finora_member_filter.dart';
import '../../core/widgets/finora_modal_scope.dart';
import '../../core/widgets/finora_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/finora_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/bank_icon.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/services/wallet_repository.dart';
import '../../domain/finance/transaction_member.dart';
import '../../state/theme_studio_controller.dart';
import '../../state/transaction_provider.dart';
import '../../state/wallet_provider.dart';
import '../planning/planning_hub_screen.dart';
import '../wallet/wealth_hub_screen.dart';
import 'add_transaction_page.dart';

/// Modal Chi Tiết Giao Dịch — thiết kế hiện đại, rõ nét, luôn nền đặc 100%.
Future<void> showTransactionDetailSheet(
  BuildContext context, {
  required String userId,
  required TransactionModel transaction,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (sheetContext) => FinoraModalScope(
      child: Theme(
        data: FinoraModalScope.opaqueModalTheme(sheetContext),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: _TransactionDetailModalContent(
              userId: userId,
              transaction: transaction,
            ),
          ),
        ),
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == 'open_source') {
    if (transaction.goalId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlanningHubScreen(
            userId: userId,
            initialTabIndex: 1,
          ),
        ),
      );
    } else if (transaction.loanId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WealthHubScreen(
            userId: userId,
            initialTabIndex: 3,
          ),
        ),
      );
    } else if (transaction.assetId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WealthHubScreen(
            userId: userId,
            initialTabIndex: 2,
          ),
        ),
      );
    }
    return;
  }

  if (action == 'edit') {
    if (transaction.loanId != null ||
        transaction.goalId != null ||
        transaction.assetId != null) {
      final sourceName = transaction.goalId != null
          ? 'Mục tiêu tài chính'
          : (transaction.loanId != null ? 'Khoản nợ' : 'Tài sản');
      FinoraNotice.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Giao dịch liên kết với $sourceName. Hãy cập nhật từ màn hình nguồn.',
          ),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Mở nguồn',
            textColor: Colors.white,
            onPressed: () {
              if (transaction.goalId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlanningHubScreen(
                      userId: userId,
                      initialTabIndex: 1,
                    ),
                  ),
                );
              } else if (transaction.loanId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WealthHubScreen(
                      userId: userId,
                      initialTabIndex: 3,
                    ),
                  ),
                );
              } else if (transaction.assetId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WealthHubScreen(
                      userId: userId,
                      initialTabIndex: 2,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AddTransactionPage(userId: userId, existing: transaction),
      ),
    );
  } else if (action == 'delete') {
    final confirm = await showConfirmDeleteDialog(
      context: context,
      title: 'Xóa giao dịch này?',
      content:
          'Số dư ví và báo cáo liên quan sẽ được tự động cập nhật lại ngay sau khi xóa.',
    );
    if (confirm && context.mounted) {
      await context.read<TransactionProvider>().delete(userId, transaction.id);
      if (context.mounted) {
        FinoraNotice.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _TransactionDetailModalContent extends StatelessWidget {
  final String userId;
  final TransactionModel transaction;

  const _TransactionDetailModalContent({
    required this.userId,
    required this.transaction,
  });

  Wallet? _resolveWallet(
    List<Wallet> wallets,
    String? targetId,
    String? targetName,
  ) {
    if (wallets.isEmpty) return null;
    if (targetId != null && targetId.trim().isNotEmpty) {
      for (final w in wallets) {
        if (w.id == targetId) return w;
      }
    }
    if (targetName != null && targetName.trim().isNotEmpty) {
      final norm = targetName.trim().toLowerCase();
      for (final w in wallets) {
        if (w.name.trim().toLowerCase() == norm ||
            (w.bankName?.trim().toLowerCase() == norm)) {
          return w;
        }
      }
    }
    return null;
  }

  String? _resolveBankCode(Wallet? wallet, String? fallbackName) {
    final rawCode = wallet?.bankCode?.trim();
    if (rawCode != null && rawCode.isNotEmpty) {
      return rawCode;
    }
    final combined = [
      wallet?.bankName,
      wallet?.name,
      fallbackName,
    ].whereType<String>().join(' ').toLowerCase();
    if (combined.contains('ncb') ||
        combined.contains('quốc dân') ||
        combined.contains('quoc dan')) {
      return 'ncb';
    }
    if (combined.contains('mb') ||
        combined.contains('tiết kiệm') ||
        combined.contains('tiet kiem')) {
      return 'mbbank';
    }
    if (combined.contains('techcom') || combined.contains('tcb')) {
      return 'tcb';
    }
    if (combined.contains('vietcom') || combined.contains('vcb')) {
      return 'vcb';
    }
    if (combined.contains('tiền mặt') || combined.contains('tien mat')) {
      return 'cash';
    }
    final typeCode = wallet?.type.trim();
    if (typeCode != null && typeCode.isNotEmpty) {
      return typeCode;
    }
    return null;
  }

  TransactionMember _resolveMember(TransactionModel tx, Wallet? matchingWallet) {
    final txExplicit = resolveMemberFields([
      tx.owner,
      tx.creatorTag,
      tx.ownerName,
      tx.creatorName,
      tx.fromOwner,
      tx.paidByOwner,
    ]);
    if (txExplicit != TransactionMember.unknown) {
      return txExplicit;
    }
    final walletResolved = resolveMemberFields([
      matchingWallet?.owner,
      matchingWallet?.ownerName,
    ]);
    if (walletResolved != TransactionMember.unknown) {
      return walletResolved;
    }
    final candidates = <String?>[
      tx.owner,
      tx.creatorTag,
      matchingWallet?.owner,
      tx.ownerName,
      tx.creatorName,
      tx.fromOwner,
      tx.paidByOwner,
      ...tx.tags,
      matchingWallet?.ownerName,
    ];
    for (final raw in candidates) {
      if (raw == null) continue;
      final v = raw.trim().toLowerCase();
      if (v.isEmpty) continue;
      if (v == 'wife' ||
          v == 'vợ' ||
          v == 'vo' ||
          v == 'female' ||
          v == 'bà xã' ||
          v.contains('vợ') ||
          v.contains('wife')) {
        return TransactionMember.wife;
      }
      if (v == 'husband' ||
          v == 'chồng' ||
          v == 'chong' ||
          v == 'male' ||
          v == 'ông xã' ||
          v.contains('chồng') ||
          v.contains('husband')) {
        return TransactionMember.husband;
      }
      if (v == 'joint' || v == 'shared' || v == 'family' || v == 'chung') {
        return TransactionMember.joint;
      }
    }
    return TransactionMember.husband;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studio = Provider.of<ThemeStudioController?>(context, listen: true);
    final brandPrimary = studio?.resolvedPrimary ?? const Color(0xFF0F6E56);
    final brandSecondary =
        studio?.resolvedSecondary ?? const Color(0xFF10B981);
    final txProvider =
        Provider.of<TransactionProvider?>(context, listen: false);
    final walletProvider = Provider.of<WalletProvider?>(context, listen: false);
    final allWallets = <Wallet>[
      ...?txProvider?.wallets,
      ...?walletProvider?.wallets,
    ];
    final tx = transaction;

    final matchingWallet = _resolveWallet(
      allWallets,
      tx.walletId ?? tx.fromWalletId,
      tx.walletName ?? tx.fromWalletName,
    );
    final sourceBankCode = _resolveBankCode(
      matchingWallet,
      tx.walletName ?? tx.fromWalletName,
    );
    final sourceBankName = matchingWallet?.bankName ??
        matchingWallet?.name ??
        tx.walletName ??
        tx.fromWalletName;

    final destWallet = _resolveWallet(
      allWallets,
      tx.toWalletId ?? tx.creditCardId,
      tx.toWalletName ?? tx.creditCardName,
    );
    final destBankCode = _resolveBankCode(
      destWallet,
      tx.toWalletName ?? tx.creditCardName,
    );
    final destBankName = destWallet?.bankName ??
        destWallet?.name ??
        tx.toWalletName ??
        tx.creditCardName;

    final normType = WalletRepository.normalizeTransactionType(tx.type);
    final isInflow =
        {'income', 'borrowing', 'loan_repayment_received'}.contains(normType);
    final isTransfer = normType == 'transfer';

    final List<Color> heroGradientColors;
    final Color heroAccent;
    final Color heroShadowColor;
    final String sign;
    final String statusBadgeText;

    if (isTransfer) {
      heroGradientColors = const [Color(0xFF0284C7), Color(0xFF2563EB)];
      heroAccent = const Color(0xFF0284C7);
      heroShadowColor = const Color(0xFF0284C7).withValues(alpha: 0.30);
      statusBadgeText = 'CHUYỂN KHOẢN NỘI BỘ';
      sign = '';
    } else if (isInflow) {
      heroGradientColors = const [Color(0xFF059669), Color(0xFF10B981)];
      heroAccent = const Color(0xFF059669);
      heroShadowColor = const Color(0xFF059669).withValues(alpha: 0.30);
      statusBadgeText =
          normType == 'borrowing' ? 'KHOẢN ĐI VAY' : 'TIỀN VÀO · THU NHẬP';
      sign = '+';
    } else {
      heroGradientColors = const [Color(0xFFE11D48), Color(0xFFF43F5E)];
      heroAccent = const Color(0xFFE11D48);
      heroShadowColor = const Color(0xFFE11D48).withValues(alpha: 0.30);
      statusBadgeText =
          normType == 'loan' ? 'KHOẢN CHO VAY' : 'TIỀN RA · CHI TIÊU';
      sign = '−';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(
      tx.date > 100000000000 ? tx.date : tx.date * 1000,
    );
    final formattedTime = DateFormat('HH:mm').format(date);
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final weekdayName = _getWeekdayVietnamese(date.weekday);

    final hasCustomNote = tx.note != null && tx.note!.trim().isNotEmpty;
    final displayTitle =
        hasCustomNote ? tx.note!.trim() : (tx.categoryName ?? 'Giao dịch');

    final member = _resolveMember(tx, matchingWallet);
    final String? memberKey = switch (member) {
      TransactionMember.husband => 'husband',
      TransactionMember.wife => 'wife',
      TransactionMember.joint || TransactionMember.unknown => null,
    };
    final String memberDisplayLabel = switch (member) {
      TransactionMember.husband =>
        studio?.husbandDisplayLabel ?? TransactionMember.husband.label,
      TransactionMember.wife =>
        studio?.wifeDisplayLabel ?? TransactionMember.wife.label,
      TransactionMember.joint => TransactionMember.joint.label,
      TransactionMember.unknown => TransactionMember.joint.label,
    };
    final Color memberAccentColor = switch (member) {
      TransactionMember.wife => const Color(0xFFDB2777),
      TransactionMember.husband => const Color(0xFF0284C7),
      TransactionMember.joint || TransactionMember.unknown =>
        const Color(0xFF059669),
    };

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        0,
        10,
        0,
        MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. TOP SHEET HEADER BAR (Drag Handle + Title + Close Pill)
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 13.5,
                        color: brandPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Chi tiết giao dịch',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'BeVietnamPro',
                          color: isDark
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).maybePop();
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. SLEEK HERO GRADIENT CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: heroGradientColors,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: heroShadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Single crisp circular category badge
                Container(
                  width: 62,
                  height: 62,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.78),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CategoryIconBadge(
                      icon: tx.categoryIcon,
                      categoryName: tx.categoryName,
                      size: 58,
                      isDark: false,
                    ),
                  ),
                ),
                const SizedBox(height: 11),

                // Type badge capsule
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.36),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTransfer
                            ? Icons.swap_horiz_rounded
                            : (isInflow
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded),
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusBadgeText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Bold tabular amount
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '$sign${NumberFormat('#,##0', 'vi_VN').format(tx.amount)}',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            letterSpacing: -0.8,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const TextSpan(text: ' '),
                        const TextSpan(
                          text: 'đ',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'BeVietnamPro',
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            decorationThickness: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Timestamp capsule
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13.5,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$formattedTime · $weekdayName, $formattedDate',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'BeVietnamPro',
                          color: Colors.white.withValues(alpha: 0.94),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. BENTO DETAILS CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Row 1: Nội dung
                _buildInsetRow(
                  isDark: isDark,
                  iconBoxColor: isDark
                      ? const Color(0xFF0C4A6E)
                      : const Color(0xFFE0F2FE),
                  iconColor: isDark
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF0284C7),
                  icon: Icons.notes_rounded,
                  label: 'Nội dung',
                  valueWidget: Text(
                    displayTitle,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'BeVietnamPro',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                _buildHairlineDivider(isDark),

                // Row 2: Danh mục
                _buildInsetRow(
                  isDark: isDark,
                  iconBoxColor: heroAccent.withValues(alpha: isDark ? 0.22 : 0.12),
                  iconColor: heroAccent,
                  icon: Icons.grid_view_rounded,
                  label: 'Danh mục',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryIconBadge(
                        icon: tx.categoryIcon,
                        categoryName: tx.categoryName,
                        size: 26,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tx.categoryName ?? 'Chưa phân loại',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'BeVietnamPro',
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildHairlineDivider(isDark),

                // Row 3: Tài khoản / Ví
                _buildInsetRow(
                  isDark: isDark,
                  iconBoxColor: isDark
                      ? const Color(0xFF064E3B)
                      : const Color(0xFFD1FAE5),
                  iconColor: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF059669),
                  icon: Icons.account_balance_wallet_rounded,
                  label: isTransfer ? 'Từ ví nguồn' : 'Tài khoản / Ví',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: ClipOval(
                          child: BankIcon(
                            bankCode: sourceBankCode,
                            bankName: sourceBankName,
                            size: 26,
                            fullBleed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          matchingWallet?.name ??
                              tx.walletName ??
                              tx.fromWalletName ??
                              'Tiền mặt',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'BeVietnamPro',
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Row 3.1: Đến ví nhận (nếu Chuyển khoản)
                if (isTransfer &&
                    (tx.toWalletName != null ||
                        tx.creditCardName != null ||
                        destWallet != null)) ...[
                  _buildHairlineDivider(isDark),
                  _buildInsetRow(
                    isDark: isDark,
                    iconBoxColor: isDark
                        ? const Color(0xFF0C4A6E)
                        : const Color(0xFFE0F2FE),
                    iconColor: isDark
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                    icon: Icons.arrow_forward_rounded,
                    label: 'Đến ví nhận',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: ClipOval(
                            child: BankIcon(
                              bankCode: destBankCode,
                              bankName: destBankName,
                              size: 26,
                              fullBleed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            destWallet?.name ??
                                tx.toWalletName ??
                                tx.creditCardName ??
                                'Ví đích',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'BeVietnamPro',
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                _buildHairlineDivider(isDark),

                // Row 4: Người ghi chép (Real synced avatar + name pill)
                _buildInsetRow(
                  isDark: isDark,
                  iconBoxColor: memberAccentColor.withValues(
                    alpha: isDark ? 0.22 : 0.12,
                  ),
                  iconColor: memberAccentColor,
                  icon: Icons.person_rounded,
                  label: 'Thành viên',
                  valueWidget: Container(
                    padding: const EdgeInsets.fromLTRB(5, 4, 12, 4),
                    decoration: BoxDecoration(
                      color: memberAccentColor.withValues(
                        alpha: isDark ? 0.18 : 0.09,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: memberAccentColor.withValues(
                          alpha: isDark ? 0.42 : 0.26,
                        ),
                        width: 0.9,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FinoraMemberAvatar(
                          member: memberKey,
                          size: 22,
                          isDark: isDark,
                          studio: studio,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            memberDisplayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Color.lerp(
                                      memberAccentColor, Colors.white, 0.35)!
                                  : memberAccentColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (tx.bankTransactionCode != null &&
                    tx.bankTransactionCode!.trim().isNotEmpty) ...[
                  _buildHairlineDivider(isDark),
                  _buildInsetRow(
                    isDark: isDark,
                    iconBoxColor: brandPrimary.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    iconColor: brandPrimary,
                    icon: Icons.qr_code_2_rounded,
                    label: 'Mã GD ngân hàng',
                    valueWidget: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Clipboard.setData(
                          ClipboardData(text: tx.bankTransactionCode!.trim()),
                        );
                        FinoraNotice.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Đã sao chép mã GD: #${tx.bankTransactionCode!.trim()}',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: brandPrimary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: brandPrimary.withValues(
                            alpha: isDark ? 0.22 : 0.10,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: brandPrimary.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                '#${tx.bankTransactionCode!.trim()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'BeVietnamPro',
                                  color: isDark
                                      ? Color.lerp(
                                          brandPrimary, Colors.white, 0.30)!
                                      : brandPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.copy_rounded,
                              size: 13.5,
                              color: isDark
                                  ? Color.lerp(
                                      brandPrimary, Colors.white, 0.30)!
                                  : brandPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Financial Link Notice (if any)
          if (tx.loanId != null || tx.goalId != null || tx.assetId != null) ...[
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark
                        ? FinoraTokens.warnAmberDark
                        : FinoraTokens.warnAmber)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isDark
                          ? FinoraTokens.warnAmberDark
                          : FinoraTokens.warnAmber)
                      .withValues(alpha: 0.30),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.link_rounded,
                    color: isDark
                        ? FinoraTokens.warnAmberDark
                        : FinoraTokens.warnAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tx.goalId != null
                          ? 'Giao dịch liên kết đóng góp vào Mục tiêu tài chính.'
                          : (tx.loanId != null
                              ? 'Giao dịch liên kết theo dõi Khoản vay / Sổ nợ.'
                              : 'Giao dịch liên kết dòng tiền Tài sản tích lũy.'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? FinoraTokens.warnAmberDark
                            : FinoraTokens.warnAmber,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context, 'open_source');
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? FinoraTokens.warnAmberDark
                                : FinoraTokens.warnAmber)
                            .withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Mở nguồn',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? FinoraTokens.warnAmberDark
                                  : FinoraTokens.warnAmber,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: isDark
                                ? FinoraTokens.warnAmberDark
                                : FinoraTokens.warnAmber,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 4. STADIUM PILL ACTION BUTTONS ROW (Theme Primary Gradient + Crimson Delete)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context, 'delete');
                    },
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48)
                            .withValues(alpha: isDark ? 0.22 : 0.11),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: const Color(0xFFE11D48)
                              .withValues(alpha: isDark ? 0.50 : 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFFFB7185)
                                : const Color(0xFFE11D48),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Xóa',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'BeVietnamPro',
                              color: isDark
                                  ? const Color(0xFFFB7185)
                                  : const Color(0xFFE11D48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, 'edit');
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandSecondary, brandPrimary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: brandPrimary.withValues(alpha: 0.32),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Chỉnh sửa',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'BeVietnamPro',
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsetRow({
    required bool isDark,
    required Color iconBoxColor,
    required Color iconColor,
    required IconData icon,
    required String label,
    required Widget valueWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBoxColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 17,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'BeVietnamPro',
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: valueWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHairlineDivider(bool isDark) {
    return Divider(
      height: 20,
      thickness: 0.8,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }

  String _getWeekdayVietnamese(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }
}
