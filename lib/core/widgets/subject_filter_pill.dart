import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../../data/models/finance_models.dart';
import '../../domain/finance/transaction_member.dart';

enum OwnerFilter {
  all('all', 'Tất cả'),
  husband('husband', 'Chồng'),
  wife('wife', 'Vợ'),
  joint('joint', 'Chung');

  final String value;
  final String label;
  const OwnerFilter(this.value, this.label);

  static OwnerFilter fromString(String? val) {
    if (val == null) return OwnerFilter.all;
    final clean = val.trim().toLowerCase();
    switch (clean) {
      case 'husband':
      case 'chồng':
      case 'chong':
        return OwnerFilter.husband;
      case 'wife':
      case 'vợ':
      case 'vo':
        return OwnerFilter.wife;
      case 'joint':
      case 'shared':
      case 'family':
      case 'chung':
      case 'gia đình':
      case 'gia dinh':
        return OwnerFilter.joint;
      case 'all':
      default:
        return OwnerFilter.all;
    }
  }

  bool matchTransaction(TransactionModel tx, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    return resolveTransactionMember(tx, walletMap: walletMap).value == value;
  }

  bool matchWallet(Wallet wallet) {
    if (this == OwnerFilter.all) return true;
    return resolveWalletMember(wallet).value == value;
  }

  bool matchAsset(Asset asset, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final targetWalletId = asset.walletId ?? asset.sourceWalletId;
    final w = (walletMap != null &&
            targetWalletId != null &&
            walletMap.containsKey(targetWalletId))
        ? walletMap[targetWalletId]
        : null;
    final raw = (w?.owner ?? '').toLowerCase().trim();
    final name = (w?.ownerName ?? '').toLowerCase().trim();
    final isWife = raw == 'wife' ||
        name == 'vợ' ||
        asset.name.toLowerCase().contains('vợ');
    if (this == OwnerFilter.wife) return isWife;
    if (this == OwnerFilter.husband) return !isWife;
    return true;
  }

  bool matchLoan(Loan loan, {Map<String, Wallet>? walletMap}) {
    if (this == OwnerFilter.all) return true;
    final w = (walletMap != null &&
            loan.walletId.isNotEmpty &&
            walletMap.containsKey(loan.walletId))
        ? walletMap[loan.walletId]
        : null;
    final raw = (w?.owner ?? '').toLowerCase().trim();
    final name = (w?.ownerName ?? '').toLowerCase().trim();
    final isWife = raw == 'wife' ||
        name == 'vợ' ||
        loan.personName.toLowerCase().contains('vợ');
    if (this == OwnerFilter.wife) return isWife;
    if (this == OwnerFilter.husband) return !isWife;
    return true;
  }
}

/// Pill chọn thành viên phong cách Apple iOS
class MemberDropdownPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool isDark;
  final bool onColoredSurface;

  const MemberDropdownPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.isDark = false,
    this.onColoredSurface = false,
  });

  Color _getColor(OwnerFilter filter) {
    switch (filter) {
      case OwnerFilter.husband:
        return const Color(0xFF173B70); // Navy
      case OwnerFilter.wife:
        return const Color(0xFFDB2777); // Pink
      case OwnerFilter.joint:
      case OwnerFilter.all:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        onColoredSurface ? Colors.white : _getColor(selected);

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<OwnerFilter>(
        initialValue: selected,
        tooltip: 'Chọn thành viên',
        onSelected: (val) {
          HapticFeedback.selectionClick();
          onSelected(val);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 10,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        constraints: const BoxConstraints(minWidth: 160),
        itemBuilder: (ctx) => [
          _buildMenuItem(OwnerFilter.all, isDark),
          _buildMenuItem(OwnerFilter.husband, isDark),
          _buildMenuItem(OwnerFilter.wife, isDark),
        ],
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 34),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
            decoration: BoxDecoration(
              color: onColoredSurface
                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                  : (isDark ? const Color(0xFF161F30) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: effectiveColor.withValues(alpha: isDark ? 0.35 : 0.22),
                width: 1.0,
              ),
            ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6.5,
                    height: 6.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: effectiveColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selected.label,
                    style: TextStyle(
                      color: onColoredSurface
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: onColoredSurface
                        ? Colors.white70
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  PopupMenuItem<OwnerFilter> _buildMenuItem(OwnerFilter filter, bool dark) {
    return CheckedPopupMenuItem<OwnerFilter>(
      value: filter,
      checked: filter == selected,
      child: Text(
        filter.label,
        style: TextStyle(
          color: dark ? Colors.white : const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Compact owner selector shared by every financial overview.
class SubjectFilterPill extends StatelessWidget {
  final OwnerFilter selected;
  final ValueChanged<OwnerFilter> onSelected;
  final bool compact;
  final bool onColoredSurface;

  const SubjectFilterPill({
    super.key,
    required this.selected,
    required this.onSelected,
    this.compact = false,
    this.onColoredSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MemberDropdownPill(
      selected: selected,
      onSelected: onSelected,
      isDark: isDark,
      onColoredSurface: onColoredSurface,
    );
  }
}
